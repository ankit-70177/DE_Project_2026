# CP4 Scalability Report

## 1. Environment and reproducibility

- Machine: Apple MacBook Pro, Apple M4
- RAM: 16 GiB
- Operating system: macOS 27.2.1 (Build 26B131)
- PostgreSQL: 17.12 (Homebrew), both databases
- Database names: `spotify_cp4_seed17`, `spotify_cp4_large`
- Time zone: `Asia/Kolkata`
- Seed streams: 250,000
- Large streams: 5,000,000
- Dataset scale factor: 20×
- Workload: 25 READ queries (R01–R25) and 5 WRITE queries (W01–W05)
- Each query executed three times using `EXPLAIN (ANALYZE, BUFFERS)`.
- Write-query benchmark executions use transaction rollback as specified by the benchmark procedure.
- Benchmark command: `./benchmarks/run_benchmark.sh <database> <phase> 3 sql/06_optimized_queries.sql`

Both comparison databases use PostgreSQL 17.12 on the same machine. These are local benchmark results; they are not production capacity measurements.

## 2. Large-data benchmark results

Run timings below are extracted from the three raw large-data plans. Averages and growth ratios are calculated from the checked-in summary CSVs.

| Query | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Seed PG17 avg (ms) | Large avg (ms) | Growth (×) | Target (ms) | Meets target? | Plan finding |
|---|---:|---:|---:|---:|---:|---:|---:|:---:|---|
| R01 | 10.478 | 2.685 | 2.584 | 0.813 | 5.249 | 6.46 | 250 | Yes | Index Only Scan using idx_track_artists_artist_track on track_artists |
| R02 | 0.831 | 0.215 | 0.151 | 0.154 | 0.399 | 2.59 | 5 | Yes | Index Only Scan using idx_tracks_album_disc_track on tracks |
| R03 | 101.788 | 34.406 | 32.529 | 11.544 | 56.241 | 4.87 | 250 | Yes | Bitmap Heap Scan on tracks |
| R04 | 1.423 | 0.297 | 0.280 | 0.126 | 0.667 | 5.29 | 5 | Yes | Index Only Scan using streams_p2025_01_user_id_started_at_track_id_ms_played_plat_idx on streams_p2025_01 |
| R05 | 6.118 | 0.188 | 0.138 | 0.567 | 2.148 | 3.79 | 5 | Yes | Index Scan using playlist_tracks_pkey on playlist_tracks |
| R06 | 0.686 | 0.047 | 0.055 | 0.140 | 0.263 | 1.88 | 5 | Yes | Index Scan using liked_tracks_pkey on liked_tracks |
| R07 | 591.635 | 283.459 | 282.792 | 18.717 | 385.962 | 20.62 | 5000 | Yes | June 2026 partition scan; sequential scan of the selected partition |
| R08 | 12.585 | 7.016 | 7.055 | 0.961 | 8.885 | 9.25 | 250 | Yes | Index Only Scan using idx_track_artists_artist_track on track_artists |
| R09 | 1.639 | 0.232 | 0.241 | 0.285 | 0.704 | 2.47 | 250 | Yes | Index Only Scan using streams_p2025_01_user_id_started_at_track_id_ms_played_plat_idx on streams_p2025_01 |
| R10 | 90.090 | 78.996 | 78.706 | 11.429 | 82.597 | 7.23 | 5000 | Yes | Seq Scan on streams_p2026_06 |
| R11 | 1.638 | 0.077 | 0.081 | 0.150 | 0.599 | 3.99 | 5 | Yes | Index Only Scan using artist_follows_pkey on artist_follows |
| R12 | 435.663 | 29.568 | 19.758 | 17.760 | 161.663 | 9.10 | 5000 | Yes | Index Only Scan using streams_p2025_01_started_at_stream_id_user_id_track_id_ms_p_idx on streams_p2025_01 |
| R13 | 108.307 | 96.442 | 94.522 | 4.585 | 99.757 | 21.76 | 250 | Yes | Playlist-based stream aggregation; partition indexes are used |
| R14 | 72.376 | 64.299 | 64.896 | 7.354 | 67.190 | 9.14 | 5000 | Yes | Index Scan using playlists_pkey on playlists |
| R15 | 73.918 | 3.395 | 3.526 | 1.429 | 26.946 | 18.86 | 250 | Yes | Index Only Scan using idx_artist_follows_artist_user on artist_follows |
| R16 | 418.929 | 391.362 | 364.828 | 20.010 | 391.706 | 19.58 | 5000 | Yes | Sequential scan of June 2026 partition and default partition |
| R17 | 110.061 | 58.680 | 57.654 | 6.539 | 75.465 | 11.54 | 5000 | Yes | Seq Scan on streams_p2026_06 |
| R18 | 308.166 | 261.985 | 257.564 | 22.046 | 275.905 | 12.51 | 5000 | Yes | Sequential scans across stream partitions |
| R19 | 925.903 | 811.451 | 836.689 | 19.940 | 858.014 | 43.03 | 5000 | Yes | Sequential scans across all stream partitions |
| R20 | 1687.152 | 1719.109 | 1714.628 | 135.349 | 1706.963 | 12.61 | 5000 | Yes | Sequential scans across stream partitions and users |
| R21 | 0.419 | 0.039 | 0.039 | 0.044 | 0.166 | 3.77 | 5 | Yes | Index Scan using tracks_isrc_key on tracks |
| R22 | 298.532 | 259.993 | 263.830 | 29.507 | 274.118 | 9.29 | 250 | **No** | Index-only scan of 2.4M playlist-track rows; 2.328M groups filtered |
| R23 | 23.123 | 20.364 | 19.279 | 12.992 | 20.922 | 1.61 | 5000 | Yes | Index Only Scan using streams_p2025_01_started_at_stream_id_user_id_track_id_ms_p_idx on streams_p2025_01 |
| R24 | 128.618 | 91.733 | 126.873 | 11.818 | 115.741 | 9.79 | 5000 | Yes | Seq Scan on tracks |
| R25 | 599.138 | 486.317 | 523.395 | 1.413 | 536.283 | 379.54 | 250 | **No** | Sequential scans across all 19 leaf partitions; 5M streams considered |
| W01 | 2.056 | 0.954 | 1.128 | 0.705 | 1.379 | 1.96 | 5 | Yes | (no scan) |
| W02 | 2.032 | 1.518 | 2.332 | 1.416 | 1.961 | 1.38 | 5 | Yes | (no scan) |
| W03 | 3.646 | 2.114 | 2.034 | 2.071 | 2.598 | 1.25 | 5 | Yes | Index Scan using playlists_pkey on playlists |
| W04 | 949.517 | 798.752 | 913.608 | 41.753 | 887.292 | 21.25 | 3000 | Yes | Index-based lookup across June/default partitions; expensive write-side work |
| W05 | 2.865 | 0.171 | 0.157 | 0.096 | 1.064 | 11.08 | 250 | Yes | Index Scan using tracks_pkey on tracks |

