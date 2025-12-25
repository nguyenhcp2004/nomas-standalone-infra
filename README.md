# Nomas Terraform - VPS Stack Deployment

> Automated VPS deployment on DigitalOcean with Docker Compose, Nginx reverse proxy, and SSL (Let's Encrypt or Cloudflare Origin Certificate).

## 📋 Overview

This project uses Terraform to:

- Create Droplets (VPS) on DigitalOcean
- Automatically install Docker & Docker Compose
- Configure Nginx as a reverse proxy
- Support SSL with Let's Encrypt or Cloudflare Origin Certificate
- Deploy ready-to-use Docker stacks (MongoDB, Redis, Kafka)

## 📁 Project Structure

```
├── main.tf                          # Entry point - providers & modules
├── variables.tf                     # Variable definitions
├── cloud-init/
│   └── base-cloud-init.yaml         # Cloud-init script (Docker, Nginx, UFW, Certbot)
├── compose/                         # Available Docker Compose stacks
│   ├── mongodb/docker-compose.yml
│   ├── redis-cifarm/docker-compose.yml
│   └── kafka-cifarm/docker-compose.yml
└── modules/
    ├── vps/                         # DigitalOcean Droplet module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── docker_stack/                # Docker Compose deployment module
        ├── main.tf
        └── variables.tf
```

## ⚙️ Requirements

- **Terraform** >= 1.6.0
- **DigitalOcean API Token** ([Create here](https://cloud.digitalocean.com/account/api/tokens))
- **SSH Private Key** for Docker stack deployment
- **(Optional)** Cloudflare API Token + Zone ID if using Cloudflare DNS/SSL

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Configure Backend for Production (Recommended)

```bash
# Create backend.tf file with:
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "nomas/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Or uncomment the backend section in `main.tf`.

### 3. Deploy with Let's Encrypt SSL

```bash
terraform plan -out tfplan \
  -var "do_token=dop_v1_xxxxxxxxxxxx" \
  -var "ssh_private_key=$(cat ~/.ssh/id_rsa)" \
  -var "region=sgp1" \
  -var "size=s-4vcpu-8gb" \
  -var "stack=redis-cifarm" \
  -var "apps=[{ domain = \"api.example.com\", port = 3000 }]" \
  -var "app_email=you@example.com" \
  -var "enable_https=true"

terraform apply "tfplan"
```

### 4. Deploy with Cloudflare Origin Certificate

```bash
terraform plan -out tfplan \
  -var "do_token=dop_v1_xxxxxxxxxxxx" \
  -var "ssh_private_key=$(cat ~/.ssh/id_rsa)" \
  -var "region=sgp1" \
  -var "size=s-4vcpu-8gb" \
  -var "stack=mongodb" \
  -var "apps=[{ domain = \"api.example.com\", port = 3000 }]" \
  -var "app_email=you@example.com" \
  -var "cloudflare_api_token=YOUR_CF_TOKEN" \
  -var "cloudflare_zone_id=YOUR_ZONE_ID" \
  -var "cloudflare_origin_cert=$(cat cloudflare.crt)" \
  -var "cloudflare_origin_key=$(cat cloudflare.key)" \
  -var "use_cloudflare_cert=true"

terraform apply "tfplan"
```

### 5. Using terraform.tfvars (Recommended)

Create a `terraform.tfvars` file:

```hcl
do_token       = "dop_v1_xxxxxxxxxxxx"
ssh_private_key = file("${pathexpand("~/.ssh/id_rsa")}")
app_email      = "you@example.com"
apps           = [{ domain = "api.example.com", port = 3000 }]
stack          = "mongodb"
```

Then run:

```bash
terraform plan
terraform apply
```

## 📝 Configuration Variables

| Variable                  | Description                                                       | Default                                 | Required |
| ------------------------- | ----------------------------------------------------------------- | --------------------------------------- | -------- |
| `do_token`                | DigitalOcean API Token                                            | -                                       | ✅       |
| `ssh_private_key`         | SSH private key content                                           | -                                       | ✅       |
| `ssh_user`                | SSH user                                                          | `root`                                  | ❌       |
| `droplet_name`            | Droplet name                                                      | `stack-1vps`                            | ❌       |
| `droplet_tags`            | Tags for Droplet                                                  | `["terraform-managed", "docker-stack"]` | ❌       |
| `region`                  | Deployment region                                                 | `sgp1`                                  | ❌       |
| `size`                    | Droplet size                                                      | `s-4vcpu-8gb`                           | ❌       |
| `image`                   | OS image                                                          | `ubuntu-22-04-x64`                      | ❌       |
| `ssh_keys`                | List of SSH key fingerprints for DO                               | `[]`                                    | ❌       |
| `stack`                   | Stack to deploy (`mongodb`, `redis-cifarm`, `kafka-cifarm`)       | `mongodb`                               | ❌       |
| `apps`                    | List of apps with domain and port                                 | `[]`                                    | ❌       |
| `app_email`               | Email for Let's Encrypt                                           | -                                       | ✅\*     |
| `enable_https`            | Enable automatic HTTPS with Certbot                               | `true`                                  | ❌       |
| `cloudflare_api_token`    | Cloudflare API Token                                              | `""`                                    | ❌       |
| `cloudflare_zone_id`      | Cloudflare Zone ID                                                | `""`                                    | ❌       |
| `use_cloudflare_cert`     | Use Cloudflare Origin Certificate                                  | `false`                                 | ❌       |
| `cloudflare_origin_cert`  | Cloudflare certificate content (PEM)                               | `""`                                    | ❌       |
| `cloudflare_origin_key`   | Certificate private key (PEM)                                     | `""`                                    | ❌       |
| `cloudflare_proxied`      | Enable Cloudflare proxy (CDN + DDoS)                               | `true`                                  | ❌       |

\*Required when `enable_https = true`

## 🐳 Available Stacks

| Stack          | Description                      |
| -------------- | -------------------------------- |
| `mongodb`      | MongoDB database                 |
| `redis-cifarm` | Redis for CiFarm                 |
| `kafka-cifarm` | Kafka message broker for CiFarm  |

To use a custom Docker Compose file, place the file and use the `compose_source` variable:

```bash
-var "compose_source=path/to/your/docker-compose.yml"
```

## ☁️ Cloudflare Setup

### Creating an Origin Certificate

1. Login to **Cloudflare Dashboard** → select your domain
2. Go to **SSL/TLS** → **Origin Server** → **Create Certificate**
3. Choose hostnames (e.g., `*.example.com`, `example.com`)
4. Select validity (recommended: 15 years)
5. Download the certificate and private key

### Benefits of Cloudflare Origin Certificate

| Feature     | Let's Encrypt | Cloudflare Origin |
| ----------- | ------------- | ----------------- |
| Validity    | 90 days       | Up to 15 years    |
| Auto-renew  | Needs cron    | Not needed        |
| Rate limit  | Yes           | No                |
| DNS management | Manual      | Automatic         |
| CDN + DDoS  | ❌            | ✅ (if proxied)   |

> ⚠️ **Note**: When using Cloudflare Origin Certificate, set SSL/TLS mode to **Full (strict)** in Cloudflare Dashboard.

## 🔐 Security

### SSH Key Authentication

This project uses SSH key authentication instead of passwords. Add your SSH public key to DigitalOcean before running Terraform:

```bash
# Add SSH key to DigitalOcean via API or UI
# Then use the fingerprint for droplet access
terraform apply \
  -var "ssh_keys=[\"your_ssh_key_fingerprint\"]" \
  -var "ssh_private_key=$(cat ~/.ssh/id_rsa)"
```

### Secrets Management

**NEVER** commit secrets to git. Use one of the following methods:

- `terraform.tfvars` (already in .gitignore)
- Environment variables: `export TF_VAR_do_token=xxx`
- Terraform Cloud/Enterprise workspace variables
- Secrets manager (AWS Secrets Manager, Vault, etc.)

### Firewall (UFW)

Cloud-init automatically configures UFW with the following rules:

- ✅ SSH (port 22)
- ✅ HTTP (port 80)
- ✅ HTTPS (port 443)

## 🔧 Customization

### Using Other Providers (AWS, GCP, etc.)

1. Replace the `vps` module with the corresponding provider
2. Keep the `docker_stack` module (uses SSH connection)
3. Update `cloud-init` if needed

## 🗑️ Destroy Resources

```bash
terraform destroy \
  -var "do_token=YOUR_DO_TOKEN" \
  -var "ssh_private_key=$(cat ~/.ssh/id_rsa)" \
  -var "app_email=you@example.com"
```

## ✅ Testing

### Terraform test (HCL)

- Module `vps`: `cd modules/vps && terraform init -backend=false && terraform test`
- Module `docker_stack`: `cd modules/docker_stack && terraform init -backend=false && terraform test`
- Tests only run `plan` with dummy variables and `-backend=false`, no real resources created.

## 📤 Outputs

| Output                  | Description                                         |
| ----------------------- | --------------------------------------------------- |
| `droplet_ip`            | Public IP of the VPS                                |
| `cloudflare_dns_record` | DNS record hostname (if using Cloudflare)           |

## 📌 Important Notes

1. **Let's Encrypt**: Ensure DNS points to the VPS IP before running `terraform apply`, or re-run after getting the IP.

2. **Cloudflare**: DNS records will be automatically created when `cloudflare_zone_id` is provided.

3. **Boot time**: Cloud-init takes 2-5 minutes to complete Docker, Nginx, and SSL installation.

4. **Debug**: SSH into the VPS and check logs:

   ```bash
   # Cloud-init logs
   cat /var/log/cloud-init-output.log

   # Certificate logs
   cat /var/log/certbot-cloud-init.log

   # Nginx status
   systemctl status nginx
   nginx -t

   # Docker status
   docker ps
   docker compose logs
   ```

## 📄 License

MIT
