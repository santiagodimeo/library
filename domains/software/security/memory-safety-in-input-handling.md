---
title: Memory safety in input handling
domain: software
area: security
claim: Memory-safety defects concentrate where code parses untrusted input, they outlive other classes by years, and neither fuzzing nor sanitizers close the gap — so the decision that matters for a C parser is the input-handling design, not the tooling around it.
confidence: medium
sources:
  - Rebert, Kern, "Secure by Design: Google's Perspective on Memory Safety", Google Security Engineering 2024 — https://research.google/pubs/secure-by-design-googles-perspective-on-memory-safety/ [T1, vendor-reported figures]
  - Alexopoulos, Brack, Wagner, Grube, Mühlhäuser, "How Long Do Vulnerabilities Live in the Code?", USENIX Security 2022 — https://www.usenix.org/conference/usenixsecurity22/presentation/alexopoulos [T1]
  - Serebryany, Bruening, Potapenko, Vyukov, "AddressSanitizer: A Fast Address Sanity Checker", USENIX ATC '12 2012 — https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf [T1]
  - Bratus, Hermerschmidt, Hallberg, Locasto, Momot, Patterson, Shubina, "Curing the Vulnerable Parser: Design Patterns for Secure Input Handling", ;login: 42(1) 2017 — https://www.usenix.org/system/files/login/articles/login_spring17_08_bratus.pdf [T1]
  - Black, Badger, Guttman, Fong, "Dramatically Reducing Software Vulnerabilities", NISTIR 8151 2016 — https://nvlpubs.nist.gov/nistpubs/ir/2016/nist.ir.8151.pdf [T1]
  - OWASP, "C-Based Toolchain Hardening Cheat Sheet", OWASP Cheat Sheet Series n.d. — https://cheatsheetseries.owasp.org/cheatsheets/C-Based_Toolchain_Hardening_Cheat_Sheet.html [T2]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [subprocess-argument-injection, shell-as-a-correctness-substrate]
---

# Memory safety in input handling

The headline proportion is about 70% of high and critical vulnerabilities in
Chrome and Android, 68% of Project Zero's in-the-wild zero-days, and 70% of
Microsoft CVEs (Rebert and Kern 2024). The more informative number in the same
source is Google's server-side fleet at 16–29% (Rebert and Kern 2024): the
proportion tracks how much hostile input the code touches, so it is a property of
the component, not of the language alone.

Lifetime data says the same. Across 5,914 CVEs in 11 FOSS projects, memory and
resource-management defects had a mean lifetime of 1,633.60 days (median 1,129)
against 1,354.07 days for input-validation defects, and the longest-lived project
in the set was tcpdump — a parser of untrusted network traffic — at a mean of
3,168.58 days (Alexopoulos et al. 2022). The arrival of modern fuzzing produced "no
significant difference in the lifetime trend" for Linux memory CVEs (Alexopoulos
et al. 2022).

Tooling narrows the gap without closing it. AddressSanitizer found over 300 unknown
bugs in Chromium in ten months, 210 of them heap use-after-free, at 73% average
slowdown and 3.4x memory (Serebryany et al. 2012). CVE-2023-4863 in libwebp still
escaped 97.55% fuzzing coverage of its own file (Rebert and Kern 2024).

## Tradeoffs

The design lever is the Recognizer Pattern: recognize input fully against a formal
specification, then pass validated objects across a boundary that program logic
never crosses backwards. Its failure mode is the "shotgun parser," where
"validation is spread across an implementation, and program logic grabs data from
the input-handling code before the full data's correctness is assured" (Bratus
et al. 2017). The same article attributes an order-of-magnitude CVE gap — 850
XML-related against 96 for JSON — to JSON taking no action until the object is
complete (Bratus et al. 2017).

Where C is unavoidable, assurance scales with smallness: NIST recommends formal
methods "for key modules rather than entire applications," citing seL4 at about
10,000 lines of C (Black et al. 2016). Everything else is hardening flags and
paired assertions (OWASP n.d.), which carry no measured effect.

## Tensions

The ~70% family is vendor self-reporting (Google, Microsoft, Project Zero)
restated in a vendor whitepaper. It is consistent across three independent
vendors, but it is not an independent replication over a named codebase and
window, and it should not be quoted as a measured constant.
