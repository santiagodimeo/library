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
- [Subprocess argument injection](domains/software/security/subprocess-argument-injection.md) — an argv API removes command injection but not argument injection, so driving external tools still needs an allowlist of commands and per-argument validation
- [Memory safety in input handling](domains/software/security/memory-safety-in-input-handling.md) — memory defects concentrate in parsers and outlive other classes by years; the lever is the input-handling design, not the sanitizer

### languages-runtimes

- [Shell as a correctness substrate](domains/software/languages-runtimes/shell-as-a-correctness-substrate.md) — every widely used shell diverges from POSIX in known ways and scripts resist static analysis, so shell is a bad host for a predicate that must hold

### ai-systems

- [LLM API throughput limits](domains/software/ai-systems/llm-api-throughput-limits.md) — org-level token limits and the spend cap bind before client infrastructure; caching and batches are the levers
- [Deterministic mediation of agents](domains/software/ai-systems/deterministic-mediation-of-agents.md) — constraints hold only when a non-bypassable component outside the model enforces them; in-model defenses break and approval prompts decay
- [MCP stdio server surface](domains/software/ai-systems/mcp-stdio-server-surface.md) — newline-delimited JSON-RPC on a pipe with a hard stdout rule, which keeps the surface small and makes every spawned subprocess a correctness hazard
- [Agent tool context budget](domains/software/ai-systems/agent-tool-context-budget.md) — every reachable tool definition is a standing token cost and a selection-accuracy cost unless the host defers it

## Hardware

## Philosophy

## Design

### interaction

- [Alert fatigue and batching](domains/design/interaction/alert-fatigue-and-batching.md) — repeated alerts lose acceptance measurably; a digest beats both real-time floods and silence

## Biology
