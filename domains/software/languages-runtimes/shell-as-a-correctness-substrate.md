---
title: Shell as a correctness substrate
domain: software
area: languages-runtimes
claim: POSIX shell semantics are dynamic enough that every widely used shell diverges from the standard in known ways and static analysis of scripts is unreliable, so shell is a poor host for logic whose correctness has to be guaranteed rather than observed.
confidence: medium
sources:
  - Greenberg, Blatt, "Executable formal semantics for the POSIX shell", Proc. ACM Program. Lang. 4(POPL) 2020 — https://arxiv.org/abs/1907.05308 [T3, preprint; published version dl.acm.org/doi/10.1145/3371111 returned 403]
  - Kallas, Mustafa, Bielak, Karnikis, Dang, Greenberg, Vasilakis, "Practically Correct, Just-in-Time Shell Script Parallelization", OSDI '22 2022 — https://www.usenix.org/conference/osdi22/presentation/kallas [T1, abstract only]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [subprocess-argument-injection]
---

# Shell as a correctness substrate

The shell's behavior was imprecise enough that pinning it down required a
mechanized formal semantics. Smoosh, a small-step executable semantics for POSIX
shell, was tested against seven shells in common use — bash, dash, zsh, OSH, mksh,
ksh93 and yash — across three test suites, and came out the most POSIX-conformant
of the set, with the Modernish suite finding it had the fewest bugs and no quirks
(Greenberg and Blatt 2020) *(unreplicated)*. The useful reading is the converse:
every shell people actually run carries documented divergences from the standard,
so "it works in bash" is a statement about one implementation.

Static reasoning about scripts fares no better. PaSh-JIT moved its analysis from
compile time to run time specifically because of "the dynamic behaviors pervasive
in shell scripts—e.g., variable expansion and command substitution—which often
requires reasoning about the current state of the shell and filesystem" (Kallas
et al. 2022). A tool cannot decide what a script will do without knowing the state
it will run against.

## Tradeoffs

Shell earns its place where the value is exactly that dynamism: gluing processes,
wiring pipes, and being readable and runnable by hand without a build step. It is a
bad host for a predicate whose wrong answer is destructive, because the failure is
silent — an unquoted expansion changes the argument list rather than raising.

The practical split is to keep shell at the boundary (installers, git hook shims,
launchers) and to put decisions that must hold — classification, validation,
refusal — in something with a type checker and a test suite. See
[[subprocess-argument-injection]] for the separate hazard of building command lines
in any language.

## Tensions

The Smoosh conformance result rests on a preprint read in abstract only; the
refereed POPL version was inaccessible. Treat the ranking of specific shells as
unconfirmed, and the general claim — that divergences exist and are known — as the
load-bearing part.
