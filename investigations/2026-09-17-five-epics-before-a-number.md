---
title: Five epics before a number
question: What has to change in the analysis pipeline before a throughput test produces a number worth trusting, and in what order?
date: 2026-09-17
domains: [software]
confidence: High — four T1/T2 sources read directly, and the library already held the baseline for every claim
read_time: 6 min
layout: software-S1
repo: euphony
artifact: https://claude.ai/artifact/RmUwzq3vCTpRgGhvY4MzHN
---

# Five epics before a number

We want to know how many conversations our analysis pipeline can process per hour. Nobody has ever measured it. The tempting move is to point a load generator at it and read the result, but the pipeline has four habits that would make that number wrong — and fixing them is most of the work. So the proposal is one epic in six parts: build an honest measurement first, then fix what the measurement will expose. What would change the plan is a measured service time per job, which is exactly what the first part produces.

17 Sep 2026 · 6 min · confidence **High**, four sources read directly · software · repo **euphony**

## TL;DR:

- A load test measures whatever the harness allows. Ours would currently measure a system nobody actually runs, so the harness is the first piece of work, not the last.
- Customers arrive whenever they like; a backfill arrives as fast as workers can pull it. These two patterns differ by up to **10× in response time** at the same load, so we test both.
- Taking turns between customers is not fairness. Without a cap on how much of the system one customer can hold, a big backfill still blocks everyone.
- When we give up waiting on a slow step, it keeps running. A retry then does the same work twice. Under load this makes the system slower the busier it gets.
- We planned to add a database connection pooler. Vendor docs say it probably does nothing for us until we change one setting — a ten-minute check before spending anything.

## Why this question is live:

The first client is expected to send millions of conversations. We cannot currently say whether that takes a week or six months, what it costs, or whether other customers notice while it runs.

The obvious answer — run a load test, read the number — fails for a specific reason. What the test reports depends on how work arrives, who else is waiting, and what happens when something is slow. All three are unsettled today, so the number would measure something real and still be useless as a promise to a customer.

## What the evidence says:

### A test that only mimics a backfill hides what customers feel

Load generators come in two shapes. In a **closed** one, a fixed set of workers each start their next job only when the last finishes — that is a backfill. In an **open** one, work arrives on its own schedule regardless of whether we finished the last piece — that is a customer uploading a file.<sup>3</sup>

Treating one as the other is not a rounding error. At the same load, average response time in an open system "can exceed that for a closed system model by an order of magnitude or more", and how much jobs vary in size matters enormously in the open case and little in the closed one.<sup>3</sup> Our pipeline is both at once, so the harness drives both shapes, and the stand-in for the slow model step returns varied delays rather than a constant.

*This becomes S1, the harness.*

### Fairness is a cap, not a turn-taking rule

The natural fix for one customer's backfill blocking everyone is to serve customers in rotation. That helps, and it is not enough: rotation decides the order, not how much of the system one customer can occupy. The industry answer is a per-customer rate limit with room to burst, which acts as a guardrail and buys time to add capacity.<sup>2</sup>

The cost of skipping it is measured in hours. If a burst goes unchecked for the 30 minutes it takes someone to notice and react, and the queued work is ten times what the system can process, "it would take 300 minutes for the system to work through the backlog and recover".<sup>2</sup>

*This becomes S2, fair claiming and a separate lane for bulk work.*

### A step we stopped waiting for is still running

Our analysis service gives each conversation 60 seconds, then gives up and retries. Giving up on a network call does not stop the work on the other side: it keeps going until it finishes. The retry starts the same conversation again while the first attempt still holds its resources.

When processing time crosses the point where work is handed out again, it "causes an already overloaded service to essentially fork-bomb itself".<sup>2</sup> The fix is not a longer deadline, which only moves the line, but a signal from the worker that it is still alive plus a retry that waits longer each time.

