
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  # The name of the environment, e.g. dev, staging, or prod
  environment = "dev"
}

resource "google_project_service" "project" {
  project = var.project_id

  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "dns.googleapis.com",
    "containersecurity.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networkmanagement.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
  ])

  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = true
}

#postgresql db for your application

module "postgresql" {
  source              = "../postgresql_module"
  project_id          = var.project_id
  name                = "book-keeping-db"
  region              = "us-west1"
  zone                = "us-west1-a"
  database_version    = "POSTGRES_15"
  #db_name             = "book-keeping-db"
  tier                = "db-perf-optimized-N-2"
  #secondary_zone     = "" #this will come into picture later at some point
  disk_size           = 100
  disk_autoresize     = true
  # ip_configuration values are added inside the module on the other side
  maintenance_window_day  = 7
  maintenance_window_hour = 23
  environment             = local.environment

  database_flags = [
    {
      name = "max_connections"
      value = "100"
    }
  ]
  #For the Google Cloud database services, such as Cloud POSTGRESQL, automatic backups are incremental by default
  backup_configuration = {
    enabled                        = true
    start_time                     = "01:00"  # Start backups at 1 AM UTC
    location                       = "us-west1"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = "7"
    retained_backups               = 24       # Keep 24 backups, one for each hour in a day
    retention_unit                 = "COUNT"  # Specify that retained_backups represents the count of backups
  }

  insights_config       = {
    query_plans_per_minute         = 10
    query_string_length            = 4096
    record_application_tags        = true
    record_client_address          = true
  }
  deletion_protection              = false
  deletion_protection_enabled      = false
}
