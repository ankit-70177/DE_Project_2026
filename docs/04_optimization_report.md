# CP3 Optimization Report

## Summary

Every workload query was run three times on PostgreSQL 18.6. The optimized benchmark used an isolated database loaded from the repository seed data. The CP2 baseline summary and plans remain unchanged.

The sum of the 30 query averages fell from **19,337.930 ms** to **352.960 ms** (98.2% lower). This sum is dominated by R19: its two correlated subqueries each scanned 250,000 streams for each verified artist.

## Before and after

Improvement = (before − after) / before × 100. Each raw plan file contains three runs.

| Query | Before (ms) | Problem found in the plan | Optimization applied | After (ms) | Improvement | Same result? |
|---|---:|---|---|---:|---:|:---:|
| R01 | 16.264 | Broad scans to find one artist within a date window. | Timestamp range and artist-to-track indexes narrow the lookups. | 1.522 | 90.6% | Yes |
| R02 | 3.286 | Sequential scan and sort of all tracks for one album. | Covering album/disc/track index returns the ordered list. | 0.029 | 99.1% | Yes |
| R03 | 44.716 | Leading-wildcard ILIKE required a table scan. | pg_trgm GIN index supports the contains search. | 5.217 | 88.3% | Yes |
| R04 | 10.367 | Full streams scan and sort for one user’s newest 50 rows. | User/time covering index supplies ordered history. | 0.068 | 99.3% | Yes |
| R05 | 0.393 | Already used primary-key indexes; small playlist lookup. | Existing primary-key access remains; no rewrite. | 0.135 | 65.6% | Yes |
| R06 | 0.078 | Already used composite primary-key and track primary-key lookups. | Existing indexes handle the selective user lookup. | 0.041 | 47.4% | Yes |
| R07 | 23.055 | Broad scan of streams and track-artist mappings. | Time index narrows June rows; the planner still scans mappings for the join. | 9.341 | 59.5% | Yes |
| R08 | 20.578 | Broad stream and mapping scans for one artist. | Artist-first mapping and track-first stream indexes support the joins. | 0.950 | 95.4% | Yes |
| R09 | 11.318 | EXTRACT(YEAR) on the timestamp hid the time range from the index. | Half-open year range and user/time index. | 0.102 | 99.1% | Yes |
| R10 | 20.670 | Casting every timestamp to date hid the range from the index. | Half-open timestamp range and covering time index. | 4.735 | 77.1% | Yes |
| R11 | 0.976 | Release lookup over followed artists. | Artist/release covering index narrows matching releases. | 0.075 | 92.3% | Yes |
| R12 | 29.495 | Broad scans of streams and tracks for compliance matches. | Time index narrows stream rows; PK lookups fetch users and tracks. | 10.406 | 64.7% | Yes |
| R13 | 48.314 | NOT IN returned no rows because stream playlist_id contains NULLs. | NOT EXISTS fixes the NULL semantics; partial non-NULL index supports the lookup. | 3.522 | 92.7% | Corrected: 0 → 1,891 rows |
| R14 | 16.883 | All collaborative playlist tracks are needed for contributor counts; final plan chose sequential scans. | Added playlist/contributor index, but planner still scans at this data size. | 9.082 | 46.2% | Yes |
| R15 | 4.053 | Finding followers of artist 33 scanned all follows. | Artist-first follow index finds seed followers. | 0.607 | 85.0% | Yes |
| R16 | 35.520 | Date-window stream scan plus mapping scan for all artists. | Time index narrows the range; mapping scan remains low cost for the join. | 16.367 | 53.9% | Yes |
| R17 | 21.522 | Broad scans for June streams and free users. | Time index narrows streams; user table is only 30k rows. | 4.312 | 80.0% | Yes |
| R18 | 30.320 | Offline-share aggregate must inspect every stream. | No selective predicate; full-table scan remains appropriate. | 17.175 | 43.4% | Yes |
| R19 | 18421.592 | Two correlated subqueries rescanned all 250k streams for each of 334 verified artists. | One aggregate computes count/max; artist and track indexes support joins. | 22.252 | 99.9% | Yes |
| R20 | 319.400 | Country/hour aggregation reads all streams and users. | No selective predicate; full-table scans remain appropriate. | 156.037 | 51.1% | Yes |
| R21 | 0.065 | Already used unique ISRC and album primary-key indexes. | Existing unique/primary-key indexes provide direct lookup. | 0.047 | 27.7% | Yes |
| R22 | 56.576 | Duplicate grouping must inspect all playlist-track rows; final plan chose sequential scan. | Added both playlist/track key orders; the aggregate remains scan-bound. | 27.229 | 51.9% | Yes |
| R23 | 89.728 | Deep OFFSET required a full scan, full sort, and temp disk spill. | Covering time index avoids sorting and disk spill; OFFSET still reads 200,025 entries. | 13.367 | 85.1% | Yes |
| R24 | 23.558 | Summary aggregates all tracks and album types. | No selective predicate; sequential scans remain appropriate. | 12.629 | 46.4% | Yes |
| R25 | 33.371 | Joined streams before restricting to the recent release window. | Restricts to recent tracks before counting their streams. | 1.345 | 96.0% | Yes |
| W01 | 0.884 | Single-row insert; original omitted required offline value. | Supplied offline=FALSE as required by schema. | 0.778 | 12.0% | Corrected input |
| W02 | 0.766 | Single-row insert with unique-conflict check. | Existing composite primary key supports idempotency. | 0.528 | 31.1% | Yes |
| W03 | 0.690 | Append calculates the maximum position for one playlist. | Existing playlist and playlist/position primary keys support lookup. | 0.500 | 27.5% | Yes |
| W04 | 44.221 | Recomputes monthly listeners across all artists and recent streams. | Timestamp index narrows recent streams; joins and aggregation still scan mappings. | 34.474 | 22.0% | Yes |
| W05 | 9.271 | Delete searched playlist rows for tracks selected from an album. | Track-first playlist index makes album-track deletion selective. | 0.088 | 99.1% | Yes |
| **Total of averages** | **19337.930** | — | — | **352.960** | **98.2%** | — |

