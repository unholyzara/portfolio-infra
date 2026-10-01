#!/usr/bin/env bash
set -euo pipefail

SERVICES=("postgres" "api")

if [[ $# -gt 0 ]]; then
  SERVICES=("$@")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export ENVIRONMENT="local"
export COMPOSE_FILE="docker-compose.yml:docker-compose.local.yml"
export POSTGRES_ROOT_PASSWORD="${POSTGRES_ROOT_PASSWORD:-postgres}"
export API_DB_PASSWORD="${API_DB_PASSWORD:-api}"
export ECR_REGISTRY="${ECR_REGISTRY:-local}"
for TAG_VAR in FRONTEND_TAG ADMIN_TAG API_TAG CV_TAG; do
  export "${TAG_VAR}=${!TAG_VAR:-local}"
done

has_service() {
  local target="$1"
  local service
  for service in "${SERVICES[@]}"; do
    if [[ "$service" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

if has_service postgres; then
  echo "Avvio di PostgreSQL..."
  docker compose up -d --wait --wait-timeout 90 postgres
fi

echo "Build e avvio dei servizi: ${SERVICES[*]}"
docker compose up -d --build "${SERVICES[@]}"

if has_service api; then
  echo "Applicazione migrazioni per api..."
  docker compose run --rm -T api python manage.py migrate --noinput

  EXIT_CODE=0
  docker compose run --rm -T api python manage.py shell -c \
    "import sys; from django.contrib.auth import get_user_model; sys.exit(0 if get_user_model().objects.filter(is_superuser=True).exists() else 3)" \
    || EXIT_CODE=$?

  case "$EXIT_CODE" in
    0)
      echo "Superuser gia' presente."
      ;;
    3)
      echo "Nessun superuser trovato, ne creo uno."
      read -rp "Username: " ADMIN_USER
      read -rsp "Password: " ADMIN_PASS
      echo
      read -rsp "Conferma password: " ADMIN_PASS_CONFIRM
      echo
      read -rp "Email (opzionale): " ADMIN_EMAIL

      if [[ -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
        echo "Username e password sono obbligatori." >&2
        exit 1
      fi
      if [[ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]]; then
        echo "Le password non coincidono." >&2
        exit 1
      fi

      docker compose run --rm -T \
        -e "DJANGO_SUPERUSER_USERNAME=${ADMIN_USER}" \
        -e "DJANGO_SUPERUSER_PASSWORD=${ADMIN_PASS}" \
        -e "DJANGO_SUPERUSER_EMAIL=${ADMIN_EMAIL:-admin@localhost}" \
        api python manage.py createsuperuser --noinput
      echo "Superuser '${ADMIN_USER}' creato."
      ;;
    *)
      echo "Verifica del superuser fallita (exit code ${EXIT_CODE})." >&2
      exit 1
      ;;
  esac
fi

echo "Servizi attivi: ${SERVICES[*]}"