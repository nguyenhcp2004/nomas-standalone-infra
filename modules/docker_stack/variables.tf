variable "ssh_user" {
  type        = string
  description = "SSH user to connect to VPS."
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  description = "SSH password (prefer SSH key in production)."
}

variable "host" {
  type        = string
  description = "VPS IP or hostname."
}

variable "compose_source" {
  type        = string
  description = "Local path to docker-compose file."
}

variable "compose_dest" {
  type        = string
  description = "Remote path to place docker-compose file."
}


