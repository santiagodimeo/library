---
title: Log-based change data capture
domain: software
area: data
claim: Tailing a database's transaction log publishes every committed change without modifying writers, but it's bounded by log retention and needs a separate full-state snapshot path.
confidence: medium
sources:
  - Yogeshwer Sharma et al., "Wormhole: Reliable Pub-Sub to Support Geo-replicated Internet Services", USENIX NSDI 2015 — https://www.usenix.org/system/files/conference/nsdi15/nsdi15-paper-sharma.pdf [T1]
  - Andreas Andreakis, Ioannis Papapanagiotou, "DBLog: A Watermark Based Change-Data-Capture Framework", arXiv 2020 — https://arxiv.org/abs/2010.12597 [T3]
  - Arslan Ahmad, "Change Data Capture 101", DesignGurus 2026 — https://www.designgurus.io/blog/change-data-capture [T2]
  - Ian Cartwright, Rob Horn, James Lewis, "Event Interception", martinfowler.com 2024 — https://martinfowler.com/articles/patterns-legacy-displacement/event-interception.html [T2]
updated: 2026-09-16
from: investigations/2026-09-16-outbox-vs-cdc.md
related: [[[transactional-outbox]], [[at-least-once-event-delivery]]]
---

# Log-based change data capture

Log-based CDC reads committed changes from a database's transaction log (MySQL binlog, PostgreSQL WAL) and publishes them downstream (Sharma 2015; Andreakis 2020). Writers don't change. Facebook chose this for Wormhole because interposing on writes across its storage fleet would be error-prone and could hurt latency and availability, and because application polling forces a choice between stale data and extra load (Sharma 2015). Of the CDC styles, which are timestamp polling, triggers, and log reading, log-based capture puts the least load on the primary (Ahmad 2026).

The output is what was stored. Wormhole encodes each update as key-value pairs of the written data plus metadata (Sharma 2015). That suits replication into caches, indexes, and read models, and legacy displacement, where teams stream a legacy database into Kafka for new consumers (Cartwright 2024).

## Tradeoffs

Scale is proven. In 2015 Wormhole moved over 35 GB/s steady (50M messages/s), with 200 GB/s bursts in recovery (Sharma 2015). Delivery is at-least-once and ordered per shard only (Sharma 2015); see [[at-least-once-event-delivery]].

Logs expire. Wormhole's guarantees lapse once an update leaves the log, and its datastores kept 1–2 days; lagging subscribers get a data-loss callback (Sharma 2015). Logs don't hold full history, so bootstrap and repair need a full-state capture (Andreakis 2020, *unreplicated*). DBLog reported in 2020 that Debezium's snapshot took table locks that could block writes on MySQL RDS, and it avoided locks with a watermark method that interleaves chunked selects with log events (Andreakis 2020, *unreplicated*; tool behavior may have changed).

For publishing domain events, the payload is row state, not intent. Pointing CDC at an outbox table instead gives both; see [[transactional-outbox]].
