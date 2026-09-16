# Index

Every note in the library, one line each: `- [Title](path) — the claim`.
`/research` keeps this current. Empty areas are omitted until they hold a note.

## Software

### architecture

- [Transactional outbox](domains/software/architecture/transactional-outbox.md) — writing the event row in the business transaction removes the dual write, at the cost of a relay and at-least-once delivery

### data

- [Log-based change data capture](domains/software/data/log-based-change-data-capture.md) — tailing the transaction log publishes every commit without touching writers, bounded by log retention and a separate snapshot path
- [Postgres job queues](domains/software/data/postgres-job-queues.md) — SKIP LOCKED queues hold up only with short claim transactions, per-table autovacuum, and retention by dropping time partitions
- [RDS Proxy connection pinning](domains/software/data/rds-proxy-connection-pinning.md) — session state pins proxy connections, and a default asyncpg pool reset likely pins every one

### reliability

- [At-least-once event delivery](domains/software/reliability/at-least-once-event-delivery.md) — log-derived pipelines redeliver and order only per shard, so consumers need idempotency tokens and a stable partition key
- [Queue leases and retries](domains/software/reliability/queue-leases-and-retries.md) — leases or heartbeats, timeouts from a false-timeout rate, retries at one layer under a budget, and a dead-letter cap
- [Multi-tenant queue fairness](domains/software/reliability/multi-tenant-queue-fairness.md) — per-tenant caps, rate limits, spillover lanes and backlog age stop one tenant's bulk work starving the rest
- [Autoscaling queue workers](domains/software/reliability/autoscaling-queue-workers.md) — scale on backlog per task, protect in-flight tasks from scale-in, and plan for Spot interruptions protection doesn't cover
- [Load testing, open vs closed](domains/software/reliability/load-testing-open-vs-closed.md) — match the arrival model, push past breaking, and sample real latency distributions or tails are understated

### security

- [Sensitive data in logs](domains/software/security/sensitive-data-in-logs.md) — statement logging captures bound values in full by default; stop the source, set retention with minimums and holds, clean up what's there

### ai-systems

- [LLM API throughput limits](domains/software/ai-systems/llm-api-throughput-limits.md) — org-level token limits and the spend cap bind before client infrastructure; caching and batches are the levers

## Hardware

## Philosophy

## Design

### interaction

- [Alert fatigue and batching](domains/design/interaction/alert-fatigue-and-batching.md) — repeated alerts lose acceptance measurably; a digest beats both real-time floods and silence

## Biology
