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
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "file" {
    source      = var.compose_source
    destination = var.compose_dest
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
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
