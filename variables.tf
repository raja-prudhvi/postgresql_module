# variable "github_owner" {}

# variable "github_token" {}

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  default     = "{project_id}"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
  default     = "us-west1"
}

variable "credentials_file" {
  description = "Path to the Google Cloud credentials file"
  default     = "~/.config/gcloud/terraform-admin.json"
}

variable "cloudflare_token" {
  description = "Cloudflare API token"
  type = string
}

variable "my_public_ip" {
  description = "Your public IP address"
  type = string
}

variable "email_address" {
  description = "Your email address"
  type = string
}