#!/usr/bin/env bash
set -euo pipefail

INTERVAL="${BACKUP_POLL_SECONDS:-900}"
DUMP=/tmp/current.sql
PREV=""
LAST=""

while true; do
  if pg_dump --no-owner --exclude-table-data=django_session -f "$DUMP"; then
    CURRENT=$(sha256sum "$DUMP" | cut -d' ' -f1)
    if [ "$CURRENT" = "$PREV" ] && [ "$CURRENT" != "$LAST" ]; then
      upload.sh "$DUMP" "$BACKUP_PREFIX"
      LAST="$CURRENT"
    fi
    PREV="$CURRENT"
  fi
  sleep "$INTERVAL"
done