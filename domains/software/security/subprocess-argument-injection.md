---
title: Subprocess argument injection
domain: software
area: security
claim: Passing an argument vector instead of a shell string removes command injection but not argument injection, so a program that drives external tools with attacker-influenced strings still needs positive allowlist validation of every command and argument.
confidence: high
sources:
  - OWASP, "OS Command Injection Defense Cheat Sheet", OWASP Cheat Sheet Series n.d. — https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html [T2]
  - OWASP, "Input Validation Cheat Sheet", OWASP Cheat Sheet Series n.d. — https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html [T2]
  - NIST NVD, "CVE-2022-24439", National Vulnerability Database 2022 — https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2022-24439 [T1]
  - NIST NVD, "CVE-2026-31862", National Vulnerability Database 2026 — https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-31862 [T1]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [shell-as-a-correctness-substrate, deterministic-mediation-of-agents]
---

# Subprocess argument injection

Command injection happens when a program builds a system command from externally
influenced input without neutralizing the special elements that change what the
command means (OWASP n.d. a). OWASP's first-choice defense is not to call an OS
command at all — a library function "cannot be manipulated to perform tasks other
than those it is intended to do" (OWASP n.d. a). When the external tool is the
point, the structural defense is that "the command must be separated from its
arguments": an argv-based API invokes the target directly and "does NOT try to
invoke the shell at any point", so the metacharacter set
``& | ; $ > < ` \ ! ' " ( )`` never gets interpreted (OWASP n.d. a).

That is necessary and not sufficient. OWASP states plainly that "Every OS Command
Injection is also an Argument Injection" — a string that never reaches a shell can
still be read by the target program as a flag (OWASP n.d. a). GitPython was
remotely exploitable in every version for exactly this reason: insufficient
sanitization of arguments let a crafted remote URL be injected into a `git clone`
invocation, scored CVSS 3.1 9.8 by NVD under CWE-20 (NIST NVD 2022). The pattern is
not historical — CVE-2026-31862 records Git-related API endpoints interpolating
user-controlled file, branch, message and commit parameters into a shell call,
CWE-78, CVSS 3.1 9.1 (NIST NVD 2026).

## Tradeoffs

The remaining control is positive validation: an allowlist of permitted commands
plus regex and length limits on each argument, since "it is trivial for an attacker
to bypass" a denylist (OWASP n.d. a, n.d. b). OWASP's own worked example is as
tight as `^[a-z0-9]{3,10}$`.

Validation is explicitly a secondary control. OWASP says input validation "should
not be used as the primary method of preventing" injection attacks, only as
something that "can significantly contribute to reducing their impact" (OWASP
n.d. b). The primary control stays structural: no shell, separated arguments, and
a fixed set of callable commands.
