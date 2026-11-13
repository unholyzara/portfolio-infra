#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git jq cronie

systemctl enable docker
systemctl start docker
systemctl enable --now crond

DOCKER_COMPOSE_VERSION="2.27.0"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

useradd -m -s /bin/bash deploy
usermod -aG docker deploy

id ssm-user &>/dev/null || useradd -m -s /bin/bash ssm-user
usermod -aG docker ssm-user
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ssm-agent-users
chmod 440 /etc/sudoers.d/ssm-agent-users

mkdir -p /home/deploy/app
cd /home/deploy/app

git clone https://github.com/${github_org}/portfolio-infra.git .
chown -R deploy:deploy /home/deploy/app

cat > /home/deploy/app/.env << ENVFILE
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
ECR_REGISTRY=${ecr_registry}
FRONTEND_TAG=main-latest
ADMIN_TAG=main-latest
API_TAG=main-latest
CV_TAG=main-latest
ENVFILE

POSTGRES_ROOT_PASSWORD=$(aws ssm get-parameter \
  --region ${aws_region} \
  --name /portfolio/${environment}/postgres \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq -r '.root_password')
echo "POSTGRES_ROOT_PASSWORD=$POSTGRES_ROOT_PASSWORD" >> /home/deploy/app/.env

%{ if environment == "prd" ~}
GRAFANA_ADMIN_PASSWORD=$(aws ssm get-parameter \
  --region ${aws_region} \
  --name /portfolio/${environment}/grafana \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq -r '.admin_password')
echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" >> /home/deploy/app/.env
%{ endif ~}

chmod 600 /home/deploy/app/.env
chown deploy:deploy /home/deploy/app/.env

sudo -u deploy bash -c "aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}"

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