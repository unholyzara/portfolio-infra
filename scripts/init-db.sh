#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -v pwd="$API_DB_PASSWORD" <<'SQL'
CREATE ROLE api_user LOGIN PASSWORD :'pwd';
CREATE DATABASE api_db OWNER api_user;
SQL