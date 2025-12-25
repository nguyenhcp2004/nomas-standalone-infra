variable "do_token" {
  type        = string
  description = "DigitalOcean API token"
  sensitive   = true
  validation {
    condition     = length(var.do_token) > 30
    error_message = "The do_token must be a valid DigitalOcean API token (typically 64+ characters)."
  }
}

variable "droplet_name" {
  type    = string
  default = "stack-1vps"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.droplet_name)) && length(var.droplet_name) > 0
    error_message = "The droplet_name must contain only alphanumeric characters and hyphens."
  }
}

variable "droplet_tags" {
  type        = list(string)
  default     = ["terraform-managed", "docker-stack"]
  description = "Tags to apply to the Droplet for identification and cost allocation."
}

variable "region" {
  type    = string
  default = "sgp1"
  validation {
    condition     = can(regex("^[a-z]{2,3}[0-9]$", var.region))
    error_message = "The region must be a valid DigitalOcean region slug (e.g., sgp1, nyc1, fra1)."
  }
}

variable "size" {
  type    = string
  default = "s-4vcpu-8gb"
}

variable "image" {
  type    = string
  default = "ubuntu-22-04-x64"
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "List of SSH key fingerprints or IDs added in DigitalOcean. Use this for droplet access."
}

variable "ssh_user" {
  type    = string
  default = "root"
  validation {
    condition     = length(var.ssh_user) > 0
    error_message = "The ssh_user must not be empty."
  }
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key content for authenticating with the VPS. Required for docker_stack deployment."
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "DEPRECATED: Use ssh_private_key instead. SSH password authentication is insecure."
  validation {
    condition     = var.ssh_password == ""
    error_message = "SSH password authentication is deprecated and insecure. Please use ssh_private_key instead."
  }
}

variable "compose_source" {
  type        = string
  default     = "docker-compose.yml"
  description = "Path to docker-compose file on local machine."
  validation {
    condition     = length(var.compose_source) > 0
    error_message = "The compose_source must not be empty."
  }
}

variable "compose_dest" {
  type    = string
  default = "/root/docker-compose.yml"
  validation {
    condition     = can(regex("^/", var.compose_dest))
    error_message = "The compose_dest must be an absolute path (starting with /)."
  }
}

variable "stack" {
  type        = string
  default     = "mongodb"
  description = "Predefined stack to deploy: mongodb, redis-cifarm, or kafka-cifarm."
  validation {
    condition     = contains(["mongodb", "redis-cifarm", "kafka-cifarm", ""], var.stack)
    error_message = "The stack must be one of: mongodb, redis-cifarm, kafka-cifarm, or empty (for custom compose_source)."
  }
}

variable "docker_host" {
  type        = string
  default     = ""
  description = "Docker endpoint, e.g., ssh://root@<ip>:22 or unix:///var/run/docker.sock."
}

variable "app_email" {
  type        = string
  description = "Email for Let's Encrypt registration. Required when enable_https is true."
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.app_email))
    error_message = "The app_email must be a valid email address."
  }
}

variable "enable_https" {
  type        = bool
  default     = true
  description = "Whether to automatically request HTTPS via Certbot."
}

variable "apps" {
  description = "List of app domains and ports to expose via Nginx/Cloudflare."
  type = list(object({
    domain = string
    port   = number
  }))
  default = []
  validation {
    condition = alltrue([
      for app in var.apps : can(regex("^[a-zA-Z0-9.-]+$", app.domain)) && app.port > 0 && app.port <= 65535
    ])
    error_message = "Each app must have a valid domain name and a port between 1 and 65535."
  }
}

variable "cloudflare_api_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare API token with Zone:Edit permission. Leave empty if not using Cloudflare."
}

variable "cloudflare_zone_id" {
  type        = string
  default     = ""
  description = "Cloudflare Zone ID (found in domain overview page). Leave empty if not using Cloudflare."
  validation {
    condition     = var.cloudflare_zone_id == "" || can(regex("^[a-z0-9]{32}$", var.cloudflare_zone_id))
    error_message = "The cloudflare_zone_id must be a valid 32-character hexadecimal string."
  }
}

variable "cloudflare_proxied" {
  type        = bool
  default     = true
  description = "Enable Cloudflare proxy (CDN + DDoS protection) for DNS record."
}

variable "use_cloudflare_cert" {
  type        = bool
  default     = false
  description = "Use Cloudflare Origin Certificate instead of Let's Encrypt."
}

variable "cloudflare_origin_cert" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare Origin Certificate content (PEM format). Required if use_cloudflare_cert = true."
}

variable "cloudflare_origin_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Cloudflare Origin Certificate private key (PEM format). Required if use_cloudflare_cert = true."
}
