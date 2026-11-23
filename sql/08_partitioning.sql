-- CP4: Convert the already-loaded 5M-row spotify.streams table into
-- monthly RANGE partitions on started_at (Asia/Kolkata calendar months).
--
-- REQUIRED ORDER:
--   1) Run sql/01_schema.sql
--   2) Load large_data with sql/02_load_data.sql (large_data path)
--   3) Run THIS file
--   4) Run sql/05_indexes.sql
--
-- This is a one-time migration for a fresh CP4 database. It is transactional:
-- any failure rolls back the rename, new table, partition creation and copy.
-- The old single-column PK cannot be retained on a RANGE-partitioned table:
-- PostgreSQL requires every partitioned UNIQUE/PRIMARY KEY to include
-- the partition key. The new key is (stream_id, started_at).

\set ON_ERROR_STOP on
SET search_path TO spotify;
SET TIME ZONE 'Asia/Kolkata';

BEGIN;
LOCK TABLE spotify.streams IN ACCESS EXCLUSIVE MODE;

-- Preserve the loaded table temporarily inside this transaction.
ALTER TABLE spotify.streams RENAME TO streams_unpartitioned_backup;

-- Remove the old PK index name before creating the partitioned PK.
ALTER TABLE spotify.streams_unpartitioned_backup
    DROP CONSTRAINT IF EXISTS streams_pkey;

CREATE TABLE spotify.streams (
    stream_id   INTEGER NOT NULL,
    user_id     INTEGER NOT NULL REFERENCES spotify.users(user_id),
    track_id    INTEGER NOT NULL REFERENCES spotify.tracks(track_id),
    started_at  TIMESTAMPTZ NOT NULL,
    ms_played   INTEGER NOT NULL CHECK (ms_played >= 0),
    platform    TEXT NOT NULL CHECK (platform IN ('ANDROID', 'CAR', 'DESKTOP', 'IOS', 'SPEAKER', 'WEB')),
    source_type TEXT NOT NULL CHECK (source_type IN ('ALBUM', 'ARTIST', 'PLAYLIST', 'RADIO', 'SEARCH')),
    playlist_id INTEGER REFERENCES spotify.playlists(playlist_id),
    skipped     BOOLEAN NOT NULL,
    offline     BOOLEAN NOT NULL,
    CONSTRAINT streams_pkey PRIMARY KEY (stream_id, started_at),
    CONSTRAINT streams_playlist_source_check CHECK (
        (source_type = 'PLAYLIST' AND playlist_id IS NOT NULL)
        OR
        (source_type <> 'PLAYLIST' AND playlist_id IS NULL)
    )
) PARTITION BY RANGE (started_at);

-- Build one partition for each month represented in the loaded data.
-- Bounds are explicit +05:30 timestamps so they do not depend on the
-- PostgreSQL server's machine-level timezone setting.
DO $$
DECLARE
    v_min_month DATE;
    v_max_month DATE;
    v_month DATE;
    v_next_month DATE;
    v_partition_name TEXT;
    v_from_bound TEXT;
    v_to_bound TEXT;
BEGIN
    SELECT
        date_trunc('month', min(started_at) AT TIME ZONE 'Asia/Kolkata')::date,
        date_trunc('month', max(started_at) AT TIME ZONE 'Asia/Kolkata')::date
    INTO v_min_month, v_max_month
    FROM spotify.streams_unpartitioned_backup;

    IF v_min_month IS NULL OR v_max_month IS NULL THEN
        RAISE EXCEPTION 'Source streams table is empty; refusing to create data-dependent partitions';
    END IF;

    v_month := v_min_month;
    WHILE v_month <= v_max_month LOOP
        v_next_month := (v_month + INTERVAL '1 month')::date;
        v_partition_name := 'streams_p' || to_char(v_month, 'YYYY_MM');
        v_from_bound := to_char(v_month, 'YYYY-MM-DD') || ' 00:00:00+05:30';
        v_to_bound := to_char(v_next_month, 'YYYY-MM-DD') || ' 00:00:00+05:30';

        EXECUTE format(
            'CREATE TABLE spotify.%I PARTITION OF spotify.streams FOR VALUES FROM (%L::timestamptz) TO (%L::timestamptz)',
            v_partition_name, v_from_bound, v_to_bound
        );
        v_month := v_next_month;
    END LOOP;
END
$$;

-- Catch future/out-of-range dates (including W01's 2026-07-01 test insert).
CREATE TABLE spotify.streams_p_default
    PARTITION OF spotify.streams DEFAULT;

-- Copy all rows into their monthly partitions.
INSERT INTO spotify.streams (
    stream_id, user_id, track_id, started_at, ms_played,
    platform, source_type, playlist_id, skipped, offline
)
SELECT
    stream_id, user_id, track_id, started_at, ms_played,
    platform, source_type, playlist_id, skipped, offline
FROM spotify.streams_unpartitioned_backup;

-- Fail and roll back if row counts differ or stream_id is not globally unique
-- in this loaded dataset (the original table's PK guaranteed this property).
DO $$
DECLARE
    v_old_count BIGINT;
    v_new_count BIGINT;
    v_distinct_ids BIGINT;
BEGIN
    SELECT count(*) INTO v_old_count FROM spotify.streams_unpartitioned_backup;
    SELECT count(*), count(DISTINCT stream_id)
      INTO v_new_count, v_distinct_ids
      FROM spotify.streams;

    IF v_old_count <> v_new_count THEN
        RAISE EXCEPTION 'Partition copy row-count mismatch: source %, partitioned %', v_old_count, v_new_count;
    END IF;
    IF v_new_count <> v_distinct_ids THEN
        RAISE EXCEPTION 'stream_id is not globally unique in loaded data; investigate before proceeding';
    END IF;
END
$$;

-- Dropping the backup also removes any old-table indexes. Recreate CP3 indexes
-- on the partitioned parent by running sql/05_indexes.sql after this file.
DROP TABLE spotify.streams_unpartitioned_backup;

COMMENT ON TABLE spotify.streams IS
    'CP4 monthly RANGE partitioned stream fact table, partitioned by started_at';

COMMIT;

-- Verify with:
-- SELECT relid::regclass, parentrelid::regclass FROM pg_partition_tree('spotify.streams');
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT count(*) FROM spotify.streams
-- WHERE started_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
--   AND started_at <  TIMESTAMPTZ '2026-07-01 00:00:00+05:30';
