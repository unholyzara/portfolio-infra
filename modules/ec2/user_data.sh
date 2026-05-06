#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git jq

systemctl enable docker
systemctl start docker

DOCKER_COMPOSE_VERSION="2.27.0"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

useradd -m -s /bin/bash deploy
usermod -aG docker deploy

mkdir -p /home/deploy/app
cd /home/deploy/app

git clone https://github.com/${github_org}/portfolio-orchestrator.git .
chown -R deploy:deploy /home/deploy/app

cat > /home/deploy/app/.env << EOF
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
FRONTEND_TAG=main-latest
ADMIN_TAG=main-latest
SERVICE_A_TAG=main-latest
SERVICE_B_TAG=main-latest
EOF

chmod 600 /home/deploy/app/.env
chown deploy:deploy /home/deploy/app/.env

aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

cat > /etc/cron.d/ecr-login << 'CRON'
0 */6 * * * deploy aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}
CRON

cd /home/deploy/app
sudo -u deploy docker compose pull

aws ssm get-parameter \
  --name "portfolio-${environment}-root-password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text | sed 's/^/POSTGRES_ROOT_PASSWORD=/' >> /home/deploy/app/.env

sudo -u deploy docker compose up -d