*This becomes S3, leases and backoff, followed by S4, which lets a worker take new work as soon as a slot frees instead of waiting for its whole batch.*

### Adding servers on the wrong signal adds the wrong number of servers

Automatic scaling works by watching one number and assuming it falls as capacity rises. Pending queue length does not behave that way, and AWS names it as the wrong choice: "the number of messages in the queue might not change proportionally to the size of the Auto Scaling group".<sup>1</sup>

The metric that does work is backlog per worker — queue length divided by how many workers are running — with the target set to the delay we can accept divided by how long one job takes. AWS's worked example: 10 seconds of acceptable delay ÷ 0.1 seconds per job = a target of 100.<sup>1</sup>

Both halves of that formula come from measurement. That is the strongest argument for building the harness first: without it, the scaling configuration is a guess wearing a number.

*This becomes S5, elasticity.*

### The database is the next wall, and the planned fix may be a no-op

More workers means more database connections, and the standard remedy is a pooler that shares them. It only works while a connection carries no leftover state; for PostgreSQL the pooler stops sharing — "pins" — on ordinary operations like setting a parameter, preparing statements, or any statement over 16 KB.<sup>4</sup>

The catch is our settings, not our code. AWS calls out pooling libraries that clear session state on release: with that configured, "RDS Proxy pins your client connection on release".<sup>4</sup> Our driver's default does exactly that, so the pooler we planned as a prerequisite may share nothing. Shrinking the pools is free, and one metric answers the question.

*This becomes S6 plus a pool-sizing change inside S5.*

## How it actually works:

```
open arrivals ──────┐                 ┌── interactive lane ──┐
(uploads, API)      ├──► job queue ───┤                      ├──► workers ──► mock
closed loop ────────┘   fair claim    └── bulk lane ─────────┘   lease +      (varied
(backfill pull)         per customer                             heartbeat     delays)
                            │                                        │
                            └── backlog ÷ running workers ───────────┴──► scaling policy
```

Both arrival shapes run at once because they behave differently. The lanes and the per-customer claim decide who waits. The published ratio, not raw queue length, is what a scaling policy can follow.

## The epics this becomes:

- **S1 — Harness.** A mock for the slow step, both generators, and a run report: completions per minute, how many finished first try, and latency percentiles. Changes no production code.
- **S2 — Fair claiming and a bulk lane.** Oldest few per customer, a cap on how much one customer can hold, and backfills marked as bulk.
- **S3 — Leases and backoff.** A worker signals it is alive; retries wait longer each time; a repeated request is recognized and skipped.
- **S4 — Continuous claiming.** Take new work when a slot frees rather than waiting for the whole batch. Same files as S3, so the same owner does it next.
- **S5 — Elasticity.** Publish backlog per worker, scale on it, and size the connection pools to fit the database.
- **S6 — Queue durability.** Retention by dropping old partitions rather than deleting rows, a smaller index over pending work, and explicit cleanup settings.

Two items sit outside the epic on purpose. Database statement logging currently captures conversation text into logs that never expire — a data-protection fix that must not wait on performance work. And the connection pooler stays unbuilt until the pinning check says it would help.

## What you get from believing this:

- **A number you can put in front of a customer.** This is the one that matters: the others are how you get it honestly.
- **A backfill that no longer freezes everyone else.** Fairness work is invisible in a closed-loop test and decisive in real traffic.
- **A cheap test loop.** With the model mocked, a full run costs a few hours of compute rather than a large model bill.

Anyone running a handful of conversations a day gains nothing here. The value arrives with volume.

## What this settles, and what it doesn't:

### Settled

- **Two generators, not one.** Open and closed arrivals differ in mean response time by an order of magnitude at the same load.<sup>3</sup>
- **Backlog per worker is the scaling signal.** Queue length does not fall proportionally with capacity.<sup>1</sup>
- **A liveness signal beats a longer timeout.** Re-handing out work that is still running is the documented way an overloaded queue multiplies its own load.<sup>2</sup>
- **A pooler can share nothing.** A session-clearing pool reset is a documented cause of pinning.<sup>4</sup>

