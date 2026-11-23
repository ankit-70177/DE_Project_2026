#!/usr/bin/env bash
# Build a fresh large-data CP4 DB: load -> partition -> CP3 indexes -> ANALYZE.
# This script refuses to overwrite an existing database or large benchmark.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DB="${1:-spotify_cp4_large}"

if ! command -v psql >/dev/null 2>&1 || ! command -v createdb >/dev/null 2>&1; then
  echo "ERROR: psql and createdb must be available in PATH." >&2; exit 1
fi
if [[ ! -d large_data ]]; then
  if [[ -f large_data.zip ]]; then
    echo "Extracting large_data.zip..."
    unzip -q large_data.zip
  else
    echo "ERROR: large_data/ and large_data.zip are both missing. Place the supplied large_data.zip in the repo root." >&2; exit 1
  fi
fi
if psql -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '$DB'" | grep -q 1; then
  echo "ERROR: database '$DB' already exists. Refusing to overwrite it." >&2; exit 1
fi
if [[ -d benchmarks/results/large ]] && find benchmarks/results/large -type f -print -quit | grep -q .; then
  echo "ERROR: benchmarks/results/large already contains files. Move it aside before rerunning." >&2; exit 1
fi

SERVER_VERSION_NUM="$(psql -d postgres -Atqc "SHOW server_version_num")"
SERVER_MAJOR="$((SERVER_VERSION_NUM / 10000))"
if [[ "$SERVER_MAJOR" -ne 17 ]]; then
  echo "ERROR: expected PostgreSQL 17 server, got $(psql -d postgres -Atqc "SELECT version()")" >&2; exit 1
fi
createdb "$DB"
psql -d "$DB" -v ON_ERROR_STOP=1 -c "ALTER DATABASE \"$DB\" SET timezone TO 'Asia/Kolkata';"
psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/01_schema.sql
# Keep the committed loader unchanged; only redirect its CSV folder for this run.
sed 's#seed_data/#large_data/#g' sql/02_load_data.sql | psql -d "$DB" -v ON_ERROR_STOP=1

# Assert all ten supplied CSV row counts before partitioning.
psql -d "$DB" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF (SELECT count(*) FROM spotify.artists) <> 60000 THEN RAISE EXCEPTION 'artists row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.albums) <> 240000 THEN RAISE EXCEPTION 'albums row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.tracks) <> 1360381 THEN RAISE EXCEPTION 'tracks row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.track_artists) <> 1554720 THEN RAISE EXCEPTION 'track_artists row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.users) <> 600000 THEN RAISE EXCEPTION 'users row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.playlists) <> 200000 THEN RAISE EXCEPTION 'playlists row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.playlist_tracks) <> 2400008 THEN RAISE EXCEPTION 'playlist_tracks row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.streams) <> 5000000 THEN RAISE EXCEPTION 'streams row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.liked_tracks) <> 1171457 THEN RAISE EXCEPTION 'liked_tracks row count mismatch'; END IF;
  IF (SELECT count(*) FROM spotify.artist_follows) <> 1399801 THEN RAISE EXCEPTION 'artist_follows row count mismatch'; END IF;
END
$$;
SQL

psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/08_partitioning.sql
psql -d "$DB" -v ON_ERROR_STOP=1 -f sql/05_indexes.sql
psql -d "$DB" -v ON_ERROR_STOP=1 -c "ANALYZE;"

echo "Large database '$DB' is ready. PostgreSQL version:"
psql -d "$DB" -Atqc "SELECT version();"
echo "Partition tree:"
psql -d "$DB" -c "SELECT relid::regclass AS partition FROM pg_partition_tree('spotify.streams') ORDER BY 1;"
echo "Row count:"
psql -d "$DB" -c "SELECT count(*) AS streams FROM spotify.streams;"
echo "Next: ./benchmarks/run_benchmark.sh '$DB' large 3 sql/06_optimized_queries.sql"
