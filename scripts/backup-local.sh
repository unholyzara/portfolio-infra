#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/db_backups"
FILE="$DIR/api_db-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"

mkdir -p "$DIR"
trap 'rm -f "$FILE.tmp"' EXIT

docker compose -f docker-compose.local.yml exec -T postgres pg_dump -U api_user --no-owner --exclude-table-data=django_session api_db | gzip > "$FILE.tmp"
mv "$FILE.tmp" "$FILE"
ln -sf "$(basename "$FILE")" "$DIR/latest.sql.gz"