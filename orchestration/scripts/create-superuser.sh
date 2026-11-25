#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$COMPOSE_DIR"

compose_args=(-f "$COMPOSE_DIR/docker-compose.yml")
for file in "$ROOT_DIR"/services/*/compose.yml; do
    [[ -f "$file" ]] || continue
    compose_args+=(-f "$file")
done

read -rp "Username: " ADMIN_USER
read -rsp "Password: " ADMIN_PASS
echo
read -rp "Email (opzionale): " ADMIN_EMAIL

if [[ -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
    echo "Username e password sono obbligatori." >&2
    exit 1
fi

docker compose "${compose_args[@]}" run --rm -T \
    -e "DJANGO_SUPERUSER_USERNAME=${ADMIN_USER}" \
    -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
    -e "DJANGO_SUPERUSER_EMAIL=${ADMIN_EMAIL}" \
    api python manage.py createsuperuser --noinput