## Plan evidence for the five largest improvements

1. **R19 (99.9%)** — The before plan ran both correlated subplans once per verified artist and rescanned the 250,000-row streams table. The rewritten plan aggregates once and probes track/artist indexes. See [before plan](../benchmarks/results/baseline/R19.txt) and [after plan](../benchmarks/results/optimized/R19.txt).
2. **R04 (99.3%)** — The before plan scanned all streams. The after plan uses the user/time index for the requested 50 newest rows. See [before plan](../benchmarks/results/baseline/R04.txt) and [after plan](../benchmarks/results/optimized/R04.txt).
3. **R02 (99.1%)** — The before plan scanned tracks for one album. The after plan reads the ordered projection from the covering album/disc/track index. See [before plan](../benchmarks/results/baseline/R02.txt) and [after plan](../benchmarks/results/optimized/R02.txt).
4. **R09 (99.1%)** — The before plan applied EXTRACT to the timestamp. The after plan uses a half-open range and user/time index. See [before plan](../benchmarks/results/baseline/R09.txt) and [after plan](../benchmarks/results/optimized/R09.txt).
5. **W05 (99.1%)** — The before plan scanned playlist tracks for album rows. The after plan uses the track-first index to find matching entries. See [before plan](../benchmarks/results/baseline/W05.txt) and [after plan](../benchmarks/results/optimized/W05.txt).

R23 also improved: its before plan sorts all 250,000 streams and spills about 9.3 MB to disk; its after plan uses the covering started_at index and avoids the sort/spill. OFFSET still walks 200,025 index entries.

## Result checks and NULL finding

Compared before and after rows on the same loaded data for each rewritten read: R01 (10 rows), R09 (4), R10 (180), R19 (334), and R25 (50) match exactly.

R13 exposed the NULL bug. NOT IN returns unknown for every candidate when its subquery contains NULL. Non-playlist streams have NULL playlist_id, so the original query returned **0** rows. NOT EXISTS correctly returns **1,891** public playlists that were never played. This intentionally fixes the original wrong result.

W01 in the original workload omits offline, although the schema requires it and provides no default. The CP2 baseline notes the successful benchmark used offline=FALSE; the optimized workload includes that required value. The original workload file is unchanged.

## Write overhead

No write query was slower in this rerun. Before/after averages: W01: 0.884 → 0.778, W02: 0.766 → 0.528, W03: 0.690 → 0.500, W04: 44.221 → 34.474, W05: 9.271 → 0.088 ms. These are local measurements; sub-millisecond results are sensitive to timing noise. W04 remains a full aggregate over recent streams and artist mappings.

## Index storage

Measured with pg_relation_size for each index and its base table after loading the 250,000-stream seed. Sizes are rounded to KiB; primary-key and unique indexes are not included.

| Table | Table size (KiB) | CP3 index | Index size (KiB) |
|---|---:|---|---:|
| albums | 1,064 | idx_albums_artist_release | 680 |
| artist_follows | 3,024 | idx_artist_follows_artist_user | 1,544 |
| playlist_tracks | 6,120 | idx_playlist_tracks_playlist_adder | 1,104 |
| playlist_tracks | 6,120 | idx_playlist_tracks_playlist_track | 2,648 |
| playlist_tracks | 6,120 | idx_playlist_tracks_track_playlist | 2,656 |
| streams | 20,608 | idx_streams_playlist_played | 928 |
| streams | 20,608 | idx_streams_started_at_cover | 13,488 |
| streams | 20,608 | idx_streams_track_started_at | 12,128 |
| streams | 20,608 | idx_streams_user_started_at | 12,136 |
| track_artists | 3,432 | idx_track_artists_artist_track | 2,496 |
| tracks | 5,856 | idx_tracks_album_disc_track | 3,848 |
| tracks | 5,856 | idx_tracks_title_trgm | 2,208 |

The 12 indexes use about 54.6 MiB in this local database. Stream indexes account for most of the storage because user history, track joins, and time reporting need different key orders.

## Queries that remain scan-bound

R18 and R20 aggregate all streams; R24 summarizes all tracks. R14 and R22 also need to inspect all relevant playlist-track rows, and PostgreSQL chose sequential scans at this data size even with the added indexes. R07 and R16 hash-join a time-window stream set with the full track-artist mapping. These are expected costs for broad aggregations.

## Reproduction

1. Load sql/01_schema.sql and sql/02_load_data.sql into a clean PostgreSQL database with the seed CSVs available.
2. Apply sql/05_indexes.sql.
3. Run ./benchmarks/run_benchmark.sh <database> optimized 3 sql/06_optimized_queries.sql.
4. Inspect benchmarks/results/optimized/summary.csv and its raw plans.

These measurements describe this laptop and the 250,000-stream data set; they are not a scalability claim.
