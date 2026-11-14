#!/usr/bin/env bash
set -euo pipefail

read -rp "Username: " ADMIN_USER
read -rsp "Password: " ADMIN_PASS
echo
read -rp "Email (opzionale): " ADMIN_EMAIL

if [[ -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
    echo "Username e password sono obbligatori." >&2
    exit 1
fi

docker compose run --rm -T \
    -e "DJANGO_SUPERUSER_USERNAME=${ADMIN_USER}" \
    -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
    -e "DJANGO_SUPERUSER_EMAIL=admin@localhost" \
    api python manage.py createsuperuser --noinput