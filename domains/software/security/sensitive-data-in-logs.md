---
title: Sensitive data in logs
domain: software
area: security
claim: Statement-level database logging captures bound values in full by default, and log stores keep data forever unless told otherwise, so personal data in logs needs the source switched off, explicit retention, and a cleanup plan for what's already there.
confidence: high
sources:
  - PostgreSQL Global Development Group, "Error Reporting and Logging", PostgreSQL docs n.d. — https://www.postgresql.org/docs/current/runtime-config-logging.html [T2]
  - OWASP, "Logging Cheat Sheet", OWASP Cheat Sheet Series n.d. — https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html [T2]
  - Kent, Souppaya, "Guide to Computer Security Log Management", NIST SP 800-92 2006 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-92.pdf [T1]
  - McCallister, Grance, Scarfone, "Guide to Protecting the Confidentiality of PII", NIST SP 800-122 2010 — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-122.pdf [T1]
  - AWS, "Working with log groups and log streams", CloudWatch Logs User Guide n.d. — https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html [T2]
  - AWS, "Help protect sensitive log data with masking", CloudWatch Logs User Guide n.d. — https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/mask-sensitive-log-data.html [T2]
  - AICPA ASEC, "2017 Trust Services Criteria (March 2020 update)", TSP Section 100 2020 — third-party mirror https://arpio.io/wp-content/uploads/2020/08/trust-services-criteria.pdf [T1, mirror copy, pre-2022 points of focus]
updated: 2026-09-16
from: a private investigation
related: [postgres-job-queues]
---

# Sensitive data in logs

With PostgreSQL's `log_statement = all` and the extended query protocol, "values of the Bind parameters are included", and the default `log_parameter_max_length = -1` logs them in full. The docs warn that logged statements "might reveal sensitive data" (PostgreSQL n.d.). Turning the setting to `none` or `ddl` isn't the whole fix: the default `log_min_error_statement = ERROR` still logs the text of failing statements (PostgreSQL n.d.). Get performance visibility from duration-based logging instead.

OWASP says sensitive personal data should usually not be logged directly (OWASP n.d.). NIST says to avoid recording unneeded sensitive data and to keep PII only as long as strictly necessary (Kent 2006; McCallister 2010).

CloudWatch keeps log data indefinitely by default, and deletion after setting retention can take up to 72 hours (AWS n.d. a). Data masking applies only to events ingested after the policy is set, and anyone with `logs:Unmask` sees raw values (AWS n.d. b). Masking is a backstop, not a fix.

## Tradeoffs

- Retention cuts both ways. OWASP says logs "must not be destroyed before" the required retention period ends "and must not be kept beyond this time" (OWASP n.d.). SOC 2 criteria ask for a defined retention period, disposal at its end, and a way to capture deletion requests (AICPA 2020, mirror copy; check the current points of focus). NIST adds litigation holds (McCallister 2010). A single "delete after N days" rule doesn't satisfy that.
- Retention covers backups and archives too (Kent 2006). Treat logs already written as a cleanup job, not only a config change.
