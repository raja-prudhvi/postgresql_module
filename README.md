# 🛠️ Google Cloud PostgreSQL Database Setup with Terraform 🛠️

Welcome to the Google Cloud PostgreSQL database setup repository using Terraform! This Terraform configuration automates the creation of a PostgreSQL database on Google Cloud Platform.

## 📁 Project Structure

```
.
├── main.tf
├── outputs.tf
├── postgresql-module
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── readme.md
└── variables.tf
```


## 🚀 Features

- **Dynamic Password Generation**: Generates a new random password every time Terraform runs.
- **PostgreSQL Database Creation**: Creates a PostgreSQL database on Google Cloud Platform.
- **Integration with Secrets Manager**: Pushes the database username and password to Google Cloud's Secrets Manager for secure management.
- **IP Mapping and DNS Resolution**: Maps the database IP to a DNS name for easy access and DNS resolution.
- **Daily Backups**: Automatically creates a backup of the database every day.

## 🚀 Getting Started

1. **Install Terraform**: Make sure you have Terraform installed locally.
2. **Set Up Google Cloud Provider**: Ensure you have set up authentication for the Google Cloud provider in your Terraform environment.
3. **Customize Variables**: Modify the variables in `variables.tf` as per your project requirements.
4. **Run Terraform**: Execute `terraform init` to initialize Terraform, then `terraform apply` to apply the changes.

