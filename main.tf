# =============================================================================
# Nom as Terraform - DigitalOcean VPS + Docker Stacks
# =============================================================================
#
# This project uses environment-based directories for multi-environment
# deployments. Each environment (dev, staging, prod) has its own state
# and configuration.
#
# Directory Structure:
#   ├── modules/              # Reusable Terraform modules
#   │   ├── vps/              # DigitalOcean Droplet module
#   │   └── docker_stack/     # Docker stack deployment module
#   ├── compose/              # Docker Compose files
#   │   ├── mongodb/
#   │   ├── redis-cifarm/
#   │   └── kafka-cifarm/
#   ├── environments/         # Environment-specific configurations
#   │   ├── dev/              # Development environment
#   │   ├── staging/          # Staging environment
#   │   └── prod/             # Production environment
#   ├── cloud-init/           # Cloud-init scripts
#   └── scripts/              # Deployment scripts
#
# Usage:
#   cd environments/dev
#   terraform init
#   terraform apply
#
#   cd ../staging
#   terraform init
#   terraform apply
#
#   cd ../prod
#   terraform init
#   terraform apply
#
# For more information, see README.md
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # No backend configured here - each environment has its own backend.tf
  # This file is kept for provider documentation purposes only

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Note: No resources defined at root level.
# All deployments are done from environments/ directories.
