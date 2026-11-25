#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN:?}"
: "${ENVIRONMENT:?}"
: "${CERT_BUCKET:?}"
: "${LETSENCRYPT_EMAIL:?}"

AWS_REGION="${AWS_REGION:-eu-south-1}"
CERTBOT_IMAGE="${CERTBOT_IMAGE:-certbot/dns-route53:v3.0.1}"
CERT_NAME="portfolio"
LE_DIR="/opt/portfolio/letsencrypt"
S3_KEY="certs/${ENVIRONMENT}/letsencrypt.tar.gz"
RENEW_BEFORE_DAYS=30

export AWS_DEFAULT_REGION="${AWS_REGION}"

TMP_TAR="$(mktemp)"
trap 'rm -f "${TMP_TAR}"' EXIT

log() {
  echo "[certs] $*"
}

restore() {
  local err
  if ! err="$(aws s3api head-object --bucket "${CERT_BUCKET}" --key "${S3_KEY}" 2>&1)"; then
    if grep -qE "404|Not Found" <<<"${err}"; then
      return 1
    fi
    echo "${err}" >&2
    exit 1
  fi
  aws s3 cp "s3://${CERT_BUCKET}/${S3_KEY}" "${TMP_TAR}" --only-show-errors || exit 1
  tar xzf "${TMP_TAR}" -C "${LE_DIR}" || exit 1
}

backup() {
  tar czf "${TMP_TAR}" -C "${LE_DIR}" . || exit 1
  aws s3 cp "${TMP_TAR}" "s3://${CERT_BUCKET}/${S3_KEY}" --only-show-errors || exit 1
}

cert_valid() {
  local pem="${LE_DIR}/live/${CERT_NAME}/fullchain.pem"
  [[ -f "${pem}" ]] || return 1
  openssl x509 -in "${pem}" -noout -checkend $((RENEW_BEFORE_DAYS * 86400)) >/dev/null
}

issue() {
  docker run --rm --network host \
    -v "${LE_DIR}:/etc/letsencrypt" \
    -e AWS_DEFAULT_REGION="${AWS_REGION}" \
    "${CERTBOT_IMAGE}" certonly \
    --dns-route53 \
    --non-interactive \
    --agree-tos \
    --email "${LETSENCRYPT_EMAIL}" \
    --cert-name "${CERT_NAME}" \
    -d "${DOMAIN}" \
    -d "*.${DOMAIN}"
}

reload_nginx() {
  local id
  id="$(docker ps -q --filter "label=com.docker.compose.service=nginx")"
  if [[ -n "${id}" ]]; then
    docker exec "${id}" nginx -s reload
  fi
  return 0
}

ensure() {
  mkdir -p "${LE_DIR}"
  restore || true
  if cert_valid; then
    log "certificate valid for more than ${RENEW_BEFORE_DAYS} days, nothing to do"
    return 0
  fi
  log "issuing certificate for ${DOMAIN} and *.${DOMAIN}"
  issue
  backup
  log "certificate stored in s3://${CERT_BUCKET}/${S3_KEY}"
}

install_timer() {
  local script
  script="$(readlink -f "$0")"

  install -d -m 700 /etc/portfolio
  cat > /etc/portfolio/certs.env <<EOF
DOMAIN=${DOMAIN}
ENVIRONMENT=${ENVIRONMENT}
CERT_BUCKET=${CERT_BUCKET}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
AWS_REGION=${AWS_REGION}
EOF
  chmod 600 /etc/portfolio/certs.env

  cat > /etc/systemd/system/portfolio-certs.service <<EOF
[Unit]
Description=Renew portfolio TLS certificate
After=docker.service network-online.target

[Service]
Type=oneshot
EnvironmentFile=/etc/portfolio/certs.env
ExecStart=${script} renew
EOF

  cat > /etc/systemd/system/portfolio-certs.timer <<EOF
[Unit]
Description=Weekly portfolio TLS certificate check

[Timer]
OnCalendar=weekly
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now portfolio-certs.timer
}

case "${1:-ensure}" in
  ensure)
    ensure
    ;;
  renew)
    ensure
    reload_nginx
    ;;
  install-timer)
    install_timer
    ;;
  *)
    echo "usage: $0 {ensure|renew|install-timer}" >&2
    exit 2
    ;;
esac