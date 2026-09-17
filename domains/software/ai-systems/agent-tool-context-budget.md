---
title: Agent tool context budget
domain: software
area: ai-systems
claim: Every tool definition an agent can reach is loaded into context on every request unless the host defers it, so a tool surface is a standing token cost and a selection-accuracy cost, not a free extension point.
confidence: high
sources:
  - Anthropic, "Tool search tool", Claude Platform docs n.d. — https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool [T2]
  - Model Context Protocol, "Client Best Practices", MCP docs 2026-07-28 — https://modelcontextprotocol.io/docs/2026-07-28/develop/clients/client-best-practices [T3, not in registry]
updated: 2026-09-16
from: investigations/2026-09-16-anvil-in-c-and-bash.md
related: [llm-api-throughput-limits, deterministic-mediation-of-agents]
---

# Agent tool context budget

Tool definitions are part of the prompt prefix. A host that connects an agent to
several tool servers pays for every definition on every request, before the user's
message is read. Anthropic gives a worked figure: a typical five-server setup
(GitHub, Slack, Sentry, Grafana, Splunk) consumes about 55k tokens in definitions
alone (Anthropic n.d.). MCP's own client guidance describes the same failure and
recommends hosts switch to on-demand loading once definitions pass 1–5% of the
context window (Model Context Protocol 2026).

The second cost is selection accuracy, and it binds earlier than the token cost.
Anthropic reports that a model's ability to pick the right tool degrades once more
than 30–50 tools are available (Anthropic n.d.). Tool count is therefore a design
constraint on the server, not only a budget problem for the host.

The mitigation on the host side is progressive discovery: expose a search
meta-tool, keep full schemas out of context until the model asks for one
(Model Context Protocol 2026). Anthropic's server-side equivalent is
`defer_loading`, which typically cuts definition tokens by over 85% by loading
only the 3–5 tools a request needs (Anthropic n.d.).

## Tradeoffs

Deferring costs a round trip and invalidates prompt caching if definitions are
inserted before the cache breakpoint; the resulting miss can cost more tokens than
the definitions removed (Model Context Protocol 2026).

Below roughly ten tools, none of this applies. Anthropic states plainly that
standard tool calling is the better fit under ten tools, or when total definitions
are under 100 tokens (Anthropic n.d.). A server author's lever is the opposite one:
keep the exported surface small enough that the question never arises.
