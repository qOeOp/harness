---
name: decision-pack
description: Use when the founder needs a high-density decision package rather than a raw discussion transcript.
---

Produce a final decision package.

Required sections:

1. Decision
2. Why now
3. Evidence
4. Dissent
5. Risks
6. Tradeoffs
7. Ask from Founder
8. Next 7 days

Use [../../docs/templates/decision-pack.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/decision-pack.md) as the canonical template.
Read [../../docs/workflows/volatile-research-default.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/volatile-research-default.md).
Read [../../docs/workflows/internal-research-routing.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/internal-research-routing.md).
If a volatile external claim lacks a linked research dispatch, fresh source-note support, or a current URL, treat it as exploratory rather than final.
Founder-facing output goes to `.harness/workspace/decisions/log/`.
Department-local output goes to the current department `workspace/outputs/`.
