#!/bin/bash
set -e

echo "==> Waiting for cloud-init to complete..."
cloud-init status --wait || echo 'Cloud-init already completed'

echo "==> Verifying Docker is ready..."
docker info >/dev/null || (echo 'Docker not ready, waiting 30s...' && sleep 30 && docker info)

%{ for stack in stacks ~}
echo ""
echo "==> Deploying ${stack}..."
mkdir -p /root/${stack}

# Write docker-compose.yml
cat > /root/${stack}/docker-compose.yml <<'EOF_COMPOSE'
${compose_contents[stack].content}
EOF_COMPOSE

# Deploy with environment variables passed directly (no .env file on disk)
cd /root/${stack}

%{ if stack == "mongodb" ~}
export MONGODB_ROOT_PASSWORD='${mongodb_root_password}'
export MONGODB_REPLICA_SET_KEY='${mongodb_replica_set_key}'
%{ endif ~}

%{ if stack == "redis-cifarm" ~}
export REDIS_PASSWORD='${redis_password}'
%{ endif ~}

%{ if stack == "kafka-cifarm" ~}
export KAFKA_CLIENT_PASSWORDS='${kafka_client_passwords}'
%{ endif ~}

%{ if stack == "arcane" ~}
export ENCRYPTION_KEY='${arcane_encryption_key}'
export JWT_SECRET='${arcane_jwt_secret}'
%{ endif ~}

%{ if stack == "grafana-loki-prometheus" ~}
export GF_SECURITY_ADMIN_USER='${grafana_admin_user:-admin}'
export GF_SECURITY_ADMIN_PASSWORD='${grafana_admin_password}'
export GF_SERVER_ROOT_URL='${grafana_root_url:-http://localhost:3000}'
%{ endif ~}

docker compose pull
docker compose up -d

# Clear exported variables from shell
unset MONGODB_ROOT_PASSWORD MONGODB_REPLICA_SET_KEY REDIS_PASSWORD KAFKA_CLIENT_PASSWORDS ENCRYPTION_KEY JWT_SECRET GF_SECURITY_ADMIN_USER GF_SECURITY_ADMIN_PASSWORD GF_SERVER_ROOT_URL 2>/dev/null || true
%{ endfor ~}

echo ""
echo "==> All stacks deployed successfully"
