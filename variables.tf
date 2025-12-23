variable "do_token" {
  type        = string
  description = "DigitalOcean API token"
  sensitive   = true
}

variable "droplet_name" {
  type    = string
  default = "stack-1vps"
}

variable "region" {
  type    = string
  default = "sgp1"
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
  description = "List fingerprint/ID SSH keys added in DO. Leave [] if using password."
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  description = "Use SSH password; should switch to SSH key soon."
}

variable "compose_source" {
  type        = string
  default     = "docker-compose.yml"
  description = "Path to docker-compose file on local machine."
}

variable "compose_dest" {
  type        = string
  default     = "/root/docker-compose.yml"
  description = "Path to place docker-compose on VPS."
}

variable "stack" {
  type        = string
  default     = "mongodb" # mongodb | redis-cifarm | kafka-cifarm
  description = "Choose compose to deploy."
}

variable "docker_host" {
  type        = string
  default     = ""
  description = "Endpoint Docker, e.g. ssh://root@<ip>:22 or unix:///var/run/docker.sock."
}

variable "app_domain" {
  type        = string
  description = "Main domain for the app (e.g. api.example.com)."
}

variable "app_email" {
  type        = string
  description = "Email for Let's Encrypt registration."
}

variable "app_port" {
  type        = number
  default     = 3000
  description = "App listening port inside VPS (e.g. 3000)."
}

variable "enable_https" {
  type        = bool
  default     = true
  description = "Whether to automatically request HTTPS via Certbot."
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

