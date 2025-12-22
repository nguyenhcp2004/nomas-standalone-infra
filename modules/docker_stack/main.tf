resource "null_resource" "docker_stack" {
  connection {
    type     = "ssh"
    host     = var.host
    user     = var.ssh_user
    password = var.ssh_password
    # Prefer SSH key in real environments.
    # private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = var.compose_source
    destination = var.compose_dest
  }

  provisioner "remote-exec" {
    inline = [
      "docker compose -f ${var.compose_dest} pull",
      "docker compose -f ${var.compose_dest} up -d"
    ]
  }
}


