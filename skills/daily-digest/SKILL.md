---
name: daily-digest
description: Use when consolidating advanced-governance department daily reports into a company-level digest.
---

Read [../../docs/workflows/process-compounding-cadence.md](../../docs/workflows/process-compounding-cadence.md).
Use [../../docs/templates/company-daily-digest.md](../../docs/templates/company-daily-digest.md).

Only use this skill when `advanced governance mode` is explicitly enabled.
Read recent files from `.harness/workspace/departments/*/workspace/reports/daily/`.
Write the result into `.harness/workspace/status/digests/`.
If the runtime has not materialized `.harness/workspace/departments/`, do not invent that surface from a source-repo sweep; report that the digest is blocked on governance-mode runtime artifacts.