### Not settled

- **Our own service time per job and how much it varies.** Every target above depends on it; no source can supply ours.
- **Whether rotation plus a cap is enough at our volumes.** This follows from [2] and the library note; no source measures our shape.
- **Whether our driver actually pins connections.** The docs make it likely, not certain; one metric settles it.<sup>4</sup>

## Cons, and what to do about them:

**Six streams is a lot of work to justify with no measurement in hand.**
Fair, and the order answers it: S1 runs against today's code and produces the number. *Mitigation:* fund S2 through S6 on what S1 shows, and keep S1 to a mock, two generators and a metrics pass.

**A mocked model measures our plumbing, not our product.**
The result describes queueing, scheduling and database writes, with the slowest real component replaced. *Mitigation:* draw the mock's delays from a measured distribution,<sup>3</sup> give it the real component's refusal behaviour, and label every result as plumbing-only.

**Protecting a busy worker from shutdown also blocks deployments.**
A worker that refuses to stop mid-job will hold up a rolling deploy. *Mitigation:* protect per job, not for the worker's lifetime, and bound it by the job's own timeout.

## Against the library:

| Claim | Verdict | Library note |
|---|---|---|
| Serving customers in rotation makes the queue fair | Conflicts | `multi-tenant-queue-fairness` — caps and rate limits, not ordering alone |
| A longer timeout fixes double-running | Conflicts | `queue-leases-and-retries` — a bigger timeout moves the threshold; leases remove it |
| Scale workers on pending queue length | Conflicts | `autoscaling-queue-workers` — backlog per worker, target from latency ÷ job time |
| A connection pooler answers connection pressure | Conflicts | `rds-proxy-connection-pinning` — a default asyncpg reset likely pins every connection |
| Mock the slow step with a fixed delay | Extends | `load-testing-open-vs-closed` — variability drives open-system response time |
| Delete old jobs on a schedule | Extends | `postgres-job-queues` — DELETE creates the cleanup load; drop partitions instead |
| Statement logging captures conversation text | Confirms | `sensitive-data-in-logs` — bound values logged in full by default |

Four planned moves were wrong in the same direction: each treated a scheduling or capacity problem as a knob to turn when the evidence calls for a mechanism. The belief that moved most is the pooler, which was on the roadmap as a prerequisite and may be a no-op.

## Open questions:

- How long does one job actually take, and how much does it vary? Every target depends on it.
- Is the client's real traffic open, closed, or a mix? It decides which result is the headline.
- Can the database keep up with cleanup while the queue is under sustained load?
- What per-customer cap is low enough to protect others and high enough to finish a backfill on time?

## Sources:

1. AWS. "Scaling policy based on Amazon SQS." *Amazon EC2 Auto Scaling User Guide*, n.d. https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-using-sqs-queue.html — **T2**
2. David Yanacek. "Avoiding insurmountable queue backlogs." *Amazon Builders' Library*, 2019. https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf — **T2**
3. Bianca Schroeder, Adam Wierman, Mor Harchol-Balter. "Open Versus Closed: A Cautionary Tale." *USENIX NSDI*, 2006. https://www.usenix.org/legacy/event/nsdi06/tech/full_papers/schroeder/schroeder.pdf — **T1**
4. AWS. "Avoiding pinning an RDS Proxy." *Amazon RDS User Guide*, n.d. https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-pinning.html — **T2**

## Filed

- Updated: [[queue-leases-and-retries]] — an abandoned HTTP call is not cancellation; the callee keeps running
- Updated: [[autoscaling-queue-workers]] — what to do when the platform has no metric math for backlog per task
- Layout: software-S1 (switched from software-S2 at the reader's request — the Proposal layout carries the TL;DR and the epic list)
