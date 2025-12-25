# Security Policy

## Secrets Management

### Terraform State
The Terraform state file may contain sensitive data. For production:
- Use a remote backend with encryption (S3, Terraform Cloud, etc.)
- Enable state locking (DynamoDB for S3, or Terraform Cloud)
- Never commit `terraform.tfstate` to version control

### Variables Marked as Sensitive
The following variables are marked `sensitive = true`:
- `do_token` - DigitalOcean API token
- `ssh_private_key` - SSH private key for VPS access
- `cloudflare_api_token` - Cloudflare API token
- `cloudflare_origin_cert` - Cloudflare Origin Certificate
- `cloudflare_origin_key` - Cloudflare Origin Certificate private key

### Recommended Secret Storage

1. **terraform.tfvars** (excluded by .gitignore)
   ```bash
   terraform.tfvars
   terraform.tfvars.json
   *.auto.tfvars
   ```

2. **Environment Variables**
   ```bash
   export TF_VAR_do_token="dop_v1_xxx"
   export TF_VAR_ssh_private_key="$(cat ~/.ssh/id_rsa)"
   ```

3. **Terraform Cloud/Enterprise**
   - Store secrets in workspace variables
   - Automatically injected at runtime

4. **External Secrets Managers**
   - AWS Secrets Manager
   - HashiCorp Vault
   - Azure Key Vault

## Certificate Handling

### Cloudflare Origin Certificate

**WARNING:** The Cloudflare Origin Certificate private key is currently embedded in the cloud-init template. While this is convenient, it has security implications:

1. **Exposure Locations:**
   - Terraform state (even with `sensitive = true`)
   - DigitalOcean droplet metadata (user_data)
   - Cloud-init logs

2. **Recommendations for Production:**
   - Use a secrets manager to retrieve certificates at boot time
   - Or provision certificates via external tool (Ansible, custom script)
   - Rotate certificates regularly

3. **Alternative Approach:**
   - Store certificates in S3/Spaces with bucket policy
   - Use Instance Metadata Service (IMDS) with proper IAM roles
   - Fetch via cloud-init script from secure location

### Let's Encrypt Certificates

Let's Encrypt certificates are managed by Certbot:
- Stored at `/etc/letsencrypt/live/`
- Auto-renewal via cron job (recommended to add)
- No manual intervention needed after initial setup

**Add to crontab for auto-renewal:**
```bash
0 0 * * * certbot renew --quiet
```

## SSH Authentication

### Key-Based Authentication (Required)
This project requires SSH key authentication. Password authentication is deprecated and blocked.

**Setup:**
1. Generate SSH key pair (or use existing):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/do_deploy
   ```

2. Add public key to DigitalOcean:
   - Via UI: Settings → Security → SSH Keys
   - Via API: Use `doctl compute ssh-key import`

3. Use private key with Terraform:
   ```bash
   -var "ssh_private_key=$(cat ~/.ssh/do_deploy)"
   ```

## Network Security

### Firewall Rules (UFW)
The cloud-init script configures UFW with:
- Port 22: SSH (from any IP)
- Port 80: HTTP
- Port 443: HTTPS

**Recommendation:** Restrict SSH access to specific IPs:
```yaml
# In cloud-init, replace with:
- ufw allow from YOUR_IP/32 to any port 22
```

### SSL/TLS Configuration
- Let's Encrypt: Full chain certificate, auto-renewed
- Cloudflare Origin: Use Full (strict) mode in Cloudflare Dashboard

## Compliance

For production deployments requiring compliance (SOC2, HIPAA, etc.):
1. Enable Cloud Audit Logs (DigitalOcean)
2. Enable centralized logging (Papertrail, Datadog, etc.)
3. Implement secret rotation policies
4. Regular security scans (`tfsec`, `checkov`)
5. Use VPC with private subnets where applicable

## Reporting Security Issues

For security vulnerabilities, please:
1. Do NOT open a public issue
2. Email security details to the project maintainer
3. Allow time for remediation before disclosure