**Target result: 28/30 queries passed (93.33%).** R22 and R25 missed their 250 ms interactive target.

Target groups are taken from `CHECKPOINTS.md`: listener-facing queries use a 5 ms target; interactive queries use 250 ms; analytics queries use 5,000 ms; W04 uses 3,000 ms.

## 3. Growth analysis

Growth is calculated as `large average ÷ seed average`. The dataset grew 20×, but query latency did not grow uniformly because plans, selectivity, indexes, partition pruning, cache state and scanned row counts differ.

- **Lower growth:** R02 (2.59×), R06 (1.88×), R09 (2.47×), R21 (3.77×), W01 (1.96×), W02 (1.39×), W03 (1.25×), and R23 (1.61×). These remained relatively efficient compared with the dataset scale, although the absolute target must still be considered separately.
- **Moderate or substantial growth:** R01 (6.46×), R03 (4.87×), R07 (20.62×), R10 (7.23×), R12 (9.10×), R13 (21.76×), R16 (19.58×), R17 (11.54×), R18 (12.52×), R19 (43.03×), R20 (12.61×), R22 (9.29×), R24 (9.79×), and W04 (21.25×). These query plans process larger stream, playlist, or relationship sets, or touch multiple partitions.
- **R25 grew 379.49×**, from 1.413 ms to 536.283 ms. Its recent-track filter is on album release date, while the stream table is partitioned on `started_at`. The filter therefore does not restrict the stream partitions, and the plan scans all 19 leaf partitions.
- Ratios are observed measurements, not a claim that every query follows a linear scaling law. Three-run local timings can also vary with cache and I/O state.

