---
title: Postgres job queues
domain: software
area: data
claim: A Postgres table claimed with SKIP LOCKED is a workable job queue only while claim transactions stay short, vacuum keeps up with churn, and old jobs leave by dropped partitions rather than DELETE.
confidence: medium
sources:
  - PostgreSQL Global Development Group, "SELECT — The Locking Clause", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/sql-select.html [T2]
  - PostgreSQL Global Development Group, "Partial Indexes", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/indexes-partial.html [T2]
  - PostgreSQL Global Development Group, "Routine Vacuuming", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/routine-vacuuming.html [T2]
  - PostgreSQL Global Development Group, "Automatic Vacuuming", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/runtime-config-autovacuum.html [T2]
  - PostgreSQL Global Development Group, "Table Partitioning", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/ddl-partitioning.html [T2]
  - Brandur Leach, "Postgres Job Queues & Failure By MVCC", brandur.org 2015 — https://brandur.org/postgres-queues [T2]
updated: 2026-09-16
from: a private investigation
related: [queue-leases-and-retries, multi-tenant-queue-fairness, rds-proxy-connection-pinning]
---

# Postgres job queues

`FOR UPDATE SKIP LOCKED` is documented for "multiple consumers accessing a queue-like table", with the warning that it gives an inconsistent view of the data (PostgreSQL n.d. a). A partial index over pending rows keeps the claim index small; the docs warn against many overlapping partial indexes (PostgreSQL n.d. b).

The hidden cost is MVCC. A dead row version can't be removed while any transaction might still see it (PostgreSQL n.d. c). One long transaction anywhere on the database, such as an analytics query or a claim held open across a slow external call, lets dead rows pile up, and every claim walks them. Brandur measured claim lock time rising from under 10 ms to over 100 ms and a 60,000-job backlog within an hour (Leach 2015). His test predates SKIP LOCKED, but the MVCC mechanism doesn't depend on it.

Default autovacuum waits for 50 rows plus 20% of the table to be dead, and the scale factor can be overridden per table (PostgreSQL n.d. d). On a 10M-row queue that's about 2M dead rows before vacuum starts (arithmetic from the defaults).

## Tradeoffs

- Commit the claim, then do the slow work. Cap other workloads with statement or idle-transaction timeouts (Leach 2015).
- Lower the autovacuum scale factor on the queue table only, and alarm on dead tuples and oldest transaction age.
- Retention by DELETE creates the same vacuum load. Partition high-churn tables by time and drop or detach old partitions, which avoids that overhead. The primary key must include the partition key, and the docs advise staying within a few thousand partitions (PostgreSQL n.d. e).
- The docs give no row-count threshold for partitioning. Their rule of thumb is a table larger than the server's memory (PostgreSQL n.d. e).

See [[queue-leases-and-retries]] for what happens when a claimed job outlives its timeout.
