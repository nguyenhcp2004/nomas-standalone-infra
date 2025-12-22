terraform {
  required_version = ">= 1.6.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # if docker_host is empty, fallback to use local socket.
  host = var.docker_host != "" ? var.docker_host : "unix:///var/run/docker.sock"
}

locals {
  compose_map = {
    mongodb      = "compose/mongodb/docker-compose.yml"
    redis-cifarm = "compose/redis-cifarm/docker-compose.yml"
    kafka-cifarm = "compose/kafka-cifarm/docker-compose.yml"
  }

  # if var.stack doesn't match key, fallback to var.compose_source (default docker-compose.yml)
  selected_compose = lookup(local.compose_map, var.stack, var.compose_source)
}

module "vps" {
  source = "./modules/vps"

  do_token     = var.do_token
  droplet_name = var.droplet_name
  region       = var.region
  size         = var.size
  image        = var.image
  ssh_keys     = var.ssh_keys

  user_data = file("${path.module}/cloud-init/base-cloud-init.yaml")
}

module "docker_stack" {
  source = "./modules/docker_stack"

  host           = module.vps.ip
  ssh_user       = var.ssh_user
  ssh_password   = var.ssh_password
  compose_source = local.selected_compose
  compose_dest   = var.compose_dest
}

output "droplet_ip" {
  value = module.vps.ip
}

