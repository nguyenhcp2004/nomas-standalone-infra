# Nomas Terraform - VPS Stack Deployment

> Automated VPS deployment on DigitalOcean with Docker stacks, Nginx reverse proxy, and SSL (Let's Encrypt or Cloudflare Origin Certificate).

## What This Does

This Terraform project automates the complete setup of a production-ready VPS:

- **Provisions** a DigitalOcean Droplet with cloud-init
- **Installs** Docker, Docker Compose, Nginx, UFW firewall, and Certbot
- **Deploys** pre-configured Docker stacks (MongoDB, Redis, Kafka)
- **Configures** Nginx as a reverse proxy for your applications
- **Secures** with Let's Encrypt or Cloudflare Origin Certificate
- **Manages** DNS records via Cloudflare (optional)

## Quick Start

### Prerequisites

| Requirement | Details |
|-------------|---------|
| Terraform | >= 1.6.0 |
| DigitalOcean API Token | [Create here](https://cloud.digitalocean.com/account/api/tokens) |
| SSH Private Key | For Docker stack deployment |
| Cloudflare Token (optional) | For DNS management and Origin Certificate |

### 1. Clone and Initialize

```bash
git clone <repository-url>
cd nomas-terraform
terraform init
```

### 2. Configure Variables

Choose one of these methods:

**Option A: Using `.env` file (Recommended for secrets)**

```bash
cp .env.example .env
# Edit .env with your actual values
```

**Option B: Using `terraform.tfvars`**

```hcl
# terraform.tfvars
droplet_name = "production-stack"
region       = "sgp1"
size         = "s-4vcpu-8gb"
stacks       = ["mongodb"]
apps         = [{ domain = "api.example.com", port = 3000 }]
app_email    = "you@example.com"
```

### 3. Deploy

**Linux/macOS:**
```bash
source .env                    # Load secrets from .env
terraform plan                 # Preview changes
terraform apply                # Deploy
```

**Windows PowerShell:**
```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^TF_VAR_') {
        $parts = $_.Split('=', 2)
        [Environment]::SetEnvironmentVariable($parts[0], $parts[1])
    }
}
terraform plan
terraform apply
```

## Project Structure

```
nomas-terraform/
├── main.tf                    # Root configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output values
├── cloud-init/
│   └── base-cloud-init.yaml   # Cloud-init script for Droplet setup
├── compose/                   # Docker stack definitions
│   ├── mongodb/docker-compose.yml
│   ├── redis-cifarm/docker-compose.yml
│   └── kafka-cifarm/docker-compose.yml
├── modules/
│   ├── vps/                   # DigitalOcean Droplet module
│   └── docker_stack/          # Docker Compose deployment via SSH
└── environments/              # Multi-environment configs (optional)
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

## Available Stacks

| Stack | Description | Services | Default Port |
|-------|-------------|----------|--------------|
| `mongodb` | MongoDB Sharded Cluster | 3 shards + config servers | 27017 |
| `redis-cifarm` | Redis for CiFarm | Single instance | 6379 |
| `kafka-cifarm` | Kafka for CiFarm | KRaft mode | 9092 |

### Deploying Multiple Stacks

```hcl
# Deploy all stacks
stacks = ["mongodb", "redis-cifarm", "kafka-cifarm"]

# Deploy specific stacks
stacks = ["mongodb", "redis-cifarm"]
```

Each stack deploys to its own directory on the VPS:
- `/root/mongodb/docker-compose.yml`
- `/root/redis-cifarm/docker-compose.yml`
- `/root/kafka-cifarm/docker-compose.yml`

## Configuration Reference

### Required Variables

| Variable | Description |
|----------|-------------|
| `do_token` | DigitalOcean API Token |
| `ssh_private_key` | SSH private key content (for connecting to VPS) |
| `app_email` | Email for Let's Encrypt certificates |

### Droplet Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `droplet_name` | `stack-1vps` | Name of the Droplet |
| `region` | `sgp1` | DigitalOcean region |
| `size` | `s-4vcpu-8gb` | Droplet size slug |
| `image` | `ubuntu-22-04-x64` | OS image |
| `ssh_keys` | `[]` | List of SSH key fingerprints (DO) |
| `droplet_tags` | `["terraform-managed"]` | Droplet tags |

### Stack Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `stacks` | `["mongodb"]` | List of stacks to deploy |
| `apps` | `[]` | List of {domain, port} for Nginx proxy |

### SSL/HTTPS Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_https` | `true` | Enable Let's Encrypt certificates |
| `use_cloudflare_cert` | `false` | Use Cloudflare Origin Certificate |
| `cloudflare_origin_cert` | `""` | PEM-formatted certificate content |
| `cloudflare_origin_key` | `""` | PEM-formatted private key content |

### Cloudflare Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `cloudflare_api_token` | `""` | Cloudflare API Token |
| `cloudflare_zone_id` | `""` | Cloudflare Zone ID |
| `cloudflare_proxied` | `true` | Enable Cloudflare proxy (CDN + DDoS) |

## Nginx Reverse Proxy

Configure the `apps` variable to expose services via domain:

```hcl
apps = [
  { domain = "mongo.example.com", port = 27017 },
  { domain = "redis.example.com", port = 6379 },
  { domain = "kafka.example.com", port = 9092 },
  { domain = "api.example.com", port = 3000 },
]
```

Each domain will get an Nginx server block with SSL termination.

## SSL Options

### Option 1: Let's Encrypt (Default)

```hcl
enable_https = true
app_email    = "you@example.com"
```

> **Note:** DNS must already point to the VPS IP before running Terraform.

### Option 2: Cloudflare Origin Certificate

```hcl
use_cloudflare_cert    = true
cloudflare_zone_id     = "your_zone_id"
cloudflare_api_token   = "your_api_token"
cloudflare_origin_cert = file("cloudflare.crt")
cloudflare_origin_key  = file("cloudflare.key")
```

**Benefits:**

| Feature | Let's Encrypt | Cloudflare Origin |
|---------|---------------|-------------------|
| Validity | 90 days | Up to 15 years |
| Auto-renewal | Requires cron | Not needed |
| Rate limits | Yes | No |
| DNS management | Manual | Automatic |
| CDN + DDoS | No | Yes (if proxied) |

## Environment Management

### Per-Environment Configuration

```bash
# Development
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform apply -var-file=environments/staging.tfvars

# Production
terraform apply -var-file=environments/prod.tfvars
```

### Auto-Loading Files

Files ending in `.auto.tfvars` load automatically:

```bash
terraform.auto.tfvars    # Non-sensitive, committed to git
local.auto.tfvars        # Sensitive, gitignored
```

## State Management (Recommended)

For production, use a remote backend:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "nomas/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Security

### Secrets Management

**NEVER** commit secrets to git. Use one of these methods:

- `.env` file (gitignored) with `TF_VAR_*` variables
- `local.auto.tfvars` (gitignored)
- Terraform Cloud workspace variables
- Secrets manager (AWS Secrets Manager, Vault, etc.)

### Firewall Rules

UFW is automatically configured with:

| Port | Service | Allowed |
|------|---------|---------|
| 22 | SSH | Yes |
| 80 | HTTP | Yes |
| 443 | HTTPS | Yes |

### SSH Access

```bash
# SSH into the deployed VPS
ssh root@<droplet_ip>
```

## Troubleshooting

### Check Cloud-Init Logs

```bash
ssh root@<droplet_ip>
cat /var/log/cloud-init-output.log
```

### Check Services

```bash
# Nginx status and config
systemctl status nginx
nginx -t

# Docker containers
docker ps
docker compose logs

# Certificate logs
cat /var/log/certbot-cloud-init.log
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Let's Encrypt fails | Ensure DNS points to VPS IP, then re-apply |
| Can't access services | Check UFW rules and Nginx config |
| Docker stack not running | Check `docker ps` and compose logs |
| Cloudflare DNS missing | Verify `cloudflare_zone_id` is correct |

## Outputs

| Output | Description |
|--------|-------------|
| `droplet_ip` | Public IP address of the VPS |
| `cloudflare_dns_record` | DNS record hostname (if using Cloudflare) |

## Destroy Resources

```bash
terraform destroy \
  -var "do_token=$TF_VAR_do_token" \
  -var "ssh_private_key=$TF_VAR_ssh_private_key" \
  -var "app_email=$TF_VAR_app_email"
```

## Testing

Run module tests (plan-only, no real resources created):

```bash
# Test VPS module
cd modules/vps && terraform init -backend=false && terraform test

# Test Docker stack module
cd modules/docker_stack && terraform init -backend=false && terraform test
```

## License

MIT
