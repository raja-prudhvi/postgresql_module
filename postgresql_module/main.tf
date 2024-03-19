# This file will generate a new random password everytime TF runs.
# It will create a POSTGRESQL db on gcp
# It will then push the username and password of the DB to gcp's secrets manager 
# If u want to login to the db, u can get the username and password from GCP's secrets manager via cloud console in respective envs
# It will then map the ip of the db to a dns name for dns resolution
# It will also create a backup everyday once

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_compute_global_address" "book_keeping_app_db_ip" {
  name          = "book-keeping-app-db-private-ip"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "devops-${var.environment}-vpc"
}

resource "google_service_networking_connection" "book_keeping_app_db_connection" {
  network                 = "devops-${var.environment}-vpc"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.book_keeping_app_db_ip.name]
}

data "google_compute_network" "main" {
  name    = "devops-${var.environment}-vpc" # this is the name of the vpc network
  project = var.project_id
}

module "sql-db_postgresql" {
  source                      = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version                     = "17.0.1"
  project_id                  = var.project_id
  name                        = var.name
  db_name                     = var.name
  database_version            = var.database_version
  region                      = var.region
  insights_config             = var.insights_config
  edition                     = var.edition
  user_name                   = var.name
  user_password               = random_password.password.result
  zone                        = var.zone
  tier                        = var.tier
  disk_autoresize             = var.disk_autoresize
  disk_size                   = var.disk_size
  #secondary_zone             = var.secondary_zone #this will come into picture later at some point
  deletion_protection         = var.deletion_protection
  deletion_protection_enabled = var.deletion_protection_enabled
  #ip_configuration is written here because, we are letting vpc private ip's to be used for the db and to give access to the db via private_network
  ip_configuration      = {
    ipv4_enabled        = true
    private_network     = data.google_compute_network.main.self_link
    require_ssl         = false
    allocated_ip_range  = null
    #only add authorized networks of popsql for prod env only, skipping for dev and stage
    authorized_networks = [
      {
        name  = "my_public_ip"
        value = "{my_public_ip}/32" # easy way to get access to the db from your local machine
      }
    ]
  }
  backup_configuration        = var.backup_configuration
  database_flags              = var.database_flags
  maintenance_window_day      = var.maintenance_window_day
  maintenance_window_hour     = var.maintenance_window_hour

  depends_on  = [ random_password.password ]
}

resource "google_secret_manager_secret" "my_secret" {
  secret_id   = var.name
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "my_secret_version" {
  secret      = google_secret_manager_secret.my_secret.id
  secret_data = random_password.password.result
}

#create a dns zone for the db if it does not exist

data "google_dns_managed_zone" "env_dns_zone" {
  name = "{dns_zone_name}" #this is the name of the dns zone where the db will be mapped to
}

#Map dns name to the database IP for dns resolution
#example:(bookkeeping.public.io) to ip of the database for dev environment
resource "google_dns_record_set" "map_dns_dbsip" {
  name          = "bookkeeping.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type          = "A"
  ttl           = 300
  managed_zone  = data.google_dns_managed_zone.env_dns_zone.name
  rrdatas       = [ module.sql-db_postgresql.public_ip_address ]

  depends_on    = [ module.sql-db_postgresql ]
}