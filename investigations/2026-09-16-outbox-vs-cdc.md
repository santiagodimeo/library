---
title: Outbox vs. CDC
question: When should a service publish domain events through a transactional outbox, and when through log-based change data capture on its own tables?
date: 2026-09-16
domains: [software]
confidence: Medium — the mechanisms rest on T1 and T2 production write-ups, but no registry source compares the two head to head, and the exactly-once result is T3
read_time: 6 min
artifact:
---

# Outbox vs. CDC

**Bottom line.** Use a transactional outbox when you own the writing service and consumers need domain events: named, intent-bearing messages that act as a contract. Use log-based CDC on the tables themselves when you need to replicate state out of databases you can't or shouldn't modify, such as caches, search indexes, and legacy systems. Either way delivery is at-least-once and ordered only per shard, so consumers must be idempotent; the choice is about what goes into the log, not about reliability.

## Both fix the dual write by trusting the database's commit

The failure both patterns address is the dual write: a service commits to its database and then publishes to a broker, and a crash between the two leaves the systems disagreeing about what happened [1]. The outbox pattern writes the business row and an event row in one local ACID transaction, so either both exist or neither does; a separate relay publishes the event rows afterward [1].

Log-based CDC skips the extra table. It reads the database's own transaction log and turns committed changes into a stream [2][3]. Facebook built Wormhole this way because interposing on writes across its storage fleet "would require modifications across the software stack, which is error-prone and might degrade latency and availability" [2]. The same paper rejects application polling: long intervals serve stale data, and short ones interfere with production load [2].

So the two patterns share a core idea: the commit is the source of truth, and publishing is derived from it later. What differs is what the log contains.

## Outbox wins when the event is a contract, not a row

A domain event records something that happened that the business cares about, such as "make purchase" against a credit card, along with when it happened and when the system noticed [4]. That is intent. A row change is a result. When consumers act on events rather than just copying data, the event's name and payload are an interface.

With an outbox, application code writes that event explicitly, inside the transaction that caused it [1]. The payload can be shaped for consumers and versioned on its own schedule. CDC on domain tables emits what was stored: Wormhole, for example, encodes each update as the key-value pairs of the written data plus metadata [2]. Consumers then have to infer intent from state changes. That inference is our reading of the mechanism, not a measured result from any source here.

Fowler's split between event notification and event-carried state transfer maps onto this. Notification keeps coupling low but can hide logic that spans several events. State transfer lets receivers hold their own copy, which improves resilience and latency at the cost of "lots of data schlepped around and lots of copies" [5]. An outbox can carry either kind. Row-level CDC is inherently state transfer.

The outbox has real costs. Someone has to manage outbox table growth, keep the relay reliable, handle retries, and make consumers idempotent. And it doesn't apply when the store has no transactions or the caller needs synchronous completion [1].

## CDC wins when you can't or shouldn't touch the writer

CDC's strength is that the writer doesn't change. Wormhole reads logs from MySQL, HDFS, and RocksDB, and in 2015 moved over 35 GB/s in steady state (50 million messages/s) with bursts to 200 GB/s during failure recovery, feeding cache invalidation, News Feed, and search indexes [2]. Netflix's DBLog keeps heterogeneous stores in sync, such as MySQL or PostgreSQL feeding Elasticsearch, and was in production across tens of microservices in 2020 [3] *(unreplicated)*.

Legacy displacement is the other clear win. The Patterns of Legacy Displacement authors report good results using Debezium to turn a legacy database's transaction log into a Kafka stream that new applications consume [6]. Among CDC styles (timestamp polling, triggers, log reading), log-based capture puts the least load on the primary database [7].

These are all replication and derivation use cases: indexes, caches, and read models where the consumer wants the current state, not a business narrative.

## The relay is the same problem either way

The distinction blurs in practice, because a common outbox relay is CDC. The relay can poll the outbox table, or a tool like Debezium can tail the log and publish outbox rows without a custom poller [1]. So the real choice is whether the log you tail contains domain rows or event rows.

The delivery properties converge too. Outbox delivery is at-least-once, and duplicates are possible [1]. Wormhole guarantees at-least-once delivery, in order within a shard, and "no ordering guarantee between updates that belong to different shards" [2]. That works because updates for one entity live on one shard [2]. The same rule applies to either pattern: pick a partition key that keeps each entity's events together.

Duplicates push the work to consumers. The AWS Builders' Library pattern is a caller-supplied idempotency token, recorded atomically with the request and kept for the resource's lifetime plus a margin, so a replay returns the original result instead of repeating the effect [8].

