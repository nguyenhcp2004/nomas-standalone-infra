# -----------------------------------------------------------------------------
# Project Metadata
# -----------------------------------------------------------------------------
variable "project_name" {
  type        = string
  description = "Project name prefix for resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

# -----------------------------------------------------------------------------
# Secrets & Authentication
# -----------------------------------------------------------------------------
variable "do_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean API token"
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SSH password for VPS access"
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "SSH user"
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "SSH private key content"
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "DigitalOcean SSH key fingerprints"
}

# -----------------------------------------------------------------------------
# VPS Configuration
# -----------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "DigitalOcean region"
}

variable "size" {
  type        = string
  description = "Droplet size slug"
}

variable "image" {
  type        = string
  description = "Droplet image slug"
}

variable "droplet_tags" {
  type        = list(string)
  default     = ["terraform-managed", "docker-stack"]
  description = "Tags for the droplet"
}

# -----------------------------------------------------------------------------
# Docker Stacks
# -----------------------------------------------------------------------------
variable "stacks" {
  type        = list(string)
  description = "List of stacks to deploy"
}

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
variable "apps" {
  description = "List of apps with domains and ports"
  type = list(object({
    domain = string
    port   = number
  }))
  default = []
}

variable "app_email" {
  type        = string
  description = "Email for Let's Encrypt"
}

variable "enable_https" {
  type        = bool
  default     = true
  description = "Enable HTTPS with Let's Encrypt"
}

variable "use_cloudflare_cert" {
  type        = bool
  default     = false
  description = "Use Cloudflare Origin Certificate"
}

variable "cloudflare_origin_cert" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare Origin Certificate (PEM)"
}

variable "cloudflare_origin_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare Origin Certificate private key (PEM)"
}

# -----------------------------------------------------------------------------
# Database Credentials
# -----------------------------------------------------------------------------
variable "mongodb_root_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "MongoDB root password"
}

variable "mongodb_replica_set_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "MongoDB replica set key"
}

variable "redis_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Redis password"
}

variable "kafka_client_passwords" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Kafka client password"
}