## 4. What broke at scale

### R22 — playlist duplicate detection

- Large average: 274.118 ms; target: 250 ms; miss: 24.118 ms (about 9.65% above target).
- The plan uses an index-only scan on `idx_playlist_tracks_playlist_track` over approximately 2,400,008 rows. It reports zero heap fetches.
- The grouping/filter stage removes approximately 2,328,008 groups and returns about 36,000 duplicate groups.
- A diagnostic experiment disabling index and index-only scans produced a sequential-scan/hash-aggregate plan taking 707.394 ms, with 81 hash batches and temporary disk usage. This was slower than the original plan.
- Decision: retain the original index-only plan. The experiment did not justify replacing it or adding a duplicate index. No official benchmark query or index was changed based on this experiment.

### R25 — recent releases ranked by streams

- Large average: 536.283 ms; target: 250 ms; approximately 2.15× the target.
- The query first finds 11,165 recent tracks using `albums.release_date`, then aggregates matching stream counts.
- The stream aggregation scans all 19 leaf partitions, considering the 5,000,000-row stream fact table. The release-date predicate does not constrain the `started_at` partition key.
- A LATERAL/index-lookup alternative was tested diagnostically and took 766.764 ms. Repeated lookups across 19 partitions were more expensive than the original plan.
- Decision: retain the original query. The tested alternative was rejected; no unsupported performance improvement is claimed.

### Other scale observations

- R19 and R20 perform broad scans over stream partitions and have high absolute runtimes, but remain under their 5,000 ms analytics target.
- W04 averages 887.292 ms, which is below its 3,000 ms target, but its growth ratio is 21.25× and should be monitored.
- No before/after optimization is claimed for R22 or R25 because the tested alternatives were slower. Original raw plans remain preserved.

## 5. Partitioning design and evidence

- Partitioned table: `spotify.streams`.
- Strategy: monthly `RANGE (started_at)` partitions using `Asia/Kolkata` calendar-month boundaries.
- Partition range represented by the loaded dataset: January 2025 through June 2026.
- Leaf partitions: 18 monthly partitions plus one default partition (19 leaf partitions total).
- The default partition catches out-of-range dates, including the future-dated W01 test insert.
- Primary key: `(stream_id, started_at)`. PostgreSQL requires a partitioned table's unique/primary-key constraint to include its partition key. The composite key therefore does not itself enforce global uniqueness of `stream_id`; the migration separately checked that stream IDs in the loaded dataset were globally unique.
- The migration is transactional, preserves the source table during the copy, checks row counts and stream-ID uniqueness, and drops the backup only after validation.

### Partition pruning evidence

A June 2026 range query using `started_at` reported `Subplans Removed: 18` and scanned only `streams_p2026_06`. The recorded EXPLAIN showed:

- Selected partition: `streams_p2026_06`
- Shared buffer hits: 2,806
- Execution time: 14.073 ms for this single diagnostic EXPLAIN execution
- Planning time: 4.418 ms

This is evidence of partition pruning for a date predicate on the partition key. It is not a replacement for the three-run workload benchmark.

### Monthly partition row counts

