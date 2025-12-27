terraform {
  required_version = ">= 1.6.0"

  # Remote backend configuration - uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "nomas/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    # Cloudflare is optional - uncomment to use Cloudflare DNS and/or Origin Certificate
    # cloudflare = {
    #   source  = "cloudflare/cloudflare"
    #   version = "~> 4.0"
    # }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "docker" {
  # if docker_host is empty, fallback to use local socket.
  host = var.docker_host != "" ? var.docker_host : "unix:///var/run/docker.sock"
}

# Cloudflare provider - uncomment and provide API token to enable Cloudflare features
# Required variables when enabled:
#   - cloudflare_api_token (40-character token from https://dash.cloudflare.com/profile/api-tokens)
#   - cloudflare_zone_id    (optional, but required for automatic DNS record creation)
#   - use_cloudflare_cert   (set to true for Origin Certificate instead of Let's Encrypt)
# provider "cloudflare" {
#   api_token = var.cloudflare_api_token
# }

locals {
  compose_map = {
    mongodb       = "compose/mongodb/docker-compose.yml"
    redis-cifarm  = "compose/redis-cifarm/docker-compose.yml"
    kafka-cifarm  = "compose/kafka-cifarm/docker-compose.yml"
  }
}
module "vps" {
  source = "./modules/vps"

  droplet_name = var.droplet_name
  region       = var.region
  size         = var.size
  image        = var.image
  ssh_keys     = var.ssh_keys
  tags         = var.droplet_tags
  ssh_user     = var.ssh_user
  ssh_password = var.ssh_password

  user_data = templatefile(
    "${path.module}/cloud-init/base-cloud-init.yaml",
    {
      apps                   = var.apps
      app_email              = var.app_email
      enable_https           = var.enable_https ? "true" : "false"
      use_cloudflare_cert    = var.use_cloudflare_cert ? "true" : "false"
      cloudflare_origin_cert = var.use_cloudflare_cert ? var.cloudflare_origin_cert : ""
      cloudflare_origin_key  = var.use_cloudflare_cert ? var.cloudflare_origin_key : ""
      root_password          = var.ssh_password
    }
  )
}

module "docker_stacks" {
  for_each = toset(var.stacks)

  source = "./modules/docker_stack"

  host             = module.vps.ip
  ssh_user         = var.ssh_user
  ssh_private_key  = var.ssh_private_key
  ssh_password     = var.ssh_password
  compose_source   = local.compose_map[each.value]
  compose_content  = file("${path.module}/${local.compose_map[each.value]}")
  compose_dest     = "/root/${each.value}/docker-compose.yml"
  compose_checksum = filebase64sha256(local.compose_map[each.value])
}

# Configure Nginx apps and SSL (runs after droplet is ready and when apps change)
resource "null_resource" "nginx_apps" {
  # Only run if apps are configured
  for_each = length(var.apps) > 0 ? { "apps" : {} } : {}

  # Trigger on apps change
  triggers = {
    apps_json    = jsonencode(var.apps)
    enable_https = var.enable_https
    app_email    = var.app_email
  }

  # Wait for droplet to be ready
  depends_on = [module.docker_stacks]

  connection {
    type        = "ssh"
    host        = module.vps.ip
    user        = var.ssh_user
    password    = var.ssh_password != "" ? var.ssh_password : null
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "10m"
  }

  # Generate and upload Nginx configuration
  provisioner "file" {
    content = templatefile("${path.module}/cloud-init/nginx-app.conf.tpl", {
      apps = var.apps
    })
    destination = "/etc/nginx/sites-available/app.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      # Enable the site
      "ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf",
      # Remove default site if exists
      "rm -f /etc/nginx/sites-enabled/default || true",
      # Test and reload Nginx
      "nginx -t && systemctl reload nginx",
      # Obtain SSL certificates if enabled
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

# Cloudflare DNS records for each app domain - uncomment to enable automatic DNS management
# resource "cloudflare_record" "app" {
#   for_each = var.cloudflare_zone_id != "" ? { for app in var.apps : app.domain => app } : {}
#
#   zone_id = var.cloudflare_zone_id
#   name    = each.value.domain
#   type    = "A"
#   value   = module.vps.ip
#   ttl     = 1 # auto
#   proxied = var.cloudflare_proxied
# }

output "droplet_ip" {
  value = module.vps.ip
}

# output "cloudflare_dns_record" {
#   value = var.cloudflare_zone_id != "" ? { for k, v in cloudflare_record.app : k => v.hostname } : null
# }

