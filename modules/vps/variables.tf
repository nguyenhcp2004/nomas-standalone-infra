variable "do_token" {
  type        = string
  description = "DigitalOcean API token."
  sensitive   = true
}

variable "droplet_name" {
  type        = string
  description = "Droplet name."
}

variable "region" {
  type        = string
  description = "Droplet region."
}

variable "size" {
  type        = string
  description = "Droplet size."
}

variable "image" {
  type        = string
  description = "Droplet image slug."
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "DigitalOcean SSH key IDs/fingerprints."
}

variable "user_data" {
  type        = string
  description = "Cloud-init user data content."
}


