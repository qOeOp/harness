---
name: retro
description: Use when generating advanced-governance retros or process audits from governance runtime artifacts.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

Only use this skill when `advanced governance mode` is explicitly enabled.

Create a company process audit or workstream retro from:

- workstream retros
- daily digests
- checkpoints
- postmortems

Use [./templates/process-audit.md](./templates/process-audit.md).
Write company process audits into `.harness/workspace/status/process-audits/`.
Write workstream retros into `.harness/workspace/workstreams/<workstream>/workspace/reports/retros/`.
If the runtime has not materialized the required `.harness/workspace/` governance surfaces, do not invent them from a source-repo sweep; report that the retro is blocked on governance-mode runtime artifacts.
Preferred script: [./scripts/new_retro.sh](./scripts/new_retro.sh)
