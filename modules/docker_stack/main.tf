resource "null_resource" "docker_stack" {
  # Trigger recreation only when compose file content changes
  triggers = {
    compose_file_checksum = var.compose_checksum
    compose_dest          = var.compose_dest
  }

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.ssh_user
    password    = var.ssh_password != "" ? var.ssh_password : null
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "10m"
  }

  provisioner "file" {
    source      = var.compose_source
    destination = var.compose_dest
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      # Wait for Docker to be available (cloud-init may still be installing)
      "echo 'Waiting for Docker to be ready...'",
      "timeout 300 sh -c 'until docker info >/dev/null 2>&1; do sleep 2; done' || echo 'Docker ready or timeout'",
      # Deploy services (file provisioner already copied docker-compose.yml)
      "echo 'Deploying Docker stack...'",
      "docker compose -f ${var.compose_dest} pull",
      "docker compose -f ${var.compose_dest} up -d",
      "echo 'Docker stack deployed successfully'"
    ]
  }
}

output "deployment_status" {
  value = "Docker stack deployment completed"
}

output "compose_file" {
  value = var.compose_dest
}
