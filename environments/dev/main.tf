terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

# Get the repository root path (2 levels up from environments/dev)
locals {
  repo_root = abspath("${path.root}/../..")
}

provider "digitalocean" {
  token = var.do_token
}

# -----------------------------------------------------------------------------
# VPS Module
# -----------------------------------------------------------------------------
module "vps" {
  source = "../../modules/vps"

  droplet_name = "${var.project_name}-${var.environment}"
  region       = var.region
  size         = var.size
  image        = var.image
  ssh_keys     = var.ssh_keys
  tags         = var.droplet_tags

  user_data = templatefile(
    "${local.repo_root}/cloud-init/base-cloud-init.yaml",
    {
      apps                   = var.apps
      app_email              = var.app_email
      enable_https           = var.enable_https ? "true" : "false"
      use_cloudflare_cert    = var.use_cloudflare_cert ? "true" : "false"
      cloudflare_origin_cert = var.use_cloudflare_cert ? var.cloudflare_origin_cert : ""
      cloudflare_origin_key  = var.use_cloudflare_cert ? var.cloudflare_origin_key : ""
      root_password          = var.ssh_password
      backend_network_name   = var.backend_network_name
    }
  )
}

# -----------------------------------------------------------------------------
# Docker Stack Deployment
# -----------------------------------------------------------------------------
resource "null_resource" "docker_stacks" {
  triggers = {
    stacks_json    = jsonencode(var.stacks)
    content_hashes = jsonencode({
      for stack in var.stacks : stack => filebase64sha256("${local.repo_root}/compose/${stack}/docker-compose.yml")
    })
  }

  depends_on = [module.vps]

  connection {
    type        = "ssh"
    host        = module.vps.ip
    user        = var.ssh_user
    password    = var.ssh_password != "" ? var.ssh_password : null
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${local.repo_root}/scripts/deploy-stacks.sh.tpl", {
      stacks = var.stacks
      compose_contents = {
        for stack in var.stacks : stack => {
          content = file("${local.repo_root}/compose/${stack}/docker-compose.yml")
          dest     = "/root/${stack}/docker-compose.yml"
        }
      }
      mongodb_root_password = var.mongodb_root_password != "" ? var.mongodb_root_password : "ChangeMe123!"
      mongodb_replica_set_key = var.mongodb_replica_set_key != "" ? var.mongodb_replica_set_key : "ChangeMeReplicaKey123!"
      redis_password = var.redis_password != "" ? var.redis_password : "ChangeMe123!"
      kafka_client_passwords = var.kafka_client_passwords != "" ? var.kafka_client_passwords : "ChangeMe123!"
      arcane_encryption_key = var.arcane_encryption_key != "" ? var.arcane_encryption_key : "ChangeMeArcaneKey123!"
      arcane_jwt_secret = var.arcane_jwt_secret != "" ? var.arcane_jwt_secret : "ChangeMeArcaneJWT123!"
      grafana_admin_user = var.grafana_admin_user != "" ? var.grafana_admin_user : "admin"
      grafana_admin_password = var.grafana_admin_password != "" ? var.grafana_admin_password : "ChangeMeGrafana123!"
      grafana_root_url = var.grafana_root_url != "" ? var.grafana_root_url : "http://localhost:3000"
      backend_network_name = var.backend_network_name
    })
    destination = "/tmp/deploy-stacks.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export BACKEND_NETWORK_NAME='${var.backend_network_name}'",
      "sed -i 's/\\r$//' /tmp/deploy-stacks.sh",
      "chmod +x /tmp/deploy-stacks.sh",
      "bash /tmp/deploy-stacks.sh",
      "rm /tmp/deploy-stacks.sh"
    ]
  }
}

# -----------------------------------------------------------------------------
# Nginx Apps Configuration
# -----------------------------------------------------------------------------
resource "null_resource" "nginx_apps" {
  for_each = length(var.apps) > 0 ? { "apps" : {} } : {}

  triggers = {
    apps_json    = jsonencode(var.apps)
    enable_https = var.enable_https
    app_email    = var.app_email
  }

  depends_on = [null_resource.docker_stacks]

  connection {
    type        = "ssh"
    host        = module.vps.ip
    user        = var.ssh_user
    password    = var.ssh_password != "" ? var.ssh_password : null
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${local.repo_root}/cloud-init/nginx-app.conf.tpl", {
      apps = var.apps
    })
    destination = "/etc/nginx/sites-available/app.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf",
      "rm -f /etc/nginx/sites-enabled/default || true",
      "nginx -t && systemctl reload nginx",
      var.enable_https ? <<-EOT
        for domain in ${join(" ", [for app in var.apps : app.domain])}; do
          echo "Obtaining certificate for $domain..."
          certbot --nginx --non-interactive --agree-tos -m "${var.app_email}" -d "$domain" --redirect || echo "Certbot failed for $domain (DNS may not be propagated yet)"
        done
        EOT
      : "echo 'HTTPS disabled, skipping Certbot'"
    ]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "droplet_ip" {
  value = module.vps.ip
  description = "VPS IP address"
}

output "droplet_name" {
  value = module.vps.ip
  description = "Droplet name"
}
