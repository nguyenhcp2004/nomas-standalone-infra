# Nomas Terraform - VPS Stack Deployment

> Automated VPS deployment on DigitalOcean with Docker stacks, Nginx reverse proxy, and SSL (Let's Encrypt).

## What This Does

This Terraform project automates the complete setup of a production-ready VPS:

- **Provisions** a DigitalOcean Droplet with cloud-init
- **Installs** Docker, Docker Compose, Nginx, UFW firewall, and Certbot
- **Deploys** pre-configured Docker stacks (MongoDB, Redis, Kafka, Arcane, Grafana-Loki-Prometheus)
- **Configures** Nginx as a reverse proxy for your applications
- **Secures** with Let's Encrypt SSL certificates
- **Supports** SSH password or key-based authentication
- **Multi-environment** support (dev, staging, prod) with isolated states
- **Cross-stack networking** with shared backend network

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
cd nomas-standalone-infra
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
| `dev` | `s-2vcpu-4gb` | Development/testing |
| `staging` | `s-4vcpu-8gb` | Pre-production testing |
| `prod` | `s-8vcpu-16gb` | Production workloads |

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

# Arcane credentials (if deploying arcane stack)
arcane_encryption_key = "your_encryption_key_32_chars"
arcane_jwt_secret     = "your_jwt_secret_32_chars"

# Grafana credentials (if deploying grafana-loki-prometheus stack)
grafana_admin_user     = "admin"
grafana_admin_password = "strong_grafana_password"
grafana_root_url       = "http://localhost:3000"

# VPS Settings
project_name = "myproject"
environment  = "dev"
region       = "sgp1"
size         = "s-2vcpu-4gb"

# Stacks to deploy
stacks = ["mongodb", "redis-cifarm", "kafka-cifarm", "arcane", "grafana-loki-prometheus"]

# Apps (configure after getting droplet IP)
apps = []

# Backend network name for cross-stack communication
backend_network_name = "backend-net"
```

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `droplet_tags` | `["docker-stack"]` | Droplet tags |
| `enable_https` | `true` | Enable Let's Encrypt |
| `ssh_private_key` | `""` | SSH private key (alternative to password) |
| `backend_network_name` | `"backend-net"` | Docker network for cross-stack communication |

## Deployment Flow

### Step 1: Initial Deployment

Deploy with empty `apps` to create the droplet and Docker stacks:

```bash
cd environments/dev
terraform apply
```

**What happens during deployment:**
1. VPS is provisioned with cloud-init
2. Docker, Nginx, UFW, Certbot are installed
3. Backend network (`backend-net`) is created for cross-stack communication
4. Stack images are pulled with **automatic retry** (3 attempts, 10s delay)
5. Each stack is deployed with environment variables injected at runtime

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
     { domain = "grafana.yourdomain.com", port = 3000 },
   ]
   ```
4. **Re-apply:**
   ```bash
   terraform apply
   ```

This will configure Nginx reverse proxy and obtain Let's Encrypt SSL certificates.

## Project Structure

```
nomas-standalone-infra/
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
│   ├── kafka-cifarm/docker-compose.yml
│   ├── arcane/docker-compose.yml
│   └── grafana-loki-prometheus/docker-compose.yml
├── cloud-init/
│   ├── base-cloud-init.yaml      # Cloud-init script for Droplet setup
│   └── nginx-app.conf.tpl        # Nginx config template for apps
└── scripts/
    └── deploy-stacks.sh.tpl      # Deployment script template with retry logic
```

## Available Stacks

| Stack | Description | Services | Internal Ports |
|-------|-------------|----------|----------------|
| `mongodb` | MongoDB Sharded Cluster | 3 shards + config servers | 27017 |
| `redis-cifarm` | Redis | Single instance | 6379 |
| `kafka-cifarm` | Kafka | KRaft mode | 9092 |
| `arcane` | Custom application | Arcane app | 8080 |
| `grafana-loki-prometheus` | Monitoring stack | Grafana, Loki, Prometheus | 3000, 3100, 9090 |

### Security Notes

- **Ports are NOT exposed** to the internet - only accessible via internal Docker networks
- Grafana port 3000 is exposed for direct access
- All services connect via `backend-net` for cross-stack communication
- Environment variables are injected at runtime (no .env files on disk)

### Deploying Multiple Stacks

```hcl
# Deploy all stacks
stacks = ["mongodb", "redis-cifarm", "kafka-cifarm", "arcane", "grafana-loki-prometheus"]

# Deploy specific stacks
stacks = ["mongodb", "redis-cifarm", "grafana-loki-prometheus"]
```

Each stack deploys to its own directory on the VPS:
- `/root/mongodb/docker-compose.yml`
- `/root/redis-cifarm/docker-compose.yml`
- `/root/kafka-cifarm/docker-compose.yml`
- `/root/arcane/docker-compose.yml`
- `/root/grafana-loki-prometheus/docker-compose.yml`

## Docker Image Pull with Retry

The deployment script includes automatic retry logic for pulling Docker images:

- **3 retry attempts** per stack
- **10 minute timeout** per attempt
- **10 second delay** between retries
- **Parallel pulling** - all stacks pull images simultaneously

```bash
# Example output during deployment
==> Phase 2: Pulling all images (parallel, with retry up to 3 times)...
  [mongodb] Pull attempt 1/3...
  [mongodb] Pull succeeded!
  [grafana-loki-prometheus] Pull attempt 1/3...
  [grafana-loki-prometheus] Pull failed (attempt 1/3)
  [grafana-loki-prometheus] Retrying in 10 seconds...
  [grafana-loki-prometheus] Pull attempt 2/3...
  [grafana-loki-prometheus] Pull succeeded!
```

If all retries fail, the script continues and `docker compose up` will retry the pull.

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

### Using Local Backend (Alternative)

If Terraform Cloud is not accessible, edit `backend.tf`:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
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
| 3000 | Grafana (if deployed) | Yes |

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
  { domain = "api.example.com", port = 3000 },
  { domain = "grafana.example.com", port = 3000 },
]
```

Each domain will get:
- Nginx server block with reverse proxy
- Let's Encrypt SSL certificate
- HTTP to HTTPS redirect

## Cross-Stack Communication

All stacks are connected via the `backend-net` Docker network:

```bash
# From any container, you can reach services from other stacks:
# mongodb:27017
# redis:6379
# kafka:9092
# arcane:8080
# grafana:3000
# prometheus:9090
# loki:3100
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

