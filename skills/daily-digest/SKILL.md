---
name: daily-digest
description: Use when consolidating advanced-governance workstream daily reports into a company-level digest.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).
Use [./templates/company-daily-digest.md](./templates/company-daily-digest.md).

Only use this skill when `advanced governance mode` is explicitly enabled.
Read recent files from `.harness/workspace/workstreams/*/workspace/reports/daily/`.
Write the result into `.harness/workspace/status/digests/`.
If the runtime has not materialized `.harness/workspace/workstreams/`, do not invent that surface from a source-repo sweep; report that the digest is blocked on governance-mode runtime artifacts.
Preferred script: [./scripts/new_digest.sh](./scripts/new_digest.sh)
