---
title: LLM API throughput limits
domain: software
area: ai-systems
claim: For a client of a hosted LLM API, the throughput ceiling is usually the provider's org-level rate limits and spend cap, not the client's own infrastructure; caching and batch processing are the main levers.
confidence: high
sources:
  - Anthropic, "Rate limits", Claude Platform docs n.d. — https://platform.claude.com/docs/en/api/rate-limits [T2]
  - Anthropic, "Claude API errors", Claude Platform docs n.d. — https://platform.claude.com/docs/en/api/errors [T2]
  - Anthropic, "Batch processing", Claude Platform docs n.d. — https://platform.claude.com/docs/en/build-with-claude/batch-processing [T2]
  - Anthropic, "Prompt caching", Claude Platform docs n.d. — https://platform.claude.com/docs/en/build-with-claude/prompt-caching [T2]
  - Anthropic, "Service tiers", Claude Platform docs n.d. — https://platform.claude.com/docs/en/api/service-tiers [T2]
updated: 2026-09-16
from: a private investigation
related: [queue-leases-and-retries, load-testing-open-vs-closed]
---

# LLM API throughput limits

Anthropic enforces limits per organization and per model class: requests, input tokens and output tokens per minute. The limiter is a token bucket, and a per-minute limit may be enforced over shorter windows, so bursts get 429s (Anthropic n.d. a). A sharp rise in usage can also trip acceleration limits; the docs say to ramp gradually (Anthropic n.d. a). Figures fetched 2026-09-16 for Sonnet 4.x and Haiku 4.5: 1,000 / 2M / 400K at Start, 5,000 / 5M / 1M at Build, 10,000 / 10M / 2M at Scale (Anthropic n.d. a).

Only uncached input and cache writes count toward input-token limits on most current models, so caching raises effective throughput (Anthropic n.d. a). The minimum cacheable prefix is 1,024 tokens on Sonnet 4.5 and 4,096 on Haiku 4.5, shorter prefixes silently don't cache, and an entry is usable only after the first response begins, so fully parallel calls can't share a cache (Anthropic n.d. d).

Each usage tier has a monthly spend cap ($500 / $1,000 / $200,000). Hitting it returns a 429 with no `retry-after`, and retries fail until the next month (Anthropic n.d. a). A 529 means provider-wide overload, not your limits; SDKs retry twice by default (Anthropic n.d. b).

## Tradeoffs

- Message Batches: 50% off, up to 100,000 requests per batch, most done within an hour, unfinished ones expire at 24 h. Batches have their own queue limits (200K / 300K / 500K requests in processing by tier) (Anthropic n.d. a; n.d. c). Right for backfills, wrong for anything a user waits on.
- Priority Tier commitments are no longer sold; guaranteed capacity goes through sales (Anthropic n.d. e).
- A load test with a mocked model can't see any of this. See [[load-testing-open-vs-closed]].
