#!/bin/bash
set -e

echo "==> Waiting for cloud-init to complete..."
cloud-init status --wait || echo 'Cloud-init already completed'

echo "==> Verifying Docker is ready..."
docker info >/dev/null || (echo 'Docker not ready, waiting 30s...' && sleep 30 && docker info)

# =============================================================================
# Phase 1: Prepare all docker-compose.yml files
# =============================================================================
echo ""
echo "==> Phase 1: Preparing compose files..."
BACKEND_NETWORK="${BACKEND_NETWORK_NAME:-backend-net}"
%{ for stack in stacks ~}
mkdir -p /root/${stack}
cat > /root/${stack}/docker-compose.yml <<'EOF_COMPOSE_${stack}'
${compose_contents[stack].content}
EOF_COMPOSE_${stack}
%{ endfor ~}

# Replace placeholder network name with actual network name
for stack in %{ for stack in stacks ~}${stack} %{ endfor ~}; do
  sed -i "s/__BACKEND_NETWORK_PLACEHOLDER__/$BACKEND_NETWORK/g" /root/$stack/docker-compose.yml
done
echo "Compose files ready (using network: $BACKEND_NETWORK)."

# =============================================================================
# Phase 2: Pull all images in parallel (background jobs)
# =============================================================================
echo ""
echo "==> Phase 2: Pulling all images (parallel, 5min timeout per stack)..."
%{ for stack in stacks ~}
(
  cd /root/${stack}
  timeout 300 docker compose pull --parallel --quiet 2>/dev/null || echo "  ${stack}: Pull timeout or failed (will retry on start)"
) &
%{ endfor ~}

# Wait for all background pull jobs to complete
wait
echo "All pull jobs completed."

# =============================================================================
# Phase 3: Deploy each stack with environment variables
# =============================================================================
echo ""
echo "==> Phase 3: Deploying stacks..."
%{ for stack in stacks ~}
echo ""
echo "==> Deploying ${stack}..."
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
export GF_SECURITY_ADMIN_USER='${grafana_admin_user}'
export GF_SECURITY_ADMIN_PASSWORD='${grafana_admin_password}'
export GF_SERVER_ROOT_URL='${grafana_root_url}'
%{ endif ~}

docker compose up -d

# Clear exported variables from shell
unset MONGODB_ROOT_PASSWORD MONGODB_REPLICA_SET_KEY REDIS_PASSWORD KAFKA_CLIENT_PASSWORDS ENCRYPTION_KEY JWT_SECRET GF_SECURITY_ADMIN_USER GF_SECURITY_ADMIN_PASSWORD GF_SERVER_ROOT_URL 2>/dev/null || true
%{ endfor ~}

echo ""
echo "==> All stacks deployed successfully"
