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
cat > /root/${stack}/docker-compose.yml <<'EOF_COMPOSE'
${compose_contents[stack].content}
EOF_COMPOSE
docker compose -f /root/${stack}/docker-compose.yml pull
docker compose -f /root/${stack}/docker-compose.yml up -d
%{ endfor ~}

echo ""
echo "==> All stacks deployed successfully"
