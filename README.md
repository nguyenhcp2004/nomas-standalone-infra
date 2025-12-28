# Nomas Terraform - VPS Stack Deployment

> Automated VPS deployment on DigitalOcean with Docker stacks, Nginx reverse proxy, and SSL (Let's Encrypt).

## What This Does

This Terraform project automates the complete setup of a production-ready VPS:

- **Provisions** a DigitalOcean Droplet with cloud-init
- **Installs** Docker, Docker Compose, Nginx, UFW firewall, and Certbot
- **Deploys** pre-configured Docker stacks (MongoDB, Redis, Kafka)
- **Configures** Nginx as a reverse proxy for your applications
- **Secures** with Let's Encrypt SSL certificates
- **Supports** SSH password or key-based authentication
- **Multi-environment** support (dev, staging, prod) with isolated states

## Quick Start

### Prerequisites

| Requirement | Details |
|-------------|---------|
| Terraform | >= 1.6.0 |
| DigitalOcean API Token | [Create here](https://cloud.digitalocean.com/account/api/tokens) |
| SSH Key OR Password | For Docker stack deployment |
| Domain (optional) | For SSL certificates |

### 1. Clone

```bash
git clone <repository-url>
cd nomas-terraform
```

### 2. Configure Environment

Each environment has its own configuration. Copy the example file:

```bash
# For dev environment
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# Edit with your values
nano environments/dev/terraform.tfvars
```

### 3. Deploy

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

## Multi-Environment Deployment

This project uses **environment-based directories** following HashiCorp best practices:

```
environments/
├── dev/          # Development environment
├── staging/      # Staging environment
└── prod/         # Production environment
```

### Deploy to Different Environments

```bash
# Dev
cd environments/dev
terraform init
terraform apply -var-file=terraform.tfvars

# Staging
cd ../staging
terraform init
terraform apply -var-file=terraform.tfvars

# Production
cd ../prod
terraform init
terraform apply -var-file=terraform.tfvars
```

Each environment has:
- **Separate state** (stored in Terraform Cloud or local)
- **Isolated configuration** (droplet size, regions, etc.)
- **Independent credentials** (different passwords, tokens)

### Environment-Specific Settings

| Environment | Droplet Size | Use Case |
|-------------|--------------|----------|
| `dev` | `s-1vcpu-1gb` | Development/testing |
| `staging` | `s-2vcpu-4gb` | Pre-production testing |
| `prod` | `s-4vcpu-8gb` | Production workloads |

## Configuration

### Required Variables

Edit `terraform.tfvars` in your environment directory:

```hcl
# Required
do_token     = "dop_v1_xxx"              # DigitalOcean API Token
ssh_password = "your_secure_password"     # OR use ssh_private_key
app_email    = "you@example.com"          # For Let's Encrypt

# Database credentials (required for stacks)
mongodb_root_password   = "strong_password_here"
mongodb_replica_set_key = "unique_key_here"
redis_password          = "strong_password_here"
kafka_client_passwords  = "strong_password_here"

# VPS Settings
project_name = "myproject"
environment  = "dev"
region       = "sgp1"
size         = "s-2vcpu-4gb"

# Stacks to deploy
stacks = ["mongodb", "redis-cifarm", "kafka-cifarm"]

# Apps (configure after getting droplet IP)
apps = []
```

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `droplet_tags` | `["docker-stack"]` | Droplet tags |
| `enable_https` | `true` | Enable Let's Encrypt |
| `ssh_private_key` | `""` | SSH private key (alternative to password) |

## Deployment Flow

### Step 1: Initial Deployment

Deploy with empty `apps` to create the droplet and Docker stacks:

```bash
cd environments/dev
terraform apply
```

After completion, get the droplet IP:
```bash
terraform output droplet_ip
# Example output: 143.198.206.177
```

### Step 2: Configure Apps (Optional)

If you have a domain:

1. **Point your domain** to the droplet IP (A record in your DNS provider)
2. **Wait for DNS propagation** (5-30 minutes)
3. **Update `terraform.tfvars`:**
   ```hcl
   apps = [
     { domain = "yourdomain.com", port = 3000 },
     { domain = "www.yourdomain.com", port = 3000 },
   ]
   ```
4. **Re-apply:**
   ```bash
   terraform apply
   ```

This will configure Nginx reverse proxy and obtain Let's Encrypt SSL certificates.

## Project Structure

```
nomas-terraform/
├── environments/                 # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf              # Dev configuration
│   │   ├── backend.tf           # Terraform Cloud backend
│   │   ├── variables.tf         # Variable definitions
│   │   └── terraform.tfvars     # Dev values (gitignored)
│   ├── staging/
│   └── prod/
├── modules/                      # Reusable Terraform modules
│   ├── vps/                      # DigitalOcean Droplet module
│   └── docker_stack/             # Docker stack deployment module
├── compose/                      # Docker stack definitions
│   ├── mongodb/docker-compose.yml
│   ├── redis-cifarm/docker-compose.yml
│   └── kafka-cifarm/docker-compose.yml
├── cloud-init/
│   ├── base-cloud-init.yaml      # Cloud-init script for Droplet setup
│   └── nginx-app.conf.tpl        # Nginx config template for apps
└── scripts/
    └── deploy-stacks.sh.tpl      # Deployment script template
```

## Available Stacks

| Stack | Description | Services | Internal Port |
|-------|-------------|----------|---------------|
| `mongodb` | MongoDB Sharded Cluster | 3 shards + config servers | 27017 |
| `redis-cifarm` | Redis | Single instance | 6379 |
| `kafka-cifarm` | Kafka | KRaft mode | 9092 |

### Security Notes

- **Ports are NOT exposed** to the internet - only accessible via internal Docker networks
- Access services through Nginx reverse proxy with your domain
- Environment variables are injected at runtime (no .env files on disk)

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

## Terraform Cloud Integration

This project supports Terraform Cloud for remote state storage:

### Setup

1. **Login to Terraform Cloud:**
   ```bash
   terraform login
   ```

2. **Configure workspace (Local execution mode):**
   - Go to Terraform Cloud UI → Workspace
   - Set **Execution Mode** to `Local`
   - Set **Working Directory** to `environments/dev` (or staging/prod)

3. **Initialize:**
   ```bash
   cd environments/dev
   terraform init
   ```

### Benefits

- **Remote state storage** with automatic locking
- **State history** for rollback capability
- **Team collaboration** with shared state
- **Local execution** for privacy and flexibility

## Security

### Secrets Management

**NEVER** commit `terraform.tfvars` to git. Each environment has:

```bash
environments/
├── dev/terraform.tfvars         # Gitignored
├── dev/terraform.tfvars.example # Template (tracked)
```

Use one of these methods:
- Copy `.tfvars.example` to `.tfvars` and fill in values
- Environment variables: `export TF_VAR_do_token="xxx"`
- Terraform Cloud workspace variables (for remote execution)

### Database Credentials

Database passwords are **not hardcoded** in compose files:
- Docker Compose uses `${VARIABLE}` substitution
- Credentials are injected at deployment time via environment variables
- No `.env` files are stored on the VPS

Generate strong passwords:
```bash
openssl rand -base64 32
```

### Firewall Rules

UFW is automatically configured:

| Port | Service | Allowed |
|------|---------|---------|
| 22 | SSH | Yes |
| 80 | HTTP | Yes |
| 443 | HTTPS | Yes |

**Database ports are NOT exposed** - services run on internal Docker networks only.

### SSH Access

```bash
# SSH into the deployed VPS
ssh root@<droplet_ip>
# Password: as set in ssh_password variable
```

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

Each domain will get:
- Nginx server block with reverse proxy
- Let's Encrypt SSL certificate
- HTTP to HTTPS redirect

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

# View logs for a specific stack
cd /root/mongodb
docker compose logs

# Certificate logs
cat /var/log/certbot-cloud-init.log
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Droplet creation fails | Check `do_token` is valid |
| SSH connection timeout | Wait 3-5 minutes for cloud-init to finish |
| Docker not found | Cloud-init still installing, wait longer |
| Let's Encrypt fails | Ensure DNS points to VPS IP, then re-apply |
| Can't access services | Services are internal-only, use Nginx proxy |

### Droplet Size Guide

| Size | CPU | RAM | Price | Use Case |
|------|-----|-----|-------|----------|
| `s-1vcpu-1gb` | 1 | 1GB | $6/mo | Testing only |
| `s-2vcpu-4gb` | 2 | 4GB | $24/mo | Small projects |
| `s-4vcpu-8gb` | 4 | 8GB | $48/mo | Medium projects |

## Outputs

| Output | Description |
|--------|-------------|
| `droplet_ip` | Public IP address of the VPS |
| `droplet_name` | Name of the created Droplet |

## Destroy Resources

```bash
cd environments/dev
terraform destroy
```

Or destroy specific resources:
```bash
# Destroy only docker stacks (keeps VPS)
terraform destroy -target=null_resource.docker_stacks

# Destroy only nginx apps config
terraform destroy -target=null_resource.nginx_apps
```

## How It Works

### Module Flow

```
environments/dev/main.tf
  ├── module.vps (DigitalOcean Droplet + cloud-init)
  │     └── Installs Docker, Nginx, UFW, Certbot
  │
  ├── null_resource.docker_stacks (sequential deployment)
  │     └── Uploads deployment script via SSH
  │     └── Injects environment variables (no .env files)
  │     └── Deploys all stacks in single connection
  │
  └── null_resource.nginx_apps (when apps configured)
        └── Uploads Nginx config via SSH
        └── Obtains Let's Encrypt certificates
```

### Cloud-Init Process

1. **Set root password** (from `ssh_password`)
2. **Enable SSH password authentication**
3. **Install Docker Engine + Compose**
4. **Configure UFW firewall**
5. **Install Nginx**
6. **Install Certbot** (if `enable_https = true`)

### Docker Stack Deployment

All Docker stacks are deployed **sequentially** with environment variables:

- Database credentials injected via `export VAR=...`
- No `.env` files stored on disk
- Variables unset after deployment
- Stacks run on isolated internal networks

## Testing

Run module tests (plan-only, no real resources created):

```bash
# Test VPS module
cd modules/vps && terraform init -backend=false && terraform test

# Test docker_stack module
cd modules/docker_stack && terraform init -backend=false && terraform test
```

## License

MIT
