---
title: Queue leases and retries
domain: software
area: reliability
claim: Queue workers need leases or heartbeats, a timeout set from an accepted false-timeout rate, retries at exactly one layer under a budget, and a dead-letter cap — otherwise an overloaded system multiplies its own load.
confidence: high
sources:
  - David Yanacek, "Avoiding insurmountable queue backlogs", Amazon Builders' Library 2019 — https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf [T2]
  - Marc Brooker, "Timeouts, retries, and backoff with jitter", Amazon Builders' Library 2020 — https://d1.awsstatic.com/builderslibrary/pdfs/timeouts-retries-and-backoff-with-jitter.pdf [T2]
  - David Yanacek, "Fairness in multi-tenant systems", Amazon Builders' Library 2019 — https://d1.awsstatic.com/builderslibrary/pdfs/fainess-in-multi-tenant-systems-david-yanacek.pdf [T2]
  - Google, "Addressing Cascading Failures", Site Reliability Engineering 2016 — https://sre.google/sre-book/addressing-cascading-failures/ [T2]
updated: 2026-09-17
from: a private investigation
related: [postgres-job-queues, at-least-once-event-delivery, multi-tenant-queue-fairness, llm-api-throughput-limits]
---

# Queue leases and retries

When processing time crosses a queue's visibility timeout, the message becomes visible again while the first attempt still runs. An already overloaded service then does the same work twice and "essentially fork-bomb[s] itself" (Yanacek 2019a). The fix is a lease the worker extends by heartbeat, and a worker that stops once its lease is gone. A bigger timeout alone only moves the threshold.

Set timeouts from the false-timeout rate you accept: 0.1% maps to the downstream p99.9 latency (Brooker 2020).

Retry at a single point in the stack. Five layers each retrying three times put 243× the load on the bottom layer (Brooker 2020). An SDK's built-in retries inside a job system's retries is the same stack. Cap retries per request, keep a server-wide retry budget (a token bucket, or the SRE book's "60 retries per minute"), and use randomized exponential backoff (Brooker 2020; Google 2016).

When a dependency returns rate-limit errors, an asynchronous system should apply backpressure and slow down, since retrying ties up more resources (Yanacek 2019b).

## Tradeoffs

- Cap attempts and move poison jobs to a dead-letter lane with its own alarm. Without a cap they cycle forever (Yanacek 2019a).
- Track age of first attempt separately from retries, so retries don't hide a growing backlog (Yanacek 2019a).
- Idempotency keys skip completed replays but not a duplicate still in flight; see [[at-least-once-event-delivery]].
- The same shape appears without a broker: an HTTP client that gives up on a call has not cancelled it. The callee keeps working unless it checks for a disconnect, so a retry runs the job twice while the first attempt still holds its resources — the fork-bomb case in HTTP clothing (inference from Yanacek 2019a). A caller-side deadline needs a callee-side abort or an idempotency key to match it.
