---
title: Deterministic mediation of agents
domain: software
area: ai-systems
claim: Constraints on an LLM agent hold only when a non-bypassable component outside the model enforces them, because in-model defenses are measurably breakable and human approval prompts decay with use.
confidence: medium
sources:
  - Ross, Winstead, McEvilley, "Engineering Trustworthy Secure Systems", NIST SP 800-160v1r1 2022 — https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-160v1r1.pdf [T1]
  - Akhawe, Felt, "Alice in Warningland: A Large-Scale Field Study of Browser Security Warning Effectiveness", USENIX Security 2013 — https://www.usenix.org/system/files/conference/usenixsecurity13/sec13-paper_akhawe.pdf [T1]
  - OWASP GenAI Security Project, "LLM01: Prompt Injection", OWASP Top 10 for LLM Applications 2025 — https://genai.owasp.org/llmrisk/llm01-prompt-injection/ [T2]
  - Debenedetti, Shumailov, Fan, Hayes, Carlini, Fabian, Kern, Shi, Terzis, Tramèr, "Defeating Prompt Injections by Design", arXiv:2503.18813v2 2025 — https://arxiv.org/pdf/2503.18813 [T3]
  - Zhan, Fang, Panchal, Kang, "Adaptive Attacks Break Defenses Against Indirect Prompt Injection Attacks on LLM Agents", arXiv:2503.00061 2025 — https://arxiv.org/abs/2503.00061 [T3, abstract only]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [mcp-stdio-server-surface, agent-tool-context-budget, subprocess-argument-injection]
---

# Deterministic mediation of agents

A rule written in a prompt is a request. NIST's Mediated Access principle is that
"All access to and operations on system elements are mediated," and that without
mediation "no basis exists upon which to claim that security is achieved" (Ross
et al. 2022). It splits enforcement into a policy decision and the enforcement of
that decision — which is precisely the split a prompt collapses, since the same
component both decides and acts.

NIST also states what a mechanism must satisfy to count: NON-BYPASSABLE,
EVALUATABLE ("sufficiently small and simple enough to be assessed"), ALWAYS
INVOKED, and TAMPER-PROOF (Ross et al. 2022). A model asked to follow rules fails
the first and the third by construction.

The empirical case agrees. OWASP's position is that in-model prevention is not
achievable — "it is unclear if there are fool-proof methods of prevention" — and
its mitigations are external: restrict privileges, "Define and validate expected
output formats using deterministic code," and gate privileged operations (OWASP
2025). Eight published defenses against indirect prompt injection were broken by
adaptive attacks with success rates over 50% against every one (Zhan et al. 2025)
*(unreplicated)*.

## Tradeoffs

Moving control flow into a deterministic interpreter costs utility. CaMeL solved
77% of AgentDojo tasks against 84% undefended, while cutting successful attacks on
one model from 300 to 0 out of 949 (Debenedetti et al. 2025) *(unreplicated)*. Its
authors name the limits: no protection where control and data flow are unaffected,
demonstrated side channels, and the burden of users writing and maintaining
policies.

Falling back on a human prompt is weaker than it looks. Across over 25 million
warning impressions, click-through ranged from about a tenth of Firefox
malware warnings to 70.2% of Chrome SSL warnings — compliance varies roughly
sevenfold on presentation alone (Akhawe and Felt 2013). CaMeL's authors make the
same point as a design goal: shift decisions into the capability system to reduce
"security fatigue and user desensitization" (Debenedetti et al. 2025).

## Tensions

The two strongest quantitative results here are preprints read without a refereed
version. Treat the direction as well supported and the specific percentages as
unconfirmed.
