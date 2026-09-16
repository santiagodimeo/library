---
title: Alert fatigue and batching
domain: design
area: interaction
claim: Repeated, non-actionable notifications get ignored at measurable rates, and batching them into a digest preserves attention better than either real-time delivery or silence.
confidence: medium
sources:
  - Ancker JS et al., "Effects of workload, work complexity, and repeated alerts on alert fatigue in a clinical decision support system", BMC Medical Informatics and Decision Making 2017 — https://pmc.ncbi.nlm.nih.gov/articles/PMC5387195/ [T1]
  - Fitz N. et al., "Batching smartphone notifications can improve well-being", Computers in Human Behavior 2019 — doi:10.1016/j.chb.2019.07.016 [T1, abstract only]
  - Beyer et al., "Monitoring Distributed Systems", Site Reliability Engineering 2016 — https://sre.google/sre-book/monitoring-distributed-systems/ [T2]
  - Kate Flaherty, "Indicators, Validations, and Notifications", Nielsen Norman Group 2024 — https://www.nngroup.com/articles/indicators-validations-notifications/ [T2]
  - Slack, "Rate limits", Slack Developer Docs n.d. — https://docs.slack.dev/apis/web-api/rate-limits/ [T2]
updated: 2026-09-16
from: a private investigation
related: [load-testing-open-vs-closed]
---

# Alert fatigue and batching

In a retrospective cohort of 112 clinicians and about 1.27 million decision-support alerts, acceptance dropped 30% for each additional reminder in an encounter, and fell as the share of repeated reminders rose (Ancker 2017). It's a clinical setting, so treat it as an analog for software alerts, not a direct measurement.

A randomized field experiment (n=237) found that batching phone notifications three times a day improved attention and well-being, while turning notifications off entirely raised anxiety and fear of missing out (Fitz 2019, abstract only).

Practitioner guidance agrees. The SRE book says "every page should be actionable", and noisy alerting teaches people to ignore alerts (Beyer 2016). NN/g notes that a notification unrelated to the user's current goal is likely to be ignored (Flaherty 2024).

## Tradeoffs

- Digest, not silence: batch bulk or backfill events into a summary, and collapse repeats per subject or rule. That follows from Ancker 2017 and Fitz 2019.
- Delivery channels have their own ceilings. Slack allows about one message per second per channel or incoming webhook, with short bursts, and returns 429 with `Retry-After` beyond that (Slack n.d.). A sustained real-time stream above that rate falls behind before anyone reads it.
- At-least-once processing can re-detect and re-send the same alert; dedupe per event (inference). See [[at-least-once-event-delivery]].
