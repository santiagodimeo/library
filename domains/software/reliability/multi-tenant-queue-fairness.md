---
title: Multi-tenant queue fairness
domain: software
area: reliability
claim: A single shared queue lets one tenant's bulk work starve everyone else; fairness takes per-tenant concurrency caps and rate limits, a spillover lane, and per-tenant backlog age, with interactive work scheduled ahead of batch.
confidence: high
sources:
  - David Yanacek, "Avoiding insurmountable queue backlogs", Amazon Builders' Library 2019 — https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf [T2]
  - Jeffrey Dean, Luiz André Barroso, "The Tail at Scale", Communications of the ACM 2013 — https://www.barroso.org/publications/TheTailAtScale.pdf [T2]
  - AWS, "Amazon SQS fair queues", SQS Developer Guide n.d. — https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-fair-queues.html [T2]
  - AWS, "Amazon SQS introduces fair queues for multi-tenant workloads", What's New 2025 — https://aws.amazon.com/about-aws/whats-new/2025/07/amazon-sqs-introduces-fair/ [T2]
updated: 2026-09-16
from: a private investigation
related: [queue-leases-and-retries, postgres-job-queues, autoscaling-queue-workers]
---

# Multi-tenant queue fairness

"A single queue and multitenancy are at odds" (Yanacek 2019). Ordering by global age means one tenant's burst sits in front of everyone. The recovery math is harsh: a 30-minute noisy-neighbor backlog at 10× capacity takes 300 minutes to drain (Yanacek 2019).

The Builders' Library toolkit (Yanacek 2019):
- A rate limit per tenant that allows bursts, with excess moved to a spillover lane rather than just ordered behind.
- A concurrency cap per workload, so a tenant can't hold most worker slots even if its jobs are individually "fair".
- Backlog measured per tenant. A shared queue has no per-attribute depth, so shared backpressure lands on innocent tenants.

Scheduling interactive requests ahead of non-interactive ones is one of the standard ways to cut tail latency; background work causes periodic latency spikes for everyone else (Dean 2013).

## Tradeoffs

- Ordering "oldest few per tenant" helps, but without a concurrency cap a tenant with many jobs still takes most slots. This follows from Yanacek 2019; no source measures it.
- A SQL-backed queue can compute per-tenant depth and age directly, which is one real argument for it over a broker (inference).
- Amazon SQS added fair queues for standard queues in July 2025. Setting `MessageGroupId` to a tenant ID enables it with no consumer change and no throughput limit. It shortens wait time for quiet tenants but doesn't cap any tenant's consumption (AWS 2025; AWS n.d.). "Brokers have no fairness" is no longer true.
