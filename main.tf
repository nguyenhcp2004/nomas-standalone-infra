terraform {
  required_version = ">= 1.6.0"

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

provider "digitalocean" {
  token = var.do_token
}

provider "docker" {
  # if docker_host is empty, fallback to use local socket.
  host = var.docker_host != "" ? var.docker_host : "unix:///var/run/docker.sock"
}

locals {
  compose_map = {
    mongodb      = "mongodb/docker-compose.yml"
    redis-cifarm = "redis-cifarm/docker-compose.yml"
    kafka-cifarm = "kafka-cifarm/docker-compose.yml"
  }

  # if var.stack doesn't match key, fallback to var.compose_source (default docker-compose.yml)
  selected_compose = lookup(local.compose_map, var.stack, var.compose_source)
}

resource "digitalocean_droplet" "stack" {
  name   = var.droplet_name
  region = var.region
  size   = var.size
  image  = var.image

  # if you have SSH key in DO, add fingerprint/ID here to use key instead of password.
  ssh_keys = var.ssh_keys

  user_data = file("${path.module}/cloud-init.yaml")
}

# Copy docker-compose and run
resource "null_resource" "docker_stack" {
  depends_on = [digitalocean_droplet.stack]

  connection {
    type     = "ssh"
    host     = digitalocean_droplet.stack.ipv4_address
    user     = var.ssh_user
    password = var.ssh_password
    # recommendation: switch to using private_key instead of password.
    # private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = local.selected_compose
    destination = var.compose_dest
  }

  provisioner "remote-exec" {
    inline = [
      "docker compose -f ${var.compose_dest} pull",
      "docker compose -f ${var.compose_dest} up -d"
    ]
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.stack.ipv4_address
}

