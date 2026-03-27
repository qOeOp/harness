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

Use [../../docs/templates/decision-pack.md](../../docs/templates/decision-pack.md) as the canonical template.
Read [../../docs/workflows/volatile-research-default.md](../../docs/workflows/volatile-research-default.md).
Read [../../docs/workflows/internal-research-routing.md](../../docs/workflows/internal-research-routing.md).
Read [../../docs/workflows/task-artifact-routing.md](../../docs/workflows/task-artifact-routing.md).
If a volatile external claim lacks a linked research dispatch, fresh source-note support, or a current URL, treat it as exploratory rather than final.
Default to a task-local decision pack under `.harness/tasks/<task-id>/refs/`.
Only promote it into `.harness/workspace/decisions/log/` or department-level governance outputs when `advanced governance mode` is explicitly enabled.
