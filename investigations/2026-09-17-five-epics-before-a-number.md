---
title: Five epics before a number
question: What has to change in the analysis pipeline before a throughput test produces a number worth trusting, and in what order?
date: 2026-09-17
domains: [software]
confidence: High — four T1/T2 sources read directly, and the library already held the baseline for every claim
read_time: 7 min
layout: software-S2
repo: euphony
artifact: https://claude.ai/artifact/RmUwzq3vCTpRgGhvY4MzHN
---

# Five epics before a number

A throughput test measures whatever the harness lets it measure. Run one against the pipeline as it stands and the number will be a closed-loop average of a system that also serves open traffic, taken while one tenant can starve the rest and a timed-out job runs twice. The five epics below are ordered by what makes the measurement honest first and what makes it larger second: the harness, fair scheduling, lease-and-retry correctness, elasticity on the right metric, and the write path. Only the fourth is about adding capacity. What would change this order is a measured service-time distribution, which we do not have yet.

17 Sep 2026 · 7 min · confidence **High**, four T1/T2 sources read directly · software · repo **euphony**

## What the evidence says:

### A closed-loop test describes a system nobody runs

Workload generators are either closed, where a new request arrives only after the last one completes, or open, where arrivals are independent of completions [3]. The distinction is not academic. For a fixed load, "the mean response time for an open system model can exceed that for a closed system model by an order of magnitude or more", and the gap persists even at a multiprogramming level of 1000 [3]. Service-time variability "has a huge impact on response times in open systems" and much less in closed ones [3].

Both shapes exist in our pipeline. A backfill is closed: workers pull the next job when the last finishes. Upload and interactive analysis are open: they arrive when a customer sends them. A harness that only drives a backfill will understate the tail that interactive users see, and a mock returning a constant delay removes the variability that drives the open-system result [3].

The same paper undercuts a tempting shortcut. Scheduling policy barely matters in a closed system but produces "more than a factor of ten improvement" in an open one under high load [3]. Any fairness work we do will look pointless in a closed-loop test and decisive in an open one.

### Fairness is a concurrency cap, not an ordering rule

Per-tenant ordering is the obvious fix for one customer's backfill blocking everyone, and it is not sufficient. AWS's fairness mechanism is "per-customer rate-based limits, with some flexibility for bursting", which serve as guardrails for unexpected spikes and buy time to provision behind the scenes [2]. A rate limit bounds how much of the system a tenant can hold; ordering only interleaves what they already queued.

The cost of getting this wrong is measured in hours, not minutes. If a spike goes unthrottled for the 30 minutes it takes an operator to notice and mitigate, and the queued volume is 10× consumer capacity, "it would take 300 minutes for the system to work through the backlog and recover" [2]. Even short spikes become multi-hour outages [2].

### A timed-out job that keeps running turns load into more load

When processing time crosses the visibility timeout, the message is redelivered while the first attempt is still running, which "causes an already overloaded service to essentially fork-bomb itself" [2]. The recommended fix is heartbeating long-running work, not a longer deadline [2].

Our shape is the same with different names. The analysis service abandons a cascade call after its timeout, but abandoning an HTTP request is not cancellation: the callee keeps working unless it checks for a disconnect. The retry then re-runs the whole conversation while the first attempt still holds its resources. Dead-letter volume is worth alarming on, but it "would arrive too late for us to rely on it exclusively to detect problems" [2], so the lease and the retry budget have to carry the load.

### Scaling on queue depth is scaling on the wrong metric

Target tracking assumes the metric falls as capacity rises. Queue depth does not: "the number of messages in the queue might not change proportionally to the size of the Auto Scaling group" [1]. The documented metric is backlog per instance — queue depth divided by running capacity — with the target set to acceptable latency divided by per-message processing time. AWS's worked example: 10 seconds of acceptable latency ÷ 0.1 seconds per message = a target of 100, against a current backlog per instance of 1500 ÷ 10 = 150, which scales out by five [1].

Two consequences for us. Our deploy tool can only point a policy at a single published metric, so the ratio has to be computed and published deliberately, or we scale on CPU and accept the lag. And the target value is a function of per-job processing time, which is exactly the number the harness in the first epic exists to produce. Scaling policy is downstream of measurement, not parallel to it.

### The database is the next bottleneck, and a proxy might not move it

More workers means more connections, and RDS Proxy is the standard answer. It only pays off while sessions carry no state. For PostgreSQL the proxy pins a connection on `SET`, on `PREPARE`/`DISCARD`/`DEALLOCATE`/`EXECUTE`, on temporary tables, sequences and cursors, on `LISTEN`, on library loads, on `nextval`/`setval`, on advisory locks, and on any statement whose text exceeds 16 KB [4]. Pinning means "each later transaction uses the same underlying database connection until the session ends" [4].

The trap is in the pool, not the application code. AWS calls out connection-pooling libraries that use a discard query as a reset: with `DISCARD ALL` configured, "RDS Proxy pins your client connection on release" [4]. Our driver's default reset runs an advisory unlock and `RESET ALL`, both on the pinning list. Shrinking pools is free and reversible; a proxy bought before checking `DatabaseConnectionsCurrentlySessionPinned` may deliver nothing [4].

