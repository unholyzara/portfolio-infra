#!/usr/bin/env bash
set -euo pipefail

FILE="$1"
PREFIX="$2"
KEY="$PREFIX/api_db-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"

gzip -c "$FILE" | aws s3 cp - "s3://$BACKUP_BUCKET/$KEY"
aws s3 cp "s3://$BACKUP_BUCKET/$KEY" "s3://$BACKUP_BUCKET/$PREFIX/latest.sql.gz"