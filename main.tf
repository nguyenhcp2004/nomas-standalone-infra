terraform {
  required_version = ">= 1.6.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "docker" {
  # if docker_host is empty, fallback to use local socket.
  host = var.docker_host != "" ? var.docker_host : "unix:///var/run/docker.sock"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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

  user_data = templatefile(
    "${path.module}/cloud-init/base-cloud-init.yaml",
    {
      app_domain            = var.app_domain
      app_email             = var.app_email
      app_port              = var.app_port
      enable_https          = var.enable_https ? "true" : "false"
      use_cloudflare_cert   = var.use_cloudflare_cert ? "true" : "false"
      cloudflare_origin_cert = var.use_cloudflare_cert ? var.cloudflare_origin_cert : ""
      cloudflare_origin_key  = var.use_cloudflare_cert ? var.cloudflare_origin_key : ""
    }
  )
}

module "docker_stack" {
  source = "./modules/docker_stack"

  host           = module.vps.ip
  ssh_user       = var.ssh_user
  ssh_password   = var.ssh_password
  compose_source = local.selected_compose
  compose_dest   = var.compose_dest
}

# Cloudflare DNS record
resource "cloudflare_record" "app" {
  count = var.cloudflare_zone_id != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.app_domain
  type    = "A"
  value   = module.vps.ip
  ttl     = 1 # auto
  proxied = var.cloudflare_proxied
}

output "droplet_ip" {
  value = module.vps.ip
}

output "cloudflare_dns_record" {
  value = var.cloudflare_zone_id != "" ? cloudflare_record.app[0].hostname : null
}

