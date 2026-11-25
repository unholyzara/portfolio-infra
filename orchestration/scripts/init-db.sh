#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${API_DB_USER:?API_DB_USER is required}"
: "${API_DB_PASSWORD:?API_DB_PASSWORD is required}"
: "${BACKUP_DB_USER:?BACKUP_DB_USER is required}"
: "${BACKUP_DB_PASSWORD:?BACKUP_DB_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -v db_name="$POSTGRES_DB" \
    -v root_user="$POSTGRES_USER" \
    -v root_pwd="$POSTGRES_PASSWORD" \
    -v api_user="$API_DB_USER" \
    -v api_pwd="$API_DB_PASSWORD" \
    -v backup_user="$BACKUP_DB_USER" \
    -v backup_pwd="$BACKUP_DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE %I WITH LOGIN SUPERUSER PASSWORD %L', :'root_user', :'root_pwd')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'root_user')
\gexec
SELECT format('ALTER ROLE %I WITH LOGIN SUPERUSER PASSWORD %L', :'root_user', :'root_pwd')
\gexec

SELECT format('CREATE ROLE %I WITH LOGIN PASSWORD %L', :'api_user', :'api_pwd')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'api_user')
\gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'api_user', :'api_pwd')
\gexec

SELECT format('CREATE ROLE %I WITH LOGIN PASSWORD %L', :'backup_user', :'backup_pwd')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'backup_user')
\gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'backup_user', :'backup_pwd')
\gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', :'api_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'db_name')
\gexec
SELECT format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'api_user')
\gexec
SQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    -v api_user="$API_DB_USER" \
    -v backup_user="$BACKUP_DB_USER" <<'SQL'
SELECT format('GRANT CONNECT, CREATE, TEMPORARY ON DATABASE %I TO %I', current_database(), :'api_user')
\gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), :'backup_user')
\gexec

SELECT format('GRANT USAGE, CREATE ON SCHEMA public TO %I', :'api_user')
\gexec
SELECT format('GRANT USAGE ON SCHEMA public TO %I', :'backup_user')
\gexec
SELECT format('GRANT SELECT ON ALL TABLES IN SCHEMA public TO %I', :'backup_user')
\gexec
SELECT format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT SELECT ON TABLES TO %I', :'api_user', :'backup_user')
\gexec
SQL
