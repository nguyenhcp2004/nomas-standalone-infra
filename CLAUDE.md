# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project that automates VPS deployment on DigitalOcean with Docker stacks, Nginx reverse proxy, and SSL (Let's Encrypt or Cloudflare Origin Certificate). The architecture consists of two main modules:

- **`modules/vps`** - Creates DigitalOcean Droplet with cloud-init for Docker, Nginx, UFW, and Certbot setup
- **`modules/docker_stack`** - Deploys Docker Compose files via SSH using `null_resource` with remote provisioners

## Commands

### Initialization
```bash
terraform init
```

### Planning and Applying
```bash
# Basic example with required variables
terraform plan -out tfplan \
  -var "do_token=YOUR_DO_TOKEN" \
  -var "ssh_password=YOUR_ROOT_PASSWORD" \
  -var "app_email=you@example.com"

terraform apply "tfplan"
```

### Testing
```bash
# Test vps module
cd modules/vps && terraform init -backend=false && terraform test

# Test docker_stack module
cd modules/docker_stack && terraform init -backend=false && terraform test
```

Tests are plan-only with dummy inputs and `-backend=false` - no real resources are created.

### Destroy
```bash
terraform destroy \
  -var "do_token=YOUR_DO_TOKEN" \
  -var "ssh_password=YOUR_ROOT_PASSWORD" \
  -var "app_email=you@example.com"
```

## Architecture

### Module Flow
1. **Root `main.tf`** orchestrates both modules, with `vps` module output (`ip`) feeding into `docker_stack` module
2. **`vps` module** creates a DigitalOcean Droplet with `user_data` (cloud-init script from `cloud-init/base-cloud-init.yaml`)
3. **`docker_stack` module** uses `null_resource` with SSH connection to copy and run `docker compose`

### Cloud-Init Template
The `cloud-init/base-cloud-init.yaml` template receives variables from root `main.tf`:
- `apps` - List of {domain, port} objects for Nginx reverse proxy config
- `app_email` - Email for Let's Encrypt
- `enable_https` - Boolean for Certbot
- `use_cloudflare_cert` - Boolean for using Cloudflare Origin Certificate instead
- `cloudflare_origin_cert` / `cloudflare_origin_key` - PEM-formatted certificate content

The template generates Nginx server blocks conditionally:
- With Cloudflare cert: HTTP→HTTPS redirect + HTTPS server block with Cloudflare cert
- Without: HTTP only (Certbot adds HTTPS later)

### Stack Selection
Root `main.tf` uses `local.compose_map` to map `var.stack` values to compose file paths:
- `mongodb` → `compose/mongodb/docker-compose.yml`
- `redis-cifarm` → `compose/redis-cifarm/docker-compose.yml`
- `kafka-cifarm` → `compose/kafka-cifarm/docker-compose.yml`

Fallback is `var.compose_source` (default: `docker-compose.yml`)

### Cloudflare Integration
When `cloudflare_zone_id` is provided:
- `cloudflare_record` resources create A records for each app domain pointing to droplet IP
- `cloudflare_proxied` controls CDN/DDoS protection (default: true)

## Important Notes

- **SSH Authentication**: Currently uses password auth (`ssh_password`). Production should use SSH keys via `ssh_keys` variable (DigitalOcean SSH key fingerprints)
- **Let's Encrypt**: Requires DNS already pointing to VPS IP before `terraform apply`, or re-run after IP is available
- **Cloud-Init Timing**: Takes 2-5 minutes to complete Docker/Nginx/SSL installation. Check logs via `cat /var/log/cloud-init-output.log`
- **Windows Syntax**: README uses `^` for line continuation (Windows cmd-style). On Linux/Mac, use `\`
