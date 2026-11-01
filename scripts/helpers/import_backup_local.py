import json
import re
import secrets
import sys

path, truncate = sys.argv[1], sys.argv[2] == "1"

with open(path, encoding="utf-8") as f:
    data = json.load(f)

if not data:
    sys.exit("The JSON file contains no tables")

name_re = re.compile(r"^[a-z_][a-z0-9_]*$")
for name in data:
    if not name_re.match(name):
        sys.exit(f"Invalid table name: {name}")

out = []

if truncate:
    tables = ", ".join(f'public."{name}"' for name in data)
    out.append(f"TRUNCATE {tables};")

for name, rows in data.items():
    payload = json.dumps(rows, ensure_ascii=False)
    tag = "j" + secrets.token_hex(4)
    while f"${tag}$" in payload:
        tag = "j" + secrets.token_hex(4)
    out.append(
        f'INSERT INTO public."{name}" SELECT * FROM json_populate_recordset('
        f'null::public."{name}", ${tag}${payload}${tag}$::json);'
    )

names = ", ".join(f"'{name}'" for name in data)
out.append(
    "DO $do$ DECLARE r record; BEGIN "
    "FOR r IN SELECT t.tbl, a.attname, "
    "pg_get_serial_sequence('public.' || quote_ident(t.tbl), a.attname) AS seq "
    f"FROM unnest(ARRAY[{names}]) AS t(tbl) "
    "JOIN pg_attribute a ON a.attrelid = ('public.' || quote_ident(t.tbl))::regclass "
    "AND a.attnum > 0 AND NOT a.attisdropped "
    "WHERE pg_get_serial_sequence('public.' || quote_ident(t.tbl), a.attname) IS NOT NULL "
    "LOOP EXECUTE format("
    "'SELECT setval(%L, COALESCE(MAX(%I), 1), MAX(%I) IS NOT NULL) FROM public.%I', "
    "r.seq, r.attname, r.attname, r.tbl); "
    "END LOOP; END $do$;"
)

print("\n".join(out))