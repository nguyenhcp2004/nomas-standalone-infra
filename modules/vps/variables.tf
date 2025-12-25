variable "droplet_name" {
  type        = string
  description = "Droplet name."
  validation {
    condition     = length(var.droplet_name) > 0
    error_message = "The droplet_name must not be empty."
  }
}

variable "region" {
  type        = string
  description = "Droplet region."
  validation {
    condition     = length(var.region) > 0
    error_message = "The region must not be empty."
  }
}

variable "size" {
  type        = string
  description = "Droplet size."
  validation {
    condition     = length(var.size) > 0
    error_message = "The size must not be empty."
  }
}

variable "image" {
  type        = string
  description = "Droplet image slug."
  validation {
    condition     = length(var.image) > 0
    error_message = "The image must not be empty."
  }
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

variable "tags" {
  type        = list(string)
  default     = ["terraform-managed", "docker-stack"]
  description = "Tags to apply to the Droplet for identification and cost allocation."
}
