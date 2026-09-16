---
title: Transactional outbox
domain: software
area: architecture
claim: Writing the event row in the same local transaction as the business change removes the dual write, at the cost of an outbox table, a relay, and at-least-once delivery.
confidence: medium
sources:
  - Arslan Ahmad, "Transactional Outbox Pattern: How to Solve the Dual-Write Problem", DesignGurus 2026 — https://www.designgurus.io/blog/transactional-outbox-pattern [T2]
  - Martin Fowler, "Domain Event", martinfowler.com 2005 — https://martinfowler.com/eaaDev/DomainEvent.html [T2]
  - Andreas Andreakis, "Machine-Checked Dual-Write Recovery from a Commit Log", arXiv 2026 — https://arxiv.org/abs/2608.00501 [T3, abstract only]
updated: 2026-09-16
from: investigations/2026-09-16-outbox-vs-cdc.md
related: [log-based-change-data-capture, at-least-once-event-delivery]
---

# Transactional outbox

A service that commits to its database and then publishes to a broker can crash between the two, leaving the systems disagreeing (Ahmad 2026). The outbox pattern closes that gap by inserting an event row into an outbox table inside the same ACID transaction as the business change. Either both rows exist or neither does (Ahmad 2026).

A separate relay then publishes outbox rows to the broker. It can poll the table, or a log-tailing CDC tool such as Debezium can read outbox inserts from the transaction log (Ahmad 2026). In the second form the outbox is CDC on a purpose-built table; see [[log-based-change-data-capture]].

The event is written by application code, so it can be a domain event: a record of something that happened that the business cares about, not just a changed row (Fowler 2005). That makes the outbox the natural fit when the event is a contract for other teams.

## Tradeoffs

Wins when you own the writing service, the store supports transactions, and consumers need intent-bearing events with a stable schema.

Costs: outbox table growth must be managed, the relay must be kept reliable, and delivery is at-least-once, so consumers must be idempotent (Ahmad 2026); see [[at-least-once-event-delivery]]. It doesn't fit stores without transactions or flows that need synchronous completion before responding (Ahmad 2026).

Relay delivery and the relay's checkpoint remain two separate durable steps. A preprint proves that recovery using only source-side state can't guarantee exactly-once across a crash (Andreakis 2026, *unreplicated*).

An outbox captures only what application code writes. Changes that bypass the application, such as migration scripts and manual fixes, emit no event. This is inferred from the mechanism, not measured.
