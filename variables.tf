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

