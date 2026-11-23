# CP4 Scalability Report

> Complete every measured field from `benchmarks/results/seed_pg17/` and
> `benchmarks/results/large/`. Do not estimate or copy timings. The official
> CP3 `optimized/` evidence is retained separately; the controlled comparison
> below uses PostgreSQL 17 on the same machine for both seed and large data.

## 1. Environment and reproducibility

- Laptop / CPU / RAM: **[record actual machine details]**
- PostgreSQL version: **[paste `SELECT version()` from both databases]**
- OS version: **[record]**
- Database names: `spotify_cp4_seed17`, `spotify_cp4_large`
- Time zone: `Asia/Kolkata`
- Seed streams: 250,000 (verify with SQL)
- Large streams: 5,000,000 (verify with SQL)
- Benchmark command: `./benchmarks/run_benchmark.sh <database> <phase> 3 sql/06_optimized_queries.sql`

## 2. Large-data benchmark results

Copy Run 1, Run 2 and Run 3 values from the raw plans in `benchmarks/results/large/`.
The summary CSV records averages; do not fabricate missing run-level values.

| Query | Seed PG17 avg (ms) | Large avg (ms) | Growth (×) | Target (ms) | Meets target? | Plan finding / fix |
|---|---:|---:|---:|---:|:---:|---|
| R01 | | | | 250 | | |
| R02 | | | | 5 | | |
| R03 | | | | 250 | | |
| R04 | | | | 5 | | |
| R05 | | | | 5 | | |
| R06 | | | | 5 | | |
| R07 | | | | 5000 | | |
| R08 | | | | 250 | | |
| R09 | | | | 250 | | |
| R10 | | | | 5000 | | |
| R11 | | | | 5 | | |
| R12 | | | | 5000 | | |
| R13 | | | | 250 | | |
| R14 | | | | 5000 | | |
| R15 | | | | 250 | | |
| R16 | | | | 5000 | | |
| R17 | | | | 5000 | | |
| R18 | | | | 5000 | | |
| R19 | | | | 5000 | | |
| R20 | | | | 5000 | | |
| R21 | | | | 5 | | |
| R22 | | | | 250 | | |
| R23 | | | | 5000 | | |
| R24 | | | | 5000 | | |
| R25 | | | | 250 | | |
| W01 | | | | 5 | | |
| W02 | | | | 5 | | |
| W03 | | | | 5 | | |
| W04 | | | | 3000 | | |
| W05 | | | | 250 | | |

Target groups follow `CHECKPOINTS.md`: listener-facing R02/R04/R05/R06/R11/R21/W01/W02/W03 < 5 ms; interactive R01/R03/R08/R09/R13/R15/R22/R25/W05 < 250 ms; analytics R07/R10/R12/R14/R16/R17/R18/R19/R20/R23/R24 < 5,000 ms; W04 < 3,000 ms.

## 3. Growth analysis

Classify queries based on measured `large ÷ seed` ratios:

- Stayed approximately constant: **[query IDs + evidence + plan explanation]**
- Grew approximately with data volume: **[query IDs + evidence + plan explanation]**
- Grew faster than data volume: **[query IDs + evidence + cause + fix]**

## 4. What broke at scale

For each missed target, include the query ID, the actual large-data plan node/buffer evidence,
root cause, change made, and before/after large-data timings. Save raw plans in
`benchmarks/results/large/` (or a clearly named subfolder) and do not overwrite original plans.

## 5. Partitioning design and evidence

- Partitioned table: `spotify.streams`
- Strategy: monthly `RANGE (started_at)` partitions, calendar boundaries in `Asia/Kolkata`.
- Why: the workload contains date-window queries (R01, R07, R10, R12, R16, R17, R25) and a newest-first stream history (R04/R23).
- Primary key: `(stream_id, started_at)`. PostgreSQL requires the partition key to be included in a partitioned table's PRIMARY KEY/UNIQUE constraint. This means the partitioned key alone does not enforce global uniqueness of `stream_id`; the loaded dataset was checked for unique stream IDs during migration. Discuss a registry table/sequence if global uniqueness must be enforced across future partitions.
- Partition pruning evidence: paste `EXPLAIN (ANALYZE, BUFFERS)` for a June 2026 range query, showing only the relevant monthly partition(s).
- Partition count and row counts: **[actual SQL output]**.

## 6. Storage

| Database | Total DB size | Table bytes | Index bytes | Notes |
|---|---:|---:|---:|---|
| Seed PG17 | | | | |
| Large partitioned PG17 | | | | |

Use `pg_database_size`, `pg_total_relation_size`, `pg_relation_size`, and `pg_indexes_size` and record actual outputs.

## 7. Architecture for 100× volume

### Sharding

Discuss time-based vs user-based vs artist/track-based sharding. Identify cross-shard queries and the cost of global royalty/artist reports. Recommend a routing/aggregation strategy backed by measured workload patterns.

### Read replicas and caching

Identify read-heavy analytics/report queries suitable for replicas or materialized summaries, and writes / read-after-write flows that must use the primary. Explain acceptable replication lag and cache invalidation.

### Maintenance

Document autovacuum/analyze strategy for the high-write `streams` partitions, retention/archiving, partition lifecycle, and refresh cadence for summary tables. Include actual settings only if measured/configured.

## 8. Conclusion and remaining risks

**[State whether targets were met, which were not, and the evidence. Do not claim production readiness solely from a local benchmark.]**
