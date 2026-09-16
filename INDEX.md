# Index

Every note in the library, one line each: `- [Title](path) — the claim`.
`/research` keeps this current. Empty areas are omitted until they hold a note.

## Software

### architecture

- [Transactional outbox](domains/software/architecture/transactional-outbox.md) — writing the event row in the business transaction removes the dual write, at the cost of a relay and at-least-once delivery

### data

- [Log-based change data capture](domains/software/data/log-based-change-data-capture.md) — tailing the transaction log publishes every commit without touching writers, bounded by log retention and a separate snapshot path

### reliability

- [At-least-once event delivery](domains/software/reliability/at-least-once-event-delivery.md) — log-derived pipelines redeliver and order only per shard, so consumers need idempotency tokens and a stable partition key

## Hardware

## Philosophy

## Design

## Biology
