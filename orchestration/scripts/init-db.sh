#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -v pwd="$API_DB_PASSWORD" <<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'api_user') THEN
        CREATE ROLE api_user LOGIN;
    END IF;
END
$$;

ALTER ROLE api_user WITH LOGIN PASSWORD :'pwd';
SELECT 'CREATE DATABASE api_db OWNER api_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'api_db')
\gexec
SQL