## Cons, and what to do about them:

**Five epics is a lot of engineering to justify with no measurement in hand.**
True, and the order already answers it: the harness is first and runs against today's code. *Mitigation:* treat epics two through five as funded by what the first one shows, and cap the harness at a mock, two generators and a metrics pass.

**A mocked dependency measures our pipeline, not our product.**
The number will describe queueing, scheduling and writes, with the slowest real component replaced by a stand-in. *Mitigation:* sample the mock's delays from a measured distribution rather than a constant [3], give it the real thing's refusal behavior, and label every result as pipeline-only.

**Scale-in protection, which keeps autoscaling from killing in-flight jobs, blocks rolling deployments while it is set.**
A worker that protects itself for the length of a long job also holds up a deploy. *Mitigation:* set protection per job rather than per task lifetime, and bound it to the job's own timeout.

**Retention by partition needs a schema change on tables that have no migration tool.**
The tables that grow fastest are the ones hardest to restructure in place. *Mitigation:* partition forward from a cutover date and leave existing rows where they are; drop old partitions rather than deleting rows.

## How it actually works:

```
open arrivals ──────┐                 ┌── interactive lane ──┐
(uploads, API)      ├──► job queue ───┤                      ├──► workers ──► mock
closed loop ────────┘   fair claim    └── bulk lane ─────────┘   lease +      (sampled
(backfill pull)         per tenant                               heartbeat     delays)
                            │                                        │
                            └── backlog ÷ running tasks ─────────────┴──► scaling policy
                                (the published metric)
```

The harness drives both arrival shapes at once because they behave differently [3]. The lanes and the per-tenant claim decide who waits. The published ratio, not raw depth, is what a scaling policy can track [1].

## What this settles, and what it doesn't:

### Settled

- **Two generators, not one.** Open and closed arrivals differ in mean response time by an order of magnitude at the same load [3].
- **Backlog per task is the scaling metric.** Raw depth doesn't move inversely with capacity, and the target is acceptable latency ÷ per-job time [1].
- **A lease beats a longer timeout.** Redelivery during a running attempt is the documented way an overloaded queue system multiplies its own load [2].
- **Pinning can erase a proxy's benefit**, and a pool reset that discards session state is a documented cause [4].

### Not settled

- **Our per-job service time and its variability.** Every target value above is a function of it; no source can supply ours.
- **Whether per-tenant ordering plus a concurrency cap is enough at our volumes.** Follows from [2] and the library note; no source measures this shape.
- **Whether our driver actually pins.** The two doc pages make it likely, not certain; the metric settles it in one run [4].

## Against the library:

| Claim | Verdict | Library note |
|---|---|---|
| Per-tenant ordering makes the queue fair | Conflicts | `multi-tenant-queue-fairness` — caps, rate limits and per-tenant backlog, not ordering alone |
| Raising the dispatch timeout past the callee's worst case fixes double-running | Conflicts | `queue-leases-and-retries` — a bigger timeout moves the threshold; leases and heartbeats remove it |
| Scale workers on pending queue depth | Conflicts | `autoscaling-queue-workers` — backlog per task, target from latency ÷ processing time |
| RDS Proxy is the answer to connection pressure | Conflicts | `rds-proxy-connection-pinning` — a default asyncpg reset likely pins every connection |
| Mock the model with fixed delays | Extends | `load-testing-open-vs-closed` — variability drives open-system response time |
| Delete old jobs on a schedule | Extends | `postgres-job-queues` — DELETE creates the vacuum load; drop partitions instead |
| Statement logging captures conversation text | Confirms | `sensitive-data-in-logs` — bind values logged in full by default |

Four of our planned moves were wrong in the same direction: each treated a scheduling or capacity problem as a knob when the source calls for a mechanism. The belief that moved most is about the proxy — it was on the roadmap as a dependency for scaling out, and it may be a no-op until the pool reset changes.

## Open questions:

- What is the service-time distribution per job, and how heavy is its tail? Every target value depends on it.
- Is the client's real traffic open, closed, or partly open? The paper's convergence depends on requests per session [3].
- Does our claim transaction stay short enough under load to keep vacuum ahead of the queue table?
- What per-tenant concurrency cap is low enough to protect others and high enough to finish a backfill in the promised window?

## Sources:

1. AWS. "Scaling policy based on Amazon SQS." *Amazon EC2 Auto Scaling User Guide*, n.d. https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-using-sqs-queue.html — **T2**
2. David Yanacek. "Avoiding insurmountable queue backlogs." *Amazon Builders' Library*, 2019. https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf — **T2**
3. Bianca Schroeder, Adam Wierman, Mor Harchol-Balter. "Open Versus Closed: A Cautionary Tale." *USENIX NSDI*, 2006. https://www.usenix.org/legacy/event/nsdi06/tech/full_papers/schroeder/schroeder.pdf — **T1**
4. AWS. "Avoiding pinning an RDS Proxy." *Amazon RDS User Guide*, n.d. https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html — **T2**

## Filed

- Updated: [[queue-leases-and-retries]] — an abandoned HTTP call is not cancellation; the callee keeps running
- Updated: [[autoscaling-queue-workers]] — what to do when the platform has no metric math for backlog per task
- Layout: software-S2
