---
title: Load testing, open vs closed
domain: software
area: reliability
claim: A load test must match how load arrives — closed loops for worker-driven batch, open arrivals for user traffic — and push past the breaking point with realistic latency distributions, or it will understate tail latency by as much as an order of magnitude.
confidence: high
sources:
  - Bianca Schroeder, Adam Wierman, Mor Harchol-Balter, "Open Versus Closed: A Cautionary Tale", USENIX NSDI 2006 — https://www.usenix.org/legacy/event/nsdi06/tech/full_papers/schroeder/schroeder.pdf [T1]
  - David Yanacek, "Using load shedding to avoid overload", Amazon Builders' Library 2019 — https://d1.awsstatic.com/builderslibrary/pdfs/using-load-shedding-to-avoid-overload.pdf [T2]
  - Beyer et al., "Monitoring Distributed Systems", Site Reliability Engineering 2016 — https://sre.google/sre-book/monitoring-distributed-systems/ [T2]
  - Jeffrey Dean, Luiz André Barroso, "The Tail at Scale", Communications of the ACM 2013 — https://www.barroso.org/publications/TheTailAtScale.pdf [T2]
updated: 2026-09-16
from: a private investigation
related: [llm-api-throughput-limits, multi-tenant-queue-fairness]
---

# Load testing, open vs closed

In a closed system, a fixed set of clients waits for each response before sending the next request. In an open system, requests arrive on their own schedule. At the same load, mean response time in an open system "can exceed that for a closed system model by an order of magnitude or more", and variability in service time matters far more there (Schroeder 2006). Scheduling policy helps open systems a lot and closed systems little. A partly-open system behaves open at five or fewer requests per session and closed at ten or more (Schroeder 2006).

A backfill driven by workers pulling jobs is close to closed. Interactive traffic is open. Testing both with a closed-loop generator hides the tail interactive users will see (inference from Schroeder 2006).

Test "far beyond the point where it breaks" and check that goodput plateaus instead of collapsing (Yanacek 2019). Report latency as histograms, not averages; an average of 100 ms can hide 1% of requests at 5 s (Beyer 2016).

## Tradeoffs

- Mock slow dependencies with latencies sampled from measured distributions, not constants (inference from Schroeder 2006's variability result).
- When the real dependency is rate-limited, the mock should be too: a token bucket with the provider's limits, 429s with retry hints, and occasional overload errors (inference). See [[llm-api-throughput-limits]].
- Run background maintenance like retention deletes and vacuum during the test; it causes periodic latency spikes in production (Dean 2013).
