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

cat > /home/deploy/app/.env << ENVFILE
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
FRONTEND_TAG=main-latest
ADMIN_TAG=main-latest
ACCADEMIC_TAG=main-latest
WORK_TAG=main-latest
PERSONA_TAG=main-latest
PROJECTS_TAG=main-latest
CV_TAG=main-latest
ENVFILE

POSTGRES_ROOT_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id /portfolio/${environment}/postgres \
  --query SecretString \
  --output text | jq -r '.root_password')
echo "POSTGRES_ROOT_PASSWORD=$POSTGRES_ROOT_PASSWORD" >> /home/deploy/app/.env

%{ if environment == "prd" ~}
GRAFANA_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id /portfolio/${environment}/grafana \
  --query SecretString \
  --output text | jq -r '.admin_password')
echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" >> /home/deploy/app/.env
%{ endif ~}

chmod 600 /home/deploy/app/.env
chown deploy:deploy /home/deploy/app/.env

aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

cat > /etc/cron.d/ecr-login << CRONFILE
0 */6 * * * deploy aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}
CRONFILE

cd /home/deploy/app
sudo -u deploy docker compose pull

%{ if environment == "prd" ~}
sudo -u deploy docker compose --profile monitoring up -d
%{ else ~}
sudo -u deploy docker compose up -d
%{ endif ~}
