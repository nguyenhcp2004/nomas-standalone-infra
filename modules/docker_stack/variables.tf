variable "host" {
  type        = string
  description = "VPS IP address or hostname."
  validation {
    condition     = length(var.host) > 0
    error_message = "The host must not be empty."
  }
}

variable "ssh_user" {
  type        = string
  description = "SSH user to connect to VPS."
  validation {
    condition     = length(var.ssh_user) > 0
    error_message = "The ssh_user must not be empty."
  }
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SSH private key content for authenticating with the VPS."
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SSH password for authenticating with the VPS."
}

variable "compose_source" {
  type        = string
  description = "Local path to docker-compose file."
}

variable "compose_content" {
  type        = string
  description = "Content of docker-compose file (used for reliable transfer)."
}

variable "compose_dest" {
  type        = string
  description = "Remote path to place docker-compose file."
  validation {
    condition     = can(regex("^/", var.compose_dest))
    error_message = "The compose_dest must be an absolute path (starting with /)."
  }
}

variable "compose_checksum" {
  type        = string
  description = "Checksum of the compose file for change detection (use filebase64sha256())."
}
