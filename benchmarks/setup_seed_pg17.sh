#!/usr/bin/env bash
# Build a fresh seed-data benchmark DB on the currently selected PostgreSQL.
# This writes only to a NEW database and a NEW results folder (seed_pg17).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DB="${1:-spotify_cp4_seed17}"

if ! command -v psql >/dev/null 2>&1 || ! command -v createdb >/dev/null 2>&1; then
  echo "ERROR: psql and createdb must be available in PATH." >&2; exit 1
fi
if [[ ! -d seed_data ]]; then
  echo "ERROR: seed_data/ is missing. Extract the supplied seed_data.zip into the repo root first." >&2; exit 1
fi
if psql -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '$DB'" | grep -q 1; then
  echo "ERROR: database '$DB' already exists. Refusing to overwrite it." >&2; exit 1
fi
if [[ -d benchmarks/results/seed_pg17 ]] && find benchmarks/results/seed_pg17 -type f -print -quit | grep -q .; then
  echo "ERROR: benchmarks/results/seed_pg17 already contains files. Move it aside before rerunning." >&2; exit 1
fi

SERVER_VERSION_NUM="$(psql -d postgres -Atqc "SHOW server_version_num")"
SERVER_MAJOR="$((SERVER_VERSION_NUM / 10000))"
if [[ "$SERVER_MAJOR" -ne 17 ]]; then
  echo "ERROR: expected PostgreSQL 17 server, got $(psql -d postgres -Atqc "SELECT version()")" >&2; exit 1
fi
createdb "$DB"
psql -d "$DB" -v ON_ERROR_STOP=1 -c "ALTER DATABASE \"$DB\" SET timezone TO 'Asia/Kolkata';"
psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/01_schema.sql
psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/02_load_data.sql
psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/05_indexes.sql
psql -d "$DB" -v ON_ERROR_STOP=1 -c "ANALYZE;"

echo "Seed database '$DB' is ready. PostgreSQL version:"
psql -d "$DB" -Atqc "SELECT version();"
echo "Next: ./benchmarks/run_benchmark.sh '$DB' seed_pg17 3 sql/06_optimized_queries.sql"
