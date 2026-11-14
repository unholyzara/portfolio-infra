#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_DIR}/orchestration/docker-compose.local.yml"
API_ENV_FILE="${PROJECT_DIR}/orchestration/services/api/local.env"

ADMIN_EMAIL="admin@admin.it"
ADMIN_PASS="admin"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker non e' installato o non e' disponibile nel PATH." >&2
    exit 1
fi

cd "${PROJECT_DIR}"

if [[ -z "${API_DB_PASSWORD:-}" ]]; then
    API_DB_PASSWORD="$(sed -nE 's/^DB_PASSWORD[[:space:]]*=[[:space:]]*(.*)$/\1/p' "${API_ENV_FILE}" | tail -n 1)"
    export API_DB_PASSWORD
fi

if [[ -z "${API_DB_PASSWORD}" ]]; then
    echo "API_DB_PASSWORD non e' definita e non e' stato possibile ricavarla da ${API_ENV_FILE}." >&2
    exit 1
fi

API_DB_USER="$(sed -nE 's/^DB_USER[[:space:]]*=[[:space:]]*(.*)$/\1/p' "${API_ENV_FILE}" | tr -d ' ' | tail -n 1)"
API_DB_USER="${API_DB_USER:-api_user}"

API_DB_NAME="$(sed -nE 's/^DB_NAME[[:space:]]*=[[:space:]]*(.*)$/\1/p' "${API_ENV_FILE}" | tr -d ' ' | tail -n 1)"
API_DB_NAME="${API_DB_NAME:-api_db}"

echo "Arresto l'istanza Docker Compose locale esistente..."
docker compose -f "${COMPOSE_FILE}" down --volumes --remove-orphans

echo "Preparo il database locale..."
docker compose -f "${COMPOSE_FILE}" build api
docker compose -f "${COMPOSE_FILE}" up -d postgres

echo "Attendo che Postgres sia pronto..."
until docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${API_DB_USER}" -d "${API_DB_NAME}" -c "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done

echo "Applico le migrazioni e creo l'amministratore..."
docker compose -f "${COMPOSE_FILE}" run --rm -T \
    -e "DJANGO_SUPERUSER_EMAIL=${ADMIN_EMAIL}" \
    -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
    api python manage.py createsuperuser --noinput

echo "Avvio una nuova istanza locale..."
exec docker compose -f "${COMPOSE_FILE}" up