A 2026 preprint argues there's no shortcut. It proves in Isabelle/HOL that any recovery policy using only source-side state must either duplicate an effect or drop one after some crash. It adds that bounded dedup state and truncated source history limit how long any exactly-once guarantee lasts [9] *(unreplicated; abstract only)*.

## Where it breaks: logs expire and snapshots cost

CDC depends on the log still being there. Wormhole's guarantees "do not hold if an update is not available in the datastore log," and its datastores typically kept 1–2 days; a subscriber that falls further behind gets a data-loss callback [2]. DBLog's authors note that transaction logs don't hold full history, so every CDC system also needs a way to capture full table state for bootstrap and repair [3] *(unreplicated)*.

That snapshot step has costs. In 2020, DBLog reported that Debezium's consistent snapshot used table locks, which on MySQL RDS could block writes until every row was selected. DBLog's watermark approach interleaves chunked selects with log events and takes no locks [3] *(unreplicated; tool behavior may have changed since)*.

An outbox avoids the snapshot question for events but not the recovery gap. Its relay checkpoint and the broker are still two durable steps, which is exactly the gap the preprint formalizes [9]. And an outbox only captures what code remembers to write. A migration script or manual fix that bypasses the application emits no event, while CDC on the tables would see it. That follows from the mechanisms in [1] and [2], not from a measured incident.

## Against the library

| Claim | Verdict | Library note |
|---|---|---|
| Outbox and log-based CDC both remove the dual write by deriving publication from the committed log | New | — |
| Outbox fits intent-bearing domain events you own; row-level CDC fits state replication from writers you can't change | New | — |
| Both deliver at-least-once with per-shard ordering, so consumers need idempotency tokens | New | — |
| Log retention bounds CDC recovery (1–2 days in Wormhole's deployment) and forces a separate snapshot path | New | — |
| Source-only recovery can't guarantee exactly-once across a crash | New | — |

The library had no notes here, so everything is New. These findings are its first baseline for event publishing.

## Open questions

- How much does coupling consumers to table schemas through CDC actually cost over time? No registry source measures it.
- Have current Debezium snapshot modes removed the locking cost DBLog described in 2020?
- What are typical outbox relay lag and outbox-table growth numbers? None of the sources give them.
- Will the exactly-once impossibility result hold up under peer review?

## Sources

1. Arslan Ahmad. "Transactional Outbox Pattern: How to Solve the Dual-Write Problem." *DesignGurus*, 2026. https://www.designgurus.io/blog/transactional-outbox-pattern — **T2**
2. Yogeshwer Sharma et al. "Wormhole: Reliable Pub-Sub to Support Geo-replicated Internet Services." *USENIX NSDI*, 2015. https://www.usenix.org/system/files/conference/nsdi15/nsdi15-paper-sharma.pdf — **T1**
3. Andreas Andreakis, Ioannis Papapanagiotou. "DBLog: A Watermark Based Change-Data-Capture Framework." *arXiv*, 2020. https://arxiv.org/abs/2010.12597 — **T3** · no published version found on arXiv; DBLP blocked the lookup
4. Martin Fowler. "Domain Event." *martinfowler.com*, 2005. https://martinfowler.com/eaaDev/DomainEvent.html — **T2**
5. Martin Fowler. "What do you mean by 'Event-Driven'?" *martinfowler.com*, 2017. https://martinfowler.com/articles/201701-event-driven.html — **T2**
6. Ian Cartwright, Rob Horn, James Lewis. "Event Interception." *Patterns of Legacy Displacement, martinfowler.com*, 2024. https://martinfowler.com/articles/patterns-legacy-displacement/event-interception.html — **T2**
7. Arslan Ahmad. "Change Data Capture 101: Keeping Systems in Sync in Real Time." *DesignGurus*, 2026. https://www.designgurus.io/blog/change-data-capture — **T2**
8. Malcolm Featonby. "Making retries safe with idempotent APIs." *Amazon Builders' Library*, n.d. https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/ — **T2**
9. Andreas Andreakis. "Machine-Checked Dual-Write Recovery from a Commit Log." *arXiv*, 2026. https://arxiv.org/abs/2608.00501 — **T3** · abstract only

## Filed

- New: [[transactional-outbox]] → `domains/software/architecture/transactional-outbox.md`
- New: [[log-based-change-data-capture]] → `domains/software/data/log-based-change-data-capture.md`
- New: [[at-least-once-event-delivery]] → `domains/software/reliability/at-least-once-event-delivery.md`
