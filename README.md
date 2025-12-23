# Terraform 1-VPS Stack (Docker Compose)

Provision a single VPS (e.g., DigitalOcean), install Docker + Docker Compose, copy your `docker-compose.yml`, and run `docker compose up -d`.

## Structure
- `main.tf`: DigitalOcean provider, droplet, copy compose, run stack.
- `variables.tf`: configuration variables (token, size, region, ssh, compose).
- `cloud-init.yaml`: installs Docker/Compose, enables basic UFW (SSH/80/443).

## Prerequisites
1) Terraform >= 1.6.0.  
2) A `docker-compose.yml` in this repo (or set `compose_source`).  
3) DigitalOcean API token.
4) (Optional) Cloudflare API token + Zone ID if using Cloudflare DNS/Origin Certificate.

## Quick start
```bash
terraform init
terraform plan -out tfplan ^
  -var "do_token=YOUR_DO_TOKEN" ^
  -var "ssh_password=YOUR_ROOT_PASSWORD" ^
  -var "region=sgp1" ^
  -var "size=s-4vcpu-8gb" ^
  -var "stack=redis-cifarm" ^
  -var "app_domain=api.example.com" ^
  -var "app_email=you@example.com" ^
  -var "app_port=3000" ^
  -var "enable_https=true"

terraform apply "tfplan"
```

> **Note**: 
> - If using Cloudflare: DNS record will be created automatically. Ensure Cloudflare SSL/TLS mode is set to "Full (strict)".
> - If using Let's Encrypt: Ensure DNS is already pointing to the VPS IP before running `terraform apply` (or re-run after getting the IP). Certbot will automatically renew certificates.

> Recommendation: use SSH keys instead of password. Configure `ssh_keys` and omit `ssh_password`.

### Docker provider (optional)
- If you want Terraform to manage Docker via the `docker` provider, pass `docker_host`.
- Example (needs SSH key agent): `-var "docker_host=ssh://root@<DROPLET_IP>:22"`
- If empty, it uses local socket `unix:///var/run/docker.sock`.

## Cloudflare Setup (Optional)

If using Cloudflare Origin Certificate:

1. Create Origin Certificate in Cloudflare Dashboard:
   - Go to SSL/TLS → Origin Server → Create Certificate
   - Select hostnames (e.g., `*.example.com, example.com`)
   - Download certificate and private key
2. Pass them as variables:

```bash
terraform plan -out tfplan ^
  -var "do_token=..." ^
  -var "ssh_password=..." ^
  -var "cloudflare_api_token=..." ^
  -var "cloudflare_zone_id=..." ^
  -var "cloudflare_origin_cert=$(cat cloudflare.crt)" ^
  -var "cloudflare_origin_key=$(cat cloudflare.key)" ^
  -var "use_cloudflare_cert=true" ^
  -var "app_domain=api.example.com" ^
  -var "app_port=3000" ^
  ...
```

DNS record will be created automatically pointing to the VPS IP.

**Benefits of Cloudflare Origin Certificate:**
- No renewal needed (valid for up to 15 years)
- No rate limits
- Automatic DNS management
- CDN + DDoS protection (if `cloudflare_proxied = true`)

## Customize
- Other providers: replace `digitalocean` with your provider; keep `null_resource` logic.
- Nginx/Certbot: automatically installed and configured via `cloud-init`. Set `app_domain`, `app_email`, `app_port`, and `enable_https` variables.
- Cloudflare: set `cloudflare_api_token`, `cloudflare_zone_id`, and origin cert/key for automatic DNS + SSL.
- Firewall: UFW configured in `cloud-init.yaml` (SSH + Nginx Full); for other clouds use their security groups.

## Destroy
```bash
terraform destroy -var "do_token=..." -var "ssh_password=..."
```

