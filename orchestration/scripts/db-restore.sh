#!/usr/bin/env bash
set -euo pipefail

ORCHESTRATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$(dirname "${ORCHESTRATION_DIR}")/services"
ENV_FILE="${ORCHESTRATION_DIR}/.env"

usage() {
  echo "Usage: $0 --key <s3-key> [--regenerate-uuids] [--dry-run]" >&2
  exit 2
}

fail() {
  echo "[db-restore] $*" >&2
  exit 1
}

log() {
  echo "[db-restore] $*"
}

KEY=""
REGENERATE_UUIDS=0
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --key) KEY="${2:-}"; shift 2 ;;
    --regenerate-uuids) REGENERATE_UUIDS=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) usage ;;
  esac
done
[ -n "${KEY}" ] || usage
[[ "${KEY}" =~ ^[A-Za-z0-9._/-]+$ ]] || fail "Invalid key: ${KEY}"

env_value() {
  grep -m1 "^$1=" "${ENV_FILE}" | cut -d= -f2-
}

PROJECT_NAME="$(env_value PROJECT_NAME)"
ENVIRONMENT="$(env_value ENVIRONMENT)"
export AWS_DEFAULT_REGION="$(env_value AWS_REGION)"
BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-backup-s3"

COMPOSE=(docker compose -f "${ORCHESTRATION_DIR}/docker-compose.yml")
for file in "${SERVICES_DIR}"/*/compose.yml; do
  [ -f "${file}" ] && COMPOSE+=(-f "${file}")
done

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
DUMP_GZ="${WORK_DIR}/dump.sql.gz"
DUMP_SQL="${WORK_DIR}/dump.sql"
RESTORE_SQL="${WORK_DIR}/restore.sql"

psql_api() {
  "${COMPOSE[@]}" exec -T postgres sh -c \
    'psql -X -At -q -v ON_ERROR_STOP=1 -U "$API_DB_USER" -d "$POSTGRES_DB" "$@"' sh "$@"
}

print_counts() {
  psql_api <<SQL
SELECT t || ': ' || (xpath('/row/c/text()', query_to_xml(format('SELECT count(*) AS c FROM public.%I', t), false, true, '')))[1]::text
FROM unnest(ARRAY[${TABLE_ARRAY}]) AS t ORDER BY t;
SQL
}

log "Downloading s3://${BUCKET}/${KEY}"
aws s3 cp "s3://${BUCKET}/${KEY}" "${DUMP_GZ}" --only-show-errors
gunzip -t "${DUMP_GZ}"
gunzip -c "${DUMP_GZ}" > "${DUMP_SQL}"

if grep -q '^CREATE TABLE' "${DUMP_SQL}"; then
  fail "${KEY} is a full dump, only data-only dumps of selected tables are supported"
fi

TABLES="$(sed -nE 's/^COPY public\.([a-z_][a-z0-9_]*) .*/\1/p' "${DUMP_SQL}" | sort -u)"
[ -n "${TABLES}" ] || fail "${KEY} contains no table data"

TABLE_ARRAY="$(sed "s/.*/'&'/" <<<"${TABLES}" | paste -sd, -)"
TABLE_CSV="$(paste -sd, - <<<"${TABLES}")"
TRUNCATE_LIST="$(sed 's/.*/public."&"/' <<<"${TABLES}" | paste -sd, -)"

MISSING="$(psql_api <<SQL
SELECT t FROM unnest(ARRAY[${TABLE_ARRAY}]) AS t WHERE to_regclass('public.' || quote_ident(t)) IS NULL;
SQL
)"
[ -z "${MISSING}" ] || fail "Tables missing in the target database (run migrations first): ${MISSING//$'\n'/, }"

log "Tables in dump: ${TABLE_CSV}"
log "Current row counts in ${ENVIRONMENT}:"
print_counts

if [ "${DRY_RUN}" = "1" ]; then
  log "Dry run, nothing changed"
  exit 0
