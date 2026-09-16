---
title: RDS Proxy connection pinning
domain: software
area: data
claim: RDS Proxy only multiplexes connections that carry no session state, and common driver defaults — such as a pool reset that runs RESET ALL — can pin every connection and erase the benefit.
confidence: medium
sources:
  - AWS, "Avoiding pinning an RDS Proxy", Amazon RDS User Guide n.d. — https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html [T2]
  - AWS, "Amazon RDS Proxy", Amazon RDS User Guide n.d. — https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html [T2]
  - Singh, Dave, Gopalan, Shalom, "Amazon RDS Proxy multiplexing support for PostgreSQL Extended Query Protocol", AWS Database Blog 2023 — https://aws.amazon.com/blogs/database/amazon-rds-proxy-multiplexing-support-for-postgresql-extended-query-protocol/ [T2]
  - AWS, "Quotas and constraints for Amazon RDS", Amazon RDS User Guide n.d. — https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html [T2]
  - MagicStack, "asyncpg API reference", asyncpg docs n.d. — https://magicstack.github.io/asyncpg/current/api/index.html [T2]
updated: 2026-09-16
from: a private investigation
related: [postgres-job-queues, autoscaling-queue-workers]
---

# RDS Proxy connection pinning

RDS Proxy shares backend connections between clients only while a session carries no state. For PostgreSQL, a connection is pinned to one client by: `SET` or resetting a parameter; SQL-level `PREPARE`/`EXECUTE`/`DEALLOCATE`/`DISCARD`; session-level advisory locks (the `_xact_` variants don't pin); `LISTEN`; temporary tables and cursors; `nextval`/`setval`; loading a library module; and any statement over 16 KB (AWS n.d. a; AWS n.d. b). The `DatabaseConnectionsCurrentlySessionPinned` metric shows it (AWS n.d. a).

Since November 2023, protocol-level prepared statements from the extended query protocol are multiplexed rather than pinned (Singh 2023). Driver statement caches that use them are therefore probably fine; AWS doesn't name specific drivers.

asyncpg's default pool reset runs `SELECT pg_advisory_unlock_all(); CLOSE ALL; UNLISTEN *; RESET ALL;` on every release (MagicStack n.d.). Both `RESET ALL` and the advisory-lock call are on the pinning list, so a default asyncpg pool likely pins every connection. That's inference from the two docs; override the reset and watch the metric.

## Tradeoffs

- Check whether a proxy is needed at all. Default PostgreSQL `max_connections` on RDS is `LEAST(DBInstanceClassMemory/9531392, 5000)` (AWS n.d. c). Around 20 services with pools of 10 fit on a 4 GB instance without one (arithmetic).
- The proxy doesn't support PostgreSQL `CancelRequest`, so client-side timeouts may leave queries running on the server (AWS n.d. b; consequence inferred).
- Bulk inserts carrying long text can cross 16 KB and pin (AWS n.d. b).
- The proxy attaches only to the writer; read replicas don't relieve write pressure (AWS n.d. b).
