---
name: decision-pack
description: Use when the founder needs a high-density decision package rather than a raw discussion transcript.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

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

Use [./templates/decision-pack.md](./templates/decision-pack.md) as the canonical template.
If a volatile external claim lacks a linked research dispatch, fresh source-note support, or a current URL, treat it as exploratory rather than final.
Default to a task-local decision pack under `.harness/tasks/<task-id>/attachments/`.
Only promote it into `.harness/workspace/decisions/log/` or department-level governance outputs when `advanced governance mode` is explicitly enabled.
Preferred script: [./scripts/new_decision.sh](./scripts/new_decision.sh)