# Check backend network
docker network ls | grep backend

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
| Terraform Cloud timeout | Switch to local backend in `backend.tf` |
| Docker not found | Cloud-init still installing, wait longer |
| Image pull fails | Script auto-retries 3 times, check logs |
| Let's Encrypt fails | Ensure DNS points to VPS IP, then re-apply |
| Can't access services | Services are internal-only, use Nginx proxy or expose port |
| Stack not deployed | Check stack name matches `compose/<stack>/docker-compose.yml` |

### Droplet Size Guide

| Size | CPU | RAM | Price | Use Case |
|------|-----|-----|-------|----------|
| `s-1vcpu-1gb` | 1 | 1GB | $6/mo | Testing only |
| `s-2vcpu-4gb` | 2 | 4GB | $24/mo | Small projects (MongoDB + Redis) |
| `s-4vcpu-8gb` | 4 | 8GB | $48/mo | Medium projects (+ Kafka, monitoring) |
| `s-8vcpu-16gb` | 8 | 16GB | $96/mo | Large projects (all stacks) |

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
  │     └── Creates backend-net network
  │
  ├── null_resource.docker_stacks (3-phase deployment)
  │     ├── Phase 1: Prepare all compose files
  │     ├── Phase 2: Pull images with retry (parallel, 3 attempts)
  │     └── Phase 3: Deploy stacks with environment variables
  │
  └── null_resource.nginx_apps (when apps configured)
        └── Uploads Nginx config via SSH
        └── Obtains Let's Encrypt certificates
```

### Cloud-Init Process

1. **Set root password** (from `ssh_password`)
2. **Enable SSH password authentication**
3. **Install Docker Engine + Compose**
4. **Create backend-net network** for cross-stack communication
5. **Configure UFW firewall**
6. **Install Nginx**
7. **Install Certbot** (if `enable_https = true`)

### Docker Stack Deployment (3-Phase)

**Phase 1: Prepare**
- Create `/root/<stack>/` directories
- Write docker-compose.yml files

**Phase 2: Pull (Parallel)**
- All stacks pull images simultaneously
- 3 retry attempts with 10s delay
- 10 minute timeout per attempt

**Phase 3: Deploy (Sequential)**
- Deploy each stack with environment variables
- Variables unset after deployment
- No .env files stored on disk

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
