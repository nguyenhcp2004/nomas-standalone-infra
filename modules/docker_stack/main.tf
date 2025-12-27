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
      # Wait for cloud-init to complete (more efficient than polling docker info)
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait --long 2>&1 || echo 'Cloud-init already completed'",
      # Verify Docker is ready
      "echo 'Verifying Docker is ready...'",
      "docker info >/dev/null || (echo 'Docker not ready, waiting...' && sleep 30 && docker info)",
      # Prepare deployment directory
      "echo 'Preparing deployment directory...'",
      "dir=$(dirname ${var.compose_dest})",
      "test -f $dir && rm -f $dir || true",
      "mkdir -p $dir",
      # Write docker-compose.yml content directly
      "echo 'Writing docker-compose.yml...'",
      "cat > ${var.compose_dest} <<'EOF_COMPOSE'",
      var.compose_content,
      "EOF_COMPOSE",
      # Deploy services
      "echo 'Pulling Docker images...'",
      "docker compose -f ${var.compose_dest} pull",
      "echo 'Starting containers...'",
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
