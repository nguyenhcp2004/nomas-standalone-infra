# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project that automates VPS deployment on DigitalOcean with Docker stacks, Nginx reverse proxy, and SSL (Let's Encrypt or Cloudflare Origin Certificate).

**Key architectural change:** This project uses **environment-based directories** (`environments/dev`, `environments/staging`, `environments/prod`) as the primary deployment method. Each environment has its own Terraform state and configuration.

## Commands

### Environment-Based Deployment (Primary Method)
```bash
# Deploy to dev environment
cd environments/dev
terraform init
terraform plan
terraform apply

# Deploy to staging
cd ../staging
terraform init
terraform apply

# Deploy to production
cd ../prod
terraform init
terraform apply
```

### Configuration File
Copy `terraform.tfvars.example` to `terraform.tfvars` in your environment directory and fill in values:

```hcl
do_token     = "dop_v1_xxx"
ssh_password = "your_password"
app_email    = "you@example.com"
stacks       = ["mongodb", "redis-cifarm", "kafka-cifarm"]
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
cd environments/dev
terraform destroy
```

## Architecture

### Directory Structure
```
nomas-standalone-infra/
├── environments/           # Environment-specific deployments (PRIMARY)
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment
│   └── prod/              # Production environment
├── modules/               # Reusable Terraform modules
│   ├── vps/              # DigitalOcean Droplet creation
│   └── docker_stack/     # Legacy single-stack deployment (not used in environments)
├── compose/               # Docker Compose stack definitions
│   ├── mongodb/
│   ├── redis-cifarm/
│   └── kafka-cifarm/
├── cloud-init/            # Cloud-init templates
│   ├── base-cloud-init.yaml
│   └── nginx-app.conf.tpl
└── scripts/               # Deployment scripts
    └── deploy-stacks.sh.tpl
```

### Environment Deployment Flow

Each environment's `main.tf` orchestrates deployment:

1. **VPS Module** (`module "vps"`) - Creates DigitalOcean Droplet with cloud-init
   - Passes `user_data` rendered from `cloud-init/base-cloud-init.yaml`
   - Sets root password, installs Docker/Nginx/UFW/Certbot

2. **Docker Stacks** (`null_resource.docker_stacks`) - Sequential stack deployment
   - Uploads `scripts/deploy-stacks.sh.tpl` rendered with credentials
   - Deploys all stacks from `var.stacks` in a single SSH connection
   - Each stack goes to `/root/<stack>/docker-compose.yml`
   - Environment variables injected at runtime (no .env files on disk)

3. **Nginx Apps** (`null_resource.nginx_apps`) - Optional reverse proxy config
   - Uploads `cloud-init/nginx-app.conf.tpl`
   - Runs Certbot for Let's Encrypt certificates

### Cloud-Init Template (`base-cloud-init.yaml`)

Template variables injected from environment:
- `apps` - List of {domain, port} for Nginx reverse proxy
- `app_email` - For Let's Encrypt registration
- `enable_https` - Boolean for Certbot installation
- `use_cloudflare_cert` - Boolean for Cloudflare Origin Certificate
- `cloudflare_origin_cert` / `cloudflare_origin_key` - PEM content
- `root_password` - SSH password for root user

The template conditionally generates Nginx configs:
- With Cloudflare cert: HTTP→HTTPS redirect + HTTPS with Cloudflare cert
- Without: HTTP only (Certbot adds HTTPS via `nginx_apps` resource)

### Stack Deployment Script (`deploy-stacks.sh.tpl`)

This template generates a bash script that:
- Waits for cloud-init completion
- Iterates through all stacks in `var.stacks`
- Creates directory `/root/<stack>/`
- Writes docker-compose.yml content (embedded in script)
- Exports stack-specific environment variables:
  - `mongodb`: `MONGODB_ROOT_PASSWORD`, `MONGODB_REPLICA_SET_KEY`
  - `redis-cifarm`: `REDIS_PASSWORD`
  - `kafka-cifarm`: `KAFKA_CLIENT_PASSWORDS`
- Runs `docker compose pull && docker compose up -d`
- Unsets exported variables

### Available Stacks

| Stack | Compose Path | Services | Internal Ports |
|-------|--------------|----------|----------------|
| `mongodb` | `compose/mongodb/docker-compose.yml` | Sharded cluster (3 shards) | 27017 |
| `redis-cifarm` | `compose/redis-cifarm/docker-compose.yml` | Redis single instance | 6379 |
| `kafka-cifarm` | `compose/kafka-cifarm/docker-compose.yml` | Kafka (KRaft mode) | 9092 |

**Important:** All services run on internal Docker networks only. Ports are NOT exposed to the internet.

## Important Notes

- **Multi-Environment:** Always work from `environments/<env>` directories, not root
- **SSH Authentication:** Uses password auth (`ssh_password`). For production, use `ssh_private_key` instead
- **Secrets Management:** Database credentials are embedded in the deployment script at runtime, not stored as .env files
- **Let's Encrypt:** Requires DNS already pointing to VPS IP. If certificate fails during cloud-init, re-run `terraform apply` after DNS propagation
- **Cloud-Init Timing:** Takes 2-5 minutes. Check logs: `ssh root@<ip> 'cat /var/log/cloud-init-output.log'`
- **Terraform Cloud:** Each environment has `backend.tf` for remote state. Use `local` execution mode for privacy
