#!/bin/bash
set -euo pipefail

APP_DIR=/home/deploy/app
COMPOSE_DIR=$APP_DIR/orchestration

dnf update -y
dnf install -y docker git jq cronie

systemctl enable docker
systemctl start docker
systemctl enable --now crond

DOCKER_COMPOSE_VERSION="2.27.0"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fSL "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

useradd -m -s /bin/bash deploy
usermod -aG docker deploy

id ssm-user &>/dev/null || useradd -m -s /bin/bash ssm-user
usermod -aG docker ssm-user
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ssm-agent-users
chmod 440 /etc/sudoers.d/ssm-agent-users

mkdir -p $APP_DIR
cd $APP_DIR

git clone https://github.com/${github_org}/${github_repository}.git .
chown -R deploy:deploy $APP_DIR

get_tag() {
  aws ssm get-parameter \
    --region ${aws_region} \
    --name "/${project_name}/${environment}/deploy/$1" \
    --query Parameter.Value \
    --output text || echo "main-latest"
}

cat > $COMPOSE_DIR/.env << ENVFILE
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
  --name /${project_name}/${environment}/postgres \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq -r '.root_password')
echo "POSTGRES_ROOT_PASSWORD=$POSTGRES_ROOT_PASSWORD" >> $COMPOSE_DIR/.env

GRAFANA_ADMIN_PASSWORD=$(aws ssm get-parameter \
  --region ${aws_region} \
  --name /${project_name}/${environment}/grafana \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq -r '.admin_password')
echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" >> $COMPOSE_DIR/.env

chmod 600 $COMPOSE_DIR/.env
chown deploy:deploy $COMPOSE_DIR/.env

sudo -u deploy bash -c "aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}"

cat > /etc/cron.d/ecr-login << CRONFILE
0 */6 * * * deploy aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}
CRONFILE

cd $COMPOSE_DIR
sudo -u deploy docker compose pull

%{ if environment == "prd" ~}
sudo -u deploy docker compose --profile monitoring up -d
%{ else ~}
sudo -u deploy docker compose up -d
%{ endif ~}

LAZYDOCKER_VERSION="0.24.1"
LAZYDOCKER_BASE="https://github.com/jesseduffield/lazydocker/releases/download/v$${LAZYDOCKER_VERSION}"
LAZYDOCKER_ARCHIVE="lazydocker_$${LAZYDOCKER_VERSION}_Linux_arm64.tar.gz"
curl -fsSL -o "/tmp/$${LAZYDOCKER_ARCHIVE}" "$${LAZYDOCKER_BASE}/$${LAZYDOCKER_ARCHIVE}"
curl -fsSL -o /tmp/lazydocker_checksums.txt "$${LAZYDOCKER_BASE}/checksums.txt"
(cd /tmp && grep "$${LAZYDOCKER_ARCHIVE}" lazydocker_checksums.txt | sha256sum -c -)
tar -xzf "/tmp/$${LAZYDOCKER_ARCHIVE}" -C /usr/local/bin lazydocker
chmod 0755 /usr/local/bin/lazydocker
rm -f "/tmp/$${LAZYDOCKER_ARCHIVE}" /tmp/lazydocker_checksums.txt