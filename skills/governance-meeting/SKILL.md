---
name: governance-meeting
description: Use when the founder wants a governance meeting briefing that combines company operations and process improvement.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

Only use this skill when `advanced governance mode` is explicitly enabled.
If the runtime has not materialized the required `.harness/workspace/` governance artifacts, do not backfill them from a source-repo sweep; report that the meeting brief is blocked on governance-mode runtime artifacts.

Prepare a governance meeting brief by combining:

- company daily digest
- department reports
- process audits
- retro findings

Use:

- [./templates/governance-meeting-brief.md](./templates/governance-meeting-brief.md)
- [./templates/meeting-minutes.md](./templates/meeting-minutes.md)

If governance recommendations depend on current tooling or community practices, require the `research` bundle `dispatch` mode plus fresh source-note support or mark them as needing freshness check.
