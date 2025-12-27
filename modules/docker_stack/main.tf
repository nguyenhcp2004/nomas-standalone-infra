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

  provisioner "remote-exec" {
    inline = [
      "set -e",
      # Wait for Docker to be available (cloud-init may still be installing)
      "echo 'Waiting for Docker to be ready...'",
      "timeout 300 sh -c 'until docker info >/dev/null 2>&1; do sleep 2; done' || echo 'Docker ready or timeout'",
      # Prepare deployment directory
      "echo 'Preparing deployment directory...'",
      "dir=$(dirname ${var.compose_dest})",
      "test -f $dir && rm -f $dir || true",
      "mkdir -p $dir",
      # Write docker-compose.yml content directly
      "cat > ${var.compose_dest} <<'EOF_COMPOSE'",
      var.compose_content,
      "EOF_COMPOSE",
      # Deploy services
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
