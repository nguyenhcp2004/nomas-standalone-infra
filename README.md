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

## Quick start
```bash
terraform init
terraform plan -out tfplan ^
  -var "do_token=YOUR_DO_TOKEN" ^
  -var "ssh_password=YOUR_ROOT_PASSWORD" ^
  -var "region=sgp1" ^
  -var "size=s-4vcpu-8gb" ^
  -var "stack=redis-cifarm"   # mongodb | redis-cifarm | kafka-cifarm

terraform apply "tfplan"
```

> Recommendation: use SSH keys instead of password. Configure `ssh_keys` and omit `ssh_password`.

### Docker provider (optional)
- If you want Terraform to manage Docker via the `docker` provider, pass `docker_host`.
- Example (needs SSH key agent): `-var "docker_host=ssh://root@<DROPLET_IP>:22"`
- If empty, it uses local socket `unix:///var/run/docker.sock`.

## Customize
- Other providers: replace `digitalocean` with your provider; keep `null_resource` logic.
- Add Nginx/Certbot: extend `cloud-init.yaml` (install `nginx`, `snapd`, `certbot`) or add as a service in `docker-compose.yml`.
- Firewall: adjust UFW in `cloud-init.yaml`; for other clouds use their security groups.

## Destroy
```bash
terraform destroy -var "do_token=..." -var "ssh_password=..."
```

