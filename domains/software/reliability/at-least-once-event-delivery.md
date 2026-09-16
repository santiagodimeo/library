---
title: At-least-once event delivery
domain: software
area: reliability
claim: Log-derived event pipelines deliver at-least-once and in order only within a shard, so consumers need idempotency and entities need a stable partition key.
confidence: medium
sources:
  - Yogeshwer Sharma et al., "Wormhole: Reliable Pub-Sub to Support Geo-replicated Internet Services", USENIX NSDI 2015 — https://www.usenix.org/system/files/conference/nsdi15/nsdi15-paper-sharma.pdf [T1]
  - Arslan Ahmad, "Transactional Outbox Pattern: How to Solve the Dual-Write Problem", DesignGurus 2026 — https://www.designgurus.io/blog/transactional-outbox-pattern [T2]
  - Malcolm Featonby, "Making retries safe with idempotent APIs", Amazon Builders' Library n.d. — https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/ [T2]
  - David Yanacek, "Avoiding insurmountable queue backlogs", Amazon Builders' Library 2019 — https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf [T2]
  - Andreas Andreakis, "Machine-Checked Dual-Write Recovery from a Commit Log", arXiv 2026 — https://arxiv.org/abs/2608.00501 [T3, abstract only]
updated: 2026-09-16
from: investigations/2026-09-16-outbox-vs-cdc.md
related: [transactional-outbox, log-based-change-data-capture, queue-leases-and-retries]
---

# At-least-once event delivery

Pipelines that derive events from a committed log, whether an outbox relay or CDC, redeliver after failures instead of losing updates. Outbox delivery is at-least-once, and duplicates are possible (Ahmad 2026). Wormhole guarantees at-least-once delivery and in-order delivery within a shard, with no ordering across shards (Sharma 2015). Per-shard order is enough when all updates for one entity live on the same shard (Sharma 2015).

Duplicates are handled at the receiver. The Builders' Library pattern has the caller supply a unique token. The service records it atomically with the request and returns a semantically equivalent response on replay, even if state has changed since. A reused token with different parameters is a validation error. Tokens are kept for the resource's lifetime plus a margin (Featonby n.d.).

An idempotency key skips a replay of a completed request, but the pattern doesn't cover a duplicate that arrives while the original is still running (Featonby n.d.). Queue redelivery after a timeout produces exactly that case (Yanacek 2019). Pair the key with a lease or heartbeat so a second attempt can't start while the first holds the job; this follows from the two sources, neither states it. See [[queue-leases-and-retries]].

## Tradeoffs

At-least-once plus idempotent receivers is the practical ceiling. A preprint proves in Isabelle/HOL that any recovery policy using only source-side state must duplicate or drop an effect after some crash. Correct recovery needs an authoritative, current record of what the sink accepted, and bounded dedup state or truncated source history limit how long the guarantee lasts (Andreakis 2026, *unreplicated*).

Dedup state isn't free. Its retention window must outlast the longest plausible redelivery delay, and for log-based sources that delay is bounded by log retention (inferred from the mechanism); see [[log-based-change-data-capture]].

Cross-shard order is not guaranteed (Sharma 2015). Choose the partition key so that events a consumer must apply in order share a shard.
