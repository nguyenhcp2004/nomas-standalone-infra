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

## Quick Start

### Prerequisites

| Requirement | Details |
|-------------|---------|
| Terraform | >= 1.6.0 |
| DigitalOcean API Token | [Create here](https://cloud.digitalocean.com/account/api/tokens) |
| SSH Key OR Password | For Docker stack deployment |
| Domain (optional) | For SSL certificates |

### 1. Clone and Initialize

```bash
git clone <repository-url>
cd nomas-terraform
terraform init
```

### 2. Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
# Required
do_token     = "dop_v1_xxx"              # DigitalOcean API Token
ssh_password = "your_password"           # OR use ssh_private_key
app_email    = "you@example.com"         # For Let's Encrypt

# VPS Settings (optional, have defaults)
droplet_name = "stack-1vps"
region       = "sgp1"
size         = "s-2vcpu-4gb"

# Stacks to deploy
stacks = ["mongodb", "redis-cifarm", "kafka-cifarm"]

# Apps (configure after getting droplet IP)
apps = []
```

### 3. Deploy

```bash
terraform plan    # Preview changes
terraform apply   # Deploy
```

## Deployment Flow

### Step 1: Initial Deployment

Deploy with empty `apps` to create the droplet and Docker stacks:

```bash
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
├── main.tf                       # Root configuration
├── variables.tf                  # Input variable definitions
├── terraform.tfvars              # Your variables (gitignored)
├── cloud-init/
│   ├── base-cloud-init.yaml      # Cloud-init script for Droplet setup
│   └── nginx-app.conf.tpl        # Nginx config template for apps
├── compose/                      # Docker stack definitions
│   ├── mongodb/docker-compose.yml
│   ├── redis-cifarm/docker-compose.yml
│   └── kafka-cifarm/docker-compose.yml
└── modules/
    ├── vps/                      # DigitalOcean Droplet module
    └── docker_stack/             # Docker Compose deployment via SSH
```

## Available Stacks

| Stack | Description | Services | Default Port |
|-------|-------------|----------|--------------|
| `mongodb` | MongoDB Sharded Cluster | 3 shards + config servers | 27018 |
| `redis-cifarm` | Redis | Single instance | 6379 |
| `kafka-cifarm` | Kafka | KRaft mode | 9092 |

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

### Authentication (Choose One)

| Variable | Description | Required |
|----------|-------------|----------|
| `ssh_password` | Root password for SSH auth | Yes (or ssh_private_key) |
| `ssh_private_key` | SSH private key content | Yes (or ssh_password) |

**Note:** SSH password is automatically set on the droplet via cloud-init. Password authentication is enabled automatically.

### Required Variables

| Variable | Description |
|----------|-------------|
| `do_token` | DigitalOcean API Token |
| `app_email` | Email for Let's Encrypt certificates |

### Droplet Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `droplet_name` | `stack-1vps` | Name of the Droplet |
| `region` | `sgp1` | DigitalOcean region |
| `size` | `s-2vcpu-4gb` | Droplet size slug |
| `image` | `ubuntu-22-04-x64` | OS image |
| `ssh_keys` | `[]` | List of SSH key fingerprints (DO) |
| `droplet_tags` | `["terraform-managed"]` | Droplet tags |

### Stack Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `stacks` | `["mongodb"]` | List of stacks to deploy |
| `apps` | `[]` | List of {domain, port} for Nginx proxy |

### SSL Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_https` | `true` | Enable Let's Encrypt certificates |

## Nginx Reverse Proxy

Configure the `apps` variable to expose services via domain:

```hcl
apps = [
  { domain = "mongo.example.com", port = 27018 },
  { domain = "redis.example.com", port = 6379 },
  { domain = "kafka.example.com", port = 9092 },
  { domain = "api.example.com", port = 3000 },
]
```

Each domain will get:
- Nginx server block with reverse proxy
- Let's Encrypt SSL certificate
- HTTP to HTTPS redirect

## Security

### Secrets Management

**NEVER** commit `terraform.tfvars` to git. Use one of these methods:

- `terraform.tfvars` (add to `.gitignore`)
- Environment variables: `export TF_VAR_do_token="xxx"`
- Terraform Cloud workspace variables

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
# Password: as set in ssh_password variable
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
| Can't access services | Check UFW allows the port |

### Droplet Size Guide

| Size | CPU | RAM | Price | Use Case |
|------|-----|-----|-------|----------|
| `s-1vcpu-1gb` | 1 | 1GB | $6/mo | Testing only |
| `s-2vcpu-4gb` | 2 | 4GB | $24/mo | Small projects (default) |
| `s-4vcpu-8gb` | 4 | 8GB | $48/mo | Medium projects |

## Outputs

| Output | Description |
|--------|-------------|
| `droplet_ip` | Public IP address of the VPS |

## Destroy Resources

```bash
terraform destroy
```

Or destroy specific resources:
```bash
# Destroy only docker stacks (keeps VPS)
terraform destroy -target=module.docker_stacks

# Destroy only nginx apps config
terraform destroy -target=null_resource.nginx_apps
```

## How It Works

### Module Flow

```
main.tf
  ├── module.vps (DigitalOcean Droplet + cloud-init)
  │     └── Installs Docker, Nginx, UFW, Certbot
  │
  ├── module.docker_stacks (for each stack)
  │     └── Copies compose file via SSH
  │     └── Runs docker compose up
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
