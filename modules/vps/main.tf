# Provider configuration is now managed in the root module
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

resource "digitalocean_droplet" "this" {
  name   = var.droplet_name
  region = var.region
  size   = var.size
  image  = var.image

  ssh_keys  = var.ssh_keys
  user_data = var.user_data

  # Ensure droplet is tagged for identification
  tags = var.tags
}


