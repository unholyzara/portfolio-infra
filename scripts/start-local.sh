#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.local.yml"
API_ENV_FILE="${PROJECT_DIR}/services/api/local.env"
DUMP_FILE="${DUMP_FILE:-${PROJECT_DIR}/dump.sql}"

if [[ -z "${ADMIN_USER:-}" ]]; then
    read -rp "Username amministratore: " ADMIN_USER
fi

if [[ -z "${ADMIN_PASS:-}" ]]; then
    read -rsp "Password amministratore: " ADMIN_PASS
    echo
fi

ADMIN_EMAIL="${ADMIN_EMAIL:-admin@localhost}"

if [[ -z "${ADMIN_USER}" || -z "${ADMIN_PASS}" ]]; then
    echo "Username e password dell'amministratore sono obbligatori." >&2
    exit 1
fi

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

if [[ -f "${DUMP_FILE}" ]]; then
    echo "Trovato dump del database in ${DUMP_FILE}, avvio l'importazione..."
    docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${API_DB_USER}" -d "${API_DB_NAME}" < "${DUMP_FILE}" >/dev/null
    echo "Dump del database importato con successo."

    echo "Verifico eventuali nuove migrazioni..."
    docker compose -f "${COMPOSE_FILE}" run --rm -T api python manage.py migrate --noinput

    echo "Assicuro la presenza dell'amministratore..."
    docker compose -f "${COMPOSE_FILE}" run --rm -T \
        -e "DJANGO_SUPERUSER_USERNAME=${ADMIN_USER}" \
        -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
        -e "DJANGO_SUPERUSER_EMAIL=${ADMIN_EMAIL}" \
        api python manage.py shell -c "
import os
from django.contrib.auth import get_user_model
User = get_user_model()
username = os.environ.get('DJANGO_SUPERUSER_USERNAME')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@localhost')
if username and password:
    user, created = User.objects.get_or_create(username=username, defaults={'email': email, 'is_staff': True, 'is_superuser': True})
    user.set_password(password)
    user.is_staff = True
    user.is_superuser = True
    user.email = email
    user.save()
"
else
    echo "Applico le migrazioni e creo l'amministratore..."
    docker compose -f "${COMPOSE_FILE}" run --rm -T \
        -e "DJANGO_SUPERUSER_USERNAME=${ADMIN_USER}" \
        -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
        -e "DJANGO_SUPERUSER_EMAIL=${ADMIN_EMAIL}" \
        api python manage.py createsuperuser --noinput
fi

echo "Avvio una nuova istanza locale..."
exec docker compose -f "${COMPOSE_FILE}" up

