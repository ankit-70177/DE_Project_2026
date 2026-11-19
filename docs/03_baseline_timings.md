
# Spotify Music Streaming Database – Baseline Query Timings

## 1. Overview

This document presents the baseline performance measurements for the Spotify Music Streaming Database.

A total of 30 workload queries were benchmarked:
- 25 READ queries (R01–R25)
- 5 WRITE queries (W01–W05)

The objective is to measure query execution performance before applying any query optimization.

## 2. Benchmark Environment

| Parameter | Details |
|---|---|
| Database System | PostgreSQL 18.6 |
| Database Name | spotify_db |
| Schema | spotify |
| Total Tables | 10 |
| Total Records | 718,735 |
| Number of Queries | 30 |
| Executions per Query | 3 |

## 3. Benchmark Methodology

Each query was executed using PostgreSQL's:

`EXPLAIN (ANALYZE, BUFFERS)`

The following procedure was followed:

1. Each query was executed three times.
2. The execution time was recorded for every run.
3. Average, median, minimum, and maximum execution times were calculated.
4. Scan operations were recorded from the execution plans.
5. Write queries were executed inside transactions and rolled back to prevent permanent data modifications.

The benchmark results and raw execution plans are stored in:

- `benchmarks/results/baseline/summary.csv`
- `benchmarks/results/baseline/`

## 4. Baseline Results

Execution times are reported in milliseconds (ms).

| Query | Operation | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01 | Artist page – most-streamed tracks | 19.598 | 14.592 | 14.601 | 16.264 |
| R02 | Album page – tracklist | 3.818 | 3.011 | 3.029 | 3.286 |
| R03 | Track search – title contains love | 43.767 | 44.970 | 45.411 | 44.716 |
| R04 | Recently played streams | 10.312 | 10.264 | 10.525 | 10.367 |
| R05 | Playlist page – tracks and artists | 0.660 | 0.261 | 0.259 | 0.393 |
| R06 | Liked tracks | 0.080 | 0.076 | 0.078 | 0.078 |
| R07 | Royalty-eligible streams per artist | 23.162 | 22.818 | 23.185 | 23.055 |
| R08 | Artist track skip rate | 21.260 | 20.204 | 20.271 | 20.578 |
| R09 | User's top artists by listening time | 11.630 | 11.038 | 11.285 | 11.318 |
| R10 | Daily streams per platform | 20.577 | 20.481 | 20.951 | 20.670 |
| R11 | Release Radar | 1.106 | 0.910 | 0.912 | 0.976 |
| R12 | Explicit tracks streamed by minors | 30.239 | 29.279 | 28.968 | 29.495 |
| R13 | Public playlists never played | 47.499 | 47.526 | 49.918 | 48.314 |
| R14 | Collaborative playlist contributors | 17.453 | 16.598 | 16.597 | 16.883 |
| R15 | Artists followed by shared fans | 4.451 | 3.861 | 3.846 | 4.053 |
| R16 | Monthly listeners per artist | 35.572 | 35.463 | 35.524 | 35.520 |
| R17 | Free users with 4+ streams | 21.711 | 21.545 | 21.309 | 21.522 |
| R18 | Offline listening share per platform | 30.063 | 29.569 | 31.327 | 30.320 |
| R19 | Verified artists report | 18703.108 | 18317.563 | 18244.104 | 18421.592 |
| R20 | Listening patterns by country and hour | 319.878 | 313.098 | 325.225 | 319.400 |
| R21 | Recording lookup by ISRC | 0.071 | 0.063 | 0.062 | 0.065 |
| R22 | Duplicate tracks in playlists | 55.530 | 57.576 | 56.621 | 56.576 |
| R23 | Support console – deep pagination | 86.913 | 90.876 | 91.395 | 89.728 |
| R24 | Average track length by album type | 23.682 | 23.497 | 23.494 | 23.558 |
| R25 | Recently released tracks ranked by streams | 33.346 | 33.432 | 33.334 | 33.371 |
| W01 | Insert a stream | 1.487 | 0.581 | 0.584 | 0.884 |
| W02 | Add a liked track | 1.294 | 0.497 | 0.507 | 0.766 |
| W03 | Add a track to a playlist | 1.105 | 0.495 | 0.470 | 0.690 |
| W04 | Recalculate monthly listeners | 45.386 | 44.797 | 42.481 | 44.221 |
| W05 | Remove album tracks from playlists | 9.268 | 9.322 | 9.223 | 9.271 |

## 5. Performance Observations

### 5.1 Slowest READ Queries

- R19 recorded the highest average execution time at 18,421.592 ms (approximately 18.42 seconds).
- R20 took 319.400 ms.
- R23 took 89.728 ms.
- R22 took 56.576 ms.
- R13 took 48.314 ms.

R19 is a significant performance bottleneck and should be investigated during the optimization phase.

### 5.2 Fastest READ Queries

- R21 recorded the lowest average execution time at 0.065 ms.
- R06 completed in 0.078 ms.
- R05 completed in 0.393 ms.

These queries benefited from index-based access paths shown in their execution plans.

### 5.3 WRITE Query Observations

- W04 was the slowest WRITE query at 44.221 ms.
- W05 took 9.271 ms.
- W01, W02, and W03 completed in less than 1 ms on average.

W04 performs a monthly-listener recalculation involving multiple tables and aggregation.

## 6. Execution Plan Observations

The execution plans showed both sequential scans and index-based scans.

Some queries used indexes such as:
- `tracks_pkey`
- `artists_pkey`
- `playlist_tracks_pkey`
- `liked_tracks_pkey`
- `tracks_isrc_key`

Several queries performed sequential scans on larger tables such as `streams`, `tracks`, and `playlist_tracks`.

These execution plans provide useful information for identifying potential optimization opportunities.

## 7. Workload Correction Note

The original W01 query in `queries/workload_30.sql` does not specify the `offline` column.

However, the database schema requires `streams.offline` to have a value because it is NOT NULL.

Therefore, the successful W01 benchmark used a temporary corrected workload that explicitly supplied `offline = FALSE`.

The original `queries/workload_30.sql` file was not modified.

## 8. Verification

The final benchmark results contain:

- 25 READ queries × 3 executions = 75 executions.
- 5 WRITE queries × 3 executions = 15 executions.
- Total = 90 successful executions.

All 30 raw execution-plan files were checked. Each contains exactly three `Execution Time:` entries.

The combined summary CSV contains all 30 queries.

## 9. Conclusion

The baseline benchmarking phase establishes the initial performance of the Spotify database before optimization.

R19, R20, R23, and R22 are important READ-query candidates for further investigation. W04 is the slowest WRITE query.

These baseline measurements will serve as the reference point for evaluating improvements during the query optimization phase.
