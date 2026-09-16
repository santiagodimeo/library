---
title: Autoscaling queue workers
domain: software
area: reliability
claim: Queue workers should scale on backlog per task, not raw queue depth, and need scale-in protection so autoscaling doesn't kill in-flight jobs; spot capacity adds interruptions that protection doesn't cover.
confidence: high
sources:
  - AWS, "Scaling policy based on Amazon SQS", EC2 Auto Scaling User Guide n.d. — https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-using-sqs-queue.html [T2]
  - AWS, "How target tracking scaling for Application Auto Scaling works", Application Auto Scaling User Guide n.d. — https://docs.aws.amazon.com/autoscaling/application/userguide/target-tracking-scaling-policy-overview.html [T2]
  - AWS, "Protect your Amazon ECS tasks from being terminated by scale-in events", Amazon ECS Developer Guide n.d. — https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-scale-in-protection.html [T2]
  - AWS, "Amazon ECS clusters for Fargate", Amazon ECS Developer Guide n.d. — https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-capacity-providers.html [T2]
  - AWS, "Linux containers on Fargate container image pull behavior", Amazon ECS Developer Guide n.d. — https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-pull-behavior.html [T2]
updated: 2026-09-16
from: a private investigation
related: [multi-tenant-queue-fairness, queue-leases-and-retries, rds-proxy-connection-pinning]
---

# Autoscaling queue workers

Target tracking assumes the metric moves in inverse proportion to capacity: double the capacity, halve the metric (AWS n.d. b). Raw queue depth doesn't, and AWS names it as the wrong metric. Use backlog per task, queue depth divided by running tasks, built with metric math. The target is acceptable latency divided by per-job processing time; AWS's example is 10 s ÷ 0.1 s = 100 (AWS n.d. a).

Target tracking already adds capacity fast and removes it slowly, usually waiting until the metric is more than 10% below target. ECS cooldowns default to 300 s, and scale-in can be disabled in favor of another mechanism (AWS n.d. b).

Slow scale-in still kills in-flight work. ECS task scale-in protection is set from inside the task through the agent endpoint, which AWS recommends for queue workers. It defaults to 2 hours, ranges from 1 to 2,880 minutes, blocks rolling deployments while set, and CloudFormation updates fail after 3 hours (AWS n.d. c).

## Tradeoffs

- Fargate Spot sends a two-minute warning via EventBridge and SIGTERM, `stopTimeout` defaults to 30 s with a 120 s max, and there's no automatic fallback to on-demand when Spot capacity runs out (AWS n.d. d). Keep an on-demand base. Scale-in protection doesn't cover Spot interruption (inference from AWS n.d. c), so jobs must survive losing a task; see [[queue-leases-and-retries]].
- Fargate doesn't cache image layers, so every new task pulls the full image. SOCI lazy loading is recommended above 250 MB, plus smaller images and a same-Region registry endpoint (AWS n.d. e). Model loading after the pull isn't helped by this (inference).
