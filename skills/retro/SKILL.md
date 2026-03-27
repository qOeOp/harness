---
name: retro
description: Use when generating a company-level retro / process audit from recent reports and retros.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

Create a company process audit from:

- department retros
- daily digests
- checkpoints
- postmortems

Use [./templates/process-audit.md](./templates/process-audit.md).
Write the result into `.harness/workspace/status/process-audits/`.
Preferred script: [./scripts/new_retro.sh](./scripts/new_retro.sh)
