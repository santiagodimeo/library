---
title: MCP stdio server surface
domain: software
area: ai-systems
claim: A local MCP server over stdio is newline-delimited JSON-RPC 2.0 on a pipe with a hard rule that nothing but protocol messages may reach stdout, which makes the implementable surface small but makes every subprocess the server spawns a correctness hazard.
confidence: medium
sources:
  - Model Context Protocol, "Transports", MCP specification 2025-06-18 — https://modelcontextprotocol.io/specification/2025-06-18/basic/transports [T3, not in registry]
  - Model Context Protocol, "Architecture overview", MCP docs 2026-07-28 — https://modelcontextprotocol.io/docs/2026-07-28/learn/architecture [T3, not in registry]
  - Model Context Protocol, "Tools", MCP specification 2026-07-28 — https://modelcontextprotocol.io/specification/2026-07-28/server/tools [T3, not in registry]
  - Model Context Protocol, "Deprecated Features", MCP specification 2026-07-28 — https://modelcontextprotocol.io/specification/2026-07-28/deprecated [T3, not in registry]
  - Model Context Protocol, "SDKs", MCP docs n.d. — https://modelcontextprotocol.io/docs/sdk [T3, not in registry]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [agent-tool-context-budget, deterministic-mediation-of-agents]
---

# MCP stdio server surface

The client launches the server as a subprocess and speaks JSON-RPC 2.0 over its
stdin and stdout. Messages are UTF-8, newline-delimited, and must not contain
embedded newlines. The server may write freely to stderr, but "**MUST NOT** write
anything to its `stdout` that is not a valid MCP message" (Model Context Protocol
2025). That last rule is the one that bites an implementation that shells out:
a spawned child inherits the parent's stdout unless redirected, so any subprocess
that prints corrupts the protocol stream. This follows from the rule and standard
POSIX fork/exec descriptor inheritance; no source states it directly.

As of protocol version 2026-07-28 the protocol is stateless — every request carries
its version and capabilities in `_meta`, and there is no protocol-level session
(Model Context Protocol 2026a). Servers needing state across calls mint an explicit
handle returned in a tool result and accepted as an ordinary argument later
(Model Context Protocol 2026b).

## Tradeoffs

The surface an implementer must cover is genuinely small: a line reader, a JSON
parser, `server/discover`, `tools/list`, `tools/call`, and two error shapes —
JSON-RPC protocol errors versus in-result `isError: true` (Model Context Protocol
2026b). That is what makes a from-scratch implementation plausible in a language
with no SDK.

The cost is spec churn, which the official SDKs absorb. There are Tier 1 SDKs for
TypeScript, Python, C#, Go and Rust, and none for C (Model Context Protocol n.d.).
Version 2026-07-28 alone deprecated roots, sampling, logging and dynamic client
registration, under a policy whose earliest removal is the first revision released
on or after 2027-07-28 (Model Context Protocol 2026c) — about a twelve-month
migration window per deprecation.