| Partition | Rows |
|---|---:|
| `streams_p2025_01` | 283,883 |
| `streams_p2025_02` | 256,411 |
| `streams_p2025_03` | 283,882 |
| `streams_p2025_04` | 274,726 |
| `streams_p2025_05` | 283,882 |
| `streams_p2025_06` | 274,726 |
| `streams_p2025_07` | 283,882 |
| `streams_p2025_08` | 283,883 |
| `streams_p2025_09` | 274,725 |
| `streams_p2025_10` | 283,883 |
| `streams_p2025_11` | 274,726 |
| `streams_p2025_12` | 283,882 |
| `streams_p2026_01` | 283,883 |
| `streams_p2026_02` | 256,410 |
| `streams_p2026_03` | 283,883 |
| `streams_p2026_04` | 274,725 |
| `streams_p2026_05` | 283,883 |
| `streams_p2026_06` | 274,725 |
| `streams_p_default` | 0 |

Total: 5,000,000 stream rows across 19 leaf partitions. The default partition currently contains zero rows in the loaded dataset.

Detailed SQL output and the partition-pruning plan are preserved in `benchmarks/results/large/partition_evidence.txt`.

## 6. Storage

| Database / object | Total size | Table bytes | Index bytes |
|---|---:|---:|---:|
| Seed database | 129 MB | — | — |
| Seed `spotify.streams` | 63 MB | 20 MB | 43 MB |
| Large database | 2,478 MB | — | — |
| Large stream leaf partitions combined | 1,329 MB | 399 MB | 929 MB |

Database size includes all database objects, not only the streams table. The large partition totals aggregate the 19 leaf partitions. The partitioned parent relation itself is not a physical heap; its size should be measured by summing its leaf partitions.

## 7. Architecture for 100× volume

The following are architectural recommendations, not changes implemented or validated by this local benchmark.

### Sharding

- Keep time-based partitioning within each shard for retention and time-window analytics.
- A user-based shard key (`user_id`) is a candidate for listener-facing history and user activity, since it localizes user-scoped queries.
- Artist/track-based sharding may help track-centric workloads but makes user-history queries and cross-artist reports more expensive.
- Global artist, royalty and discovery reports would require cross-shard aggregation. Use scheduled aggregation jobs or a distributed analytical layer rather than synchronously querying every shard for each request.
- Introduce a routing layer that maps a user or tenant key to a shard and documents how cross-shard queries are executed.

### Read replicas and caching

- Keep writes and read-after-write operations on the primary database.
- Route suitable read-heavy analytics and reporting queries to replicas, with an explicit replication-lag tolerance.
- Cache frequently requested artist, album, track and summary results with bounded TTLs and invalidation on relevant writes.
- Use precomputed/materialized summaries for expensive global reports; define refresh cadence and acceptable staleness.

### Maintenance

- Create future monthly partitions ahead of time and monitor the default partition for unexpected dates.
- Apply and verify autovacuum/analyze behavior on high-write partitions; tune settings only after measuring actual dead tuples, vacuum duration and workload.
- Archive or detach old partitions according to retention requirements and backup policy.
- Refresh summary tables on a documented schedule and monitor refresh duration, freshness and storage.
- Monitor partition count, per-partition row counts, index size, query latency, buffer reads, replication lag and disk growth.

## 8. Conclusion and remaining risks

The 5,000,000-row dataset represents a 20× increase over the 250,000-row seed dataset. Monthly range partitioning is implemented and June 2026 partition pruning was demonstrated. The benchmark met 28 of 30 query targets (93.33%).

R22 and R25 did not meet the 250 ms interactive target. The diagnostic alternatives tested for these queries were slower, so the original query plans were retained and the misses are reported transparently.

Important remaining risks:

- R25 scans all stream partitions because its date predicate is not on the partition key.
- R22 still processes millions of playlist-track rows for duplicate detection.
- The local machine benchmark does not establish production throughput, concurrency capacity, availability, replication behavior or 100× readiness.
- Global uniqueness of `stream_id` across future partitions requires an explicit enforcement design if it is a production requirement.
- The proposed 100× architecture requires separate load, concurrency, failover and operational testing.

Raw plans, summary CSVs, partitioning SQL and partition evidence are retained alongside this report for reproducibility.
