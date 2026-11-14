#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/db_backups"
FILE="$DIR/api_db-$(date -u +%Y%m%dT%H%M%SZ).json"
EXCLUDE="${EXCLUDE:-^(django_|auth_|user_|site_settings_)}"

mkdir -p "$DIR"
trap 'rm -f "$FILE.tmp"' EXIT

run_psql() {
  docker compose -f docker-compose.local.yml exec -T postgres \
    psql -X -At -v ON_ERROR_STOP=1 -v exclude="$EXCLUDE" -U api_user -d api_db
}

QUERY="$(run_psql <<'SQL'
WITH RECURSIVE tbl AS (
  SELECT c.oid, c.relname
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relname !~ :'exclude'
),
fk AS (
  SELECT conrelid AS child, confrelid AS parent
  FROM pg_constraint
  WHERE contype = 'f' AND conrelid <> confrelid
),
depth AS (
  SELECT oid, 0 AS d FROM tbl
  UNION ALL
  SELECT fk.child, depth.d + 1
  FROM depth
  JOIN fk ON fk.parent = depth.oid
  JOIN tbl ON tbl.oid = fk.child
  WHERE depth.d < 20
),
ordered AS (
  SELECT t.relname, row_number() OVER (ORDER BY max(depth.d), t.relname) AS pos
  FROM tbl t
  JOIN depth ON depth.oid = t.oid
  GROUP BY t.relname
)
SELECT 'SELECT json_object_agg(k, v ORDER BY o) FROM (' ||
  string_agg(
    format(
      'SELECT %s AS o, %L AS k, COALESCE((SELECT json_agg(t ORDER BY t::text) FROM public.%I t), ''[]''::json) AS v',
      pos, relname, relname
    ),
    ' UNION ALL ' ORDER BY pos
  ) || ') s;'
FROM ordered;
SQL
)"

[ -n "$QUERY" ] || { echo "No tables found" >&2; exit 1; }

printf '%s\n' "$QUERY" | run_psql | python3 -m json.tool --no-ensure-ascii --indent 2 > "$FILE.tmp"

mv "$FILE.tmp" "$FILE"
ln -sf "$(basename "$FILE")" "$DIR/latest.json"