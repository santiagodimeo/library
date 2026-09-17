---
title: Anvil in C and Bash
question: If anvil's deterministic layer becomes a vendor-neutral MCP server written in C and Bash, what does that substrate buy in control over an agent, and what does it cost?
date: 2026-09-16
domains: [software]
confidence: Medium — the mediation case rests on T1 principles, but its sharpest numbers are preprints and the memory-safety proportions are vendor-reported
read_time: 7 min
repo: anvil
artifact: https://claude.ai/artifact/KegcJk7wPtPJSbcfmKtuXM
---

# Anvil in C and Bash

**Bottom line.** The control comes from the mediation boundary, not from C. Moving
anvil's rules out of prompt text into a program that decides and then refuses is
the whole win, and it is language-independent. C then makes a specific trade: it
is the right size for the job — an MCP stdio server is a small surface, and NIST
treats smallness as a precondition for a mechanism being assessable at all — but
anvil's deterministic layer is a parser of attacker-influenced strings, which is
the worst place to spend memory safety. The thing that would change the calculus
is not the language: it is whether the shell stays out of the command path.

## The control is the refusal, not the language

NIST's Mediated Access principle is that "All access to and operations on system
elements are mediated," and that without mediation "no basis exists upon which to
claim that security is achieved" [1]. It splits enforcement into a policy decision
and the enforcement of that decision. A rule written in a prompt collapses those
two into one component, and that component is the model.

