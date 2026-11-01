#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIR="$(cd "$SCRIPT_DIR/.." && pwd)/db_backups"
HELPER="$SCRIPT_DIR/helpers/import_backup_local.py"
TRUNCATE=0
FILE=""

for arg in "$@"; do
  case "$arg" in
    --truncate) TRUNCATE=1 ;;
    *) FILE="$arg" ;;
  esac
done

FILE="${FILE:-$DIR/latest.json}"
[ -f "$FILE" ] || { echo "File not found: $FILE" >&2; exit 1; }
[ -f "$HELPER" ] || { echo "Helper not found: $HELPER" >&2; exit 1; }

python3 "$HELPER" "$FILE" "$TRUNCATE" | docker compose -f docker-compose.local.yml exec -T postgres psql -1 -X -q -v ON_ERROR_STOP=1 -U api_user -d api_db

echo "Import completed: $FILE"