fi

{
  echo "SELECT set_config('restore.tables', '${TABLE_CSV}', true);"
  echo "SET CONSTRAINTS ALL DEFERRED;"
  echo "TRUNCATE ${TRUNCATE_LIST};"
  cat "${DUMP_SQL}"
  echo "SET search_path = public, pg_catalog;"
  if [ "${REGENERATE_UUIDS}" = "1" ]; then
    cat <<'SQL'
CREATE TEMP TABLE uuid_map (old uuid PRIMARY KEY, new uuid NOT NULL) ON COMMIT DROP;
DO $do$
DECLARE
  r record;
  tables oid[];
BEGIN
  SELECT array_agg(c.oid) INTO tables
  FROM pg_class c
  WHERE c.relnamespace = 'public'::regnamespace
    AND c.relname = ANY(string_to_array(current_setting('restore.tables'), ','));

  FOR r IN
    SELECT c.oid::regclass AS tbl, a.attname AS col
    FROM pg_class c
    JOIN pg_index i ON i.indrelid = c.oid AND i.indisprimary AND i.indnkeyatts = 1
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = i.indkey[0]
    WHERE c.oid = ANY(tables) AND a.atttypid = 'uuid'::regtype
  LOOP
    EXECUTE format('INSERT INTO uuid_map SELECT %I, gen_random_uuid() FROM %s', r.col, r.tbl);
  END LOOP;

  FOR r IN
    SELECT k.conrelid::regclass AS tbl, a.attname AS col
    FROM pg_constraint k
    JOIN pg_attribute a ON a.attrelid = k.conrelid AND a.attnum = k.conkey[1]
    WHERE k.contype = 'f'
      AND array_length(k.conkey, 1) = 1
      AND k.conrelid = ANY(tables)
      AND k.confrelid = ANY(tables)
      AND a.atttypid = 'uuid'::regtype
  LOOP
    EXECUTE format('UPDATE %s t SET %I = m.new FROM uuid_map m WHERE t.%I = m.old', r.tbl, r.col, r.col);
  END LOOP;

  FOR r IN
    SELECT c.oid::regclass AS tbl, a.attname AS col
    FROM pg_class c
    JOIN pg_index i ON i.indrelid = c.oid AND i.indisprimary AND i.indnkeyatts = 1
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = i.indkey[0]
    WHERE c.oid = ANY(tables) AND a.atttypid = 'uuid'::regtype
  LOOP
    EXECUTE format('UPDATE %s t SET %I = m.new FROM uuid_map m WHERE t.%I = m.old', r.tbl, r.col, r.col);
  END LOOP;
END
$do$;
SQL
  fi
  cat <<'SQL'
DO $do$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT t.tbl, a.attname,
           pg_get_serial_sequence('public.' || quote_ident(t.tbl), a.attname) AS seq
    FROM unnest(string_to_array(current_setting('restore.tables'), ',')) AS t(tbl)
    JOIN pg_attribute a ON a.attrelid = ('public.' || quote_ident(t.tbl))::regclass
      AND a.attnum > 0 AND NOT a.attisdropped
    WHERE pg_get_serial_sequence('public.' || quote_ident(t.tbl), a.attname) IS NOT NULL
  LOOP
    EXECUTE format(
      'SELECT setval(%L, COALESCE(MAX(%I), 1), MAX(%I) IS NOT NULL) FROM public.%I',
      r.seq, r.attname, r.attname, r.tbl
    );
  END LOOP;
END
$do$;
SQL
} > "${RESTORE_SQL}"

if [ "${REGENERATE_UUIDS}" = "1" ]; then
  log "Restoring with regenerated UUIDs"
else
  log "Restoring with original UUIDs"
fi
psql_api --single-transaction -f - < "${RESTORE_SQL}" > /dev/null

log "Restore completed, row counts in ${ENVIRONMENT}:"
print_counts