NIST also states what a mechanism must satisfy to count as protection at all:
NON-BYPASSABLE, EVALUATABLE ("sufficiently small and simple enough to be assessed
to produce adequate confidence in the protection provided"), ALWAYS INVOKED, and
TAMPER-PROOF [1]. Anvil's current sweep rules — never touch a dirty tree, never
push, Docker is always an ask — fail the first and the third by construction. They
hold when the model complies and are silent when it does not.

The empirical picture agrees with the principle. OWASP's position is that in-model
prevention is not achievable — "it is unclear if there are fool-proof methods of
prevention" — and every mitigation it lists is external, including "Define and
validate expected output formats using deterministic code" [2]. Eight published
defenses against indirect prompt injection were broken by adaptive attacks with
success rates over 50% against all of them [3] *(unreplicated)*. The strongest
demonstration of the alternative fixes control flow in an interpreter and lets the
model supply only values: it solved 77% of AgentDojo tasks against 84% undefended,
and cut successful attacks on one model from 300 to 0 out of 949 [4]
*(unreplicated)*.

That is the argument for the rewrite, and none of it mentions a language. A plan
tool that classifies actions and an apply tool that refuses any id it did not
itself classify satisfies non-bypassable and always-invoked in Go, in Rust, or in
C. Choosing C is a separate decision with separate consequences.

## C's risk lands exactly on anvil's input surface

What the deterministic layer actually does is parse. It reads JSON-RPC from a pipe,
`.claude.json` from disk, and then strings it did not author: git refs, GitHub PR
titles, worktree paths, Docker compose labels. Anyone with push access to a fork
writes some of those, and sweep reads them across every repo you own in one run.

Memory safety is the dominant severe-bug class in large C/C++ codebases: about 70%
of high and critical vulnerabilities in Chrome and in Android, 68% of Project
Zero's in-the-wild zero-days, and 70% of Microsoft vulnerabilities with CVEs [5].
Google's own server-side fleet sits far lower at 16–29% [5], which is the useful
qualifier — the proportion tracks exposure to hostile input, and a parser is the
high end of that range, not the low one.

These bugs also last. Across 5,914 CVEs in 11 FOSS projects, memory and
resource-management vulnerabilities had a mean lifetime of 1,633.60 days against
1,354.07 for input-validation bugs, and the longest-lived project in the set was
tcpdump — a parser of untrusted network input — at a mean of 3,168.58 days, roughly
8.7 years [6]. The same study found the arrival of modern fuzzing produced "no
significant difference in the lifetime trend" for Linux memory CVEs [6].

Tooling narrows this without closing it. AddressSanitizer found over 300 unknown
bugs in Chromium in ten months, 210 of them heap use-after-free, at 73% average
slowdown and 3.4x memory [7]. CVE-2023-4863 in libwebp still escaped 97.55% fuzzing
coverage of its own file, and Chrome's targeted use-after-free mitigation covers
50% of such issues [5].

## Smallness is the one argument that genuinely favors C

NIST's EVALUATABLE criterion cuts the other way once the surface is small enough.
It recommends formal methods "for key modules rather than entire applications," and
its worked example of what is tractable is the seL4 verification at "about 10 000
lines of C code" [8]. Its Reduced Complexity principle says the same thing in
reverse: complexity "increases the difficulty in identifying and assessing loss
scenarios, susceptibilities, and vulnerabilities" [1].

The MCP stdio surface is genuinely that small. Messages are UTF-8 JSON-RPC 2.0,
newline-delimited, with no embedded newlines [9]. Since the 2026-07-28 revision the
protocol is stateless, with no protocol-level session — a server that needs state
mints an explicit handle and receives it back as an ordinary tool argument [10].
The methods that matter are `server/discover`, `tools/list` and `tools/call`, plus
two error shapes. That is a few hundred lines, not a framework.

The discipline that makes it hold is the Recognizer Pattern: recognize input fully
against a formal specification, then hand validated objects across a boundary that
program logic never crosses backwards. Its named failure mode is the "shotgun
parser," where "validation is spread across an implementation, and program logic
grabs data from the input-handling code before the full data's correctness is
assured" [11]. The same article counts 850 XML-related CVEs against 96 for JSON,
attributing the gap to JSON taking no action until the object is complete [11]. A
line-delimited JSON protocol starts on the right side of that line — unless the
implementation throws it away by acting on half-parsed input.

## Bash is where the injection lives

The sharper risk is not memory, it is the command path. OWASP's first defense is
not to call an OS command at all; when the tool is the point, "the command must be
separated from its arguments," and an argv API "does NOT try to invoke the shell at
any point," so the metacharacter set never gets interpreted [12]. That is not a
Bash-friendly requirement. A shell script that interpolates a ref name into a
`git` invocation is building a string, which is the shape the defense exists to
eliminate.

Separating arguments is necessary and not sufficient: "Every OS Command Injection
is also an Argument Injection" [12]. GitPython was remotely exploitable in every
version because a crafted remote URL could be injected into a `git clone`
invocation — CWE-20, CVSS 3.1 9.8 [13]. And this is current: CVE-2026-31862, from
March 2026, records a Git-driving tool whose API endpoints interpolated
user-controlled file, ref, message and commit parameters into shell calls —
CWE-78, CVSS 3.1 9.1 [14]. That is anvil's exact input list.

Shell is also a poor place for a predicate that must hold. Pinning down POSIX shell
behavior required a mechanized semantics, which turned out to be more conformant
than any of bash, dash, zsh, OSH, mksh, ksh93 or yash [15] *(unreplicated)* — the
converse being that every shell in use carries known divergences. Static analysis
fares no better: PaSh-JIT moved its analysis to run time because of "the dynamic
behaviors pervasive in shell scripts—e.g., variable expansion and command
substitution" [16].

One mechanical hazard belongs here too. The stdio transport says the server "MUST
NOT write anything to its `stdout` that is not a valid MCP message" [9], and a
spawned child inherits its parent's stdout unless redirected. Every `git`, `gh` and
`docker` call must have its stdout captured explicitly or the transport corrupts.
This follows from [9] and standard POSIX descriptor inheritance; no source states
it.

## Where it breaks

Deterministic mediation is not a guarantee, and its own authors say so: it "doesn't
aim to defend against attacks that do not affect the control nor the data flow," it
is "vulnerable to side-channel attacks," and it requires "users needing to codify
and specify security policies and maintain them" [4]. A planner that classifies
correctly and an executor that refuses faithfully still execute a plan that was
wrong for reasons no predicate encodes.

Falling back on a human gate is weaker than it reads. Across over 25 million
warning impressions, click-through ran from about a tenth of Firefox malware
warnings to 70.2% of Chrome SSL warnings — a sevenfold spread on presentation alone
[17]. Anvil's Ask tier inherits that curve, which is an argument for keeping the
tier small rather than for widening it.

Two costs are structural. The 70% memory-safety family is vendor self-reporting
restated in a vendor whitepaper [5], not an independent replication — directionally
solid, not a measured constant. And there is no C SDK at any tier: Tier 1 covers
TypeScript, Python, C#, Go and Rust [18]. Version 2026-07-28 alone deprecated
roots, sampling, logging and dynamic client registration [19]. In C, that migration
is yours.

One sizing note favors anvil: keeping the exported surface under ten tools avoids
the regime where definitions dominate context and selection accuracy degrades past
30–50 tools [20].

## Against the library

The library had nothing on any of this. Six notes now hold the baseline, in
`software/ai-systems`, `software/security` and `software/languages-runtimes`.

## Open questions

- Does the plan/apply handle need entropy and expiry on a single-client stdio
  server, where the spec's state-handle guidance assumes a multi-user service?
- Is there an independent, non-vendor measurement of memory-safety proportions for
  a small C parser, rather than for browser-scale codebases?
- Does moving the commit-message and ref-name gates from harness hooks into git's
  own hooks change their bypass rate in practice, or only their coverage?
- What is the smallest predicate set that makes sweep's Never tier non-bypassable,
  and can it be property-tested rather than argued?

## Sources

1. Ross, R., Winstead, M., McEvilley, M. "Engineering Trustworthy Secure Systems." *NIST SP 800-160v1r1*, 2022. https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-160v1r1.pdf — **T1**
2. OWASP GenAI Security Project. "LLM01: Prompt Injection." *OWASP Top 10 for LLM Applications*, 2025. https://genai.owasp.org/llmrisk/llm01-prompt-injection/ — **T2**
3. Zhan, Q., Fang, R., Panchal, H. S., Kang, D. "Adaptive Attacks Break Defenses Against Indirect Prompt Injection Attacks on LLM Agents." *arXiv:2503.00061*, 2025. https://arxiv.org/abs/2503.00061 — **T3** · abstract only
4. Debenedetti, E., Shumailov, I., Fan, T., Hayes, J., Carlini, N., Fabian, D., Kern, C., Shi, C., Terzis, A., Tramèr, F. "Defeating Prompt Injections by Design." *arXiv:2503.18813v2*, 2025. https://arxiv.org/pdf/2503.18813 — **T3**
5. Rebert, A., Kern, C. "Secure by Design: Google's Perspective on Memory Safety." *Google Security Engineering*, 2024. https://research.google/pubs/secure-by-design-googles-perspective-on-memory-safety/ — **T1** · figures read from the Google-hosted PDF
6. Alexopoulos, N., Brack, M., Wagner, J. P., Grube, T., Mühlhäuser, M. "How Long Do Vulnerabilities Live in the Code?" *31st USENIX Security Symposium*, 2022. https://www.usenix.org/conference/usenixsecurity22/presentation/alexopoulos — **T1**
7. Serebryany, K., Bruening, D., Potapenko, A., Vyukov, D. "AddressSanitizer: A Fast Address Sanity Checker." *USENIX ATC '12*, 2012. https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf — **T1**
8. Black, P. E., Badger, M., Guttman, B., Fong, E. "Dramatically Reducing Software Vulnerabilities." *NISTIR 8151*, 2016. https://nvlpubs.nist.gov/nistpubs/ir/2016/nist.ir.8151.pdf — **T1**
9. Model Context Protocol. "Transports." *MCP specification 2025-06-18*. https://modelcontextprotocol.io/specification/2025-06-18/basic/transports — **T3** · not in registry
10. Model Context Protocol. "Tools." *MCP specification 2026-07-28*. https://modelcontextprotocol.io/specification/2026-07-28/server/tools — **T3** · not in registry
11. Bratus, S., Hermerschmidt, L., Hallberg, S. M., Locasto, M. E., Momot, F. D., Patterson, M. L., Shubina, A. "Curing the Vulnerable Parser: Design Patterns for Secure Input Handling." *;login:*, USENIX, 42(1), 2017. https://www.usenix.org/system/files/login/articles/login_spring17_08_bratus.pdf — **T1**
12. OWASP. "OS Command Injection Defense Cheat Sheet." *OWASP Cheat Sheet Series*, n.d. https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html — **T2**
13. NIST NVD. "CVE-2022-24439." *National Vulnerability Database*, 2022. https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2022-24439 — **T1**
14. NIST NVD. "CVE-2026-31862." *National Vulnerability Database*, 2026. https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-31862 — **T1**
15. Greenberg, M., Blatt, A. J. "Executable formal semantics for the POSIX shell." *Proc. ACM Program. Lang.* 4(POPL), 2020. https://arxiv.org/abs/1907.05308 — **T3** · abstract only; refereed version returned 403
16. Kallas, K., Mustafa, T., Bielak, J., Karnikis, D., Dang, T. N., Greenberg, M., Vasilakis, N. "Practically Correct, Just-in-Time Shell Script Parallelization." *OSDI '22*, 2022. https://www.usenix.org/conference/osdi22/presentation/kallas — **T1** · abstract only
17. Akhawe, D., Felt, A. P. "Alice in Warningland: A Large-Scale Field Study of Browser Security Warning Effectiveness." *22nd USENIX Security Symposium*, 2013. https://www.usenix.org/system/files/conference/usenixsecurity13/sec13-paper_akhawe.pdf — **T1**
18. Model Context Protocol. "SDKs." *MCP docs*, n.d. https://modelcontextprotocol.io/docs/sdk — **T3** · not in registry
19. Model Context Protocol. "Deprecated Features." *MCP specification 2026-07-28*. https://modelcontextprotocol.io/specification/2026-07-28/deprecated — **T3** · not in registry
20. Anthropic. "Tool search tool." *Claude Platform docs*, n.d. https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool — **T2** · fetched 2026-09-16

## Proposed sources

- Model Context Protocol specification and docs — `modelcontextprotocol.io`, proposed **T2**: a project's own documentation is primary for that project's behavior, which is the rule the registry already applies to PostgreSQL, Kafka and Debezium. Used here as T3 only because no row exists yet.

## Filed

- New: [[deterministic-mediation-of-agents]] → `domains/software/ai-systems/deterministic-mediation-of-agents.md`
- New: [[mcp-stdio-server-surface]] → `domains/software/ai-systems/mcp-stdio-server-surface.md`
- New: [[agent-tool-context-budget]] → `domains/software/ai-systems/agent-tool-context-budget.md`
- New: [[subprocess-argument-injection]] → `domains/software/security/subprocess-argument-injection.md`
- New: [[shell-as-a-correctness-substrate]] → `domains/software/languages-runtimes/shell-as-a-correctness-substrate.md`
- New: [[memory-safety-in-input-handling]] → `domains/software/security/memory-safety-in-input-handling.md`
