---
name: acceptance-review
description: Use when the founder needs to review a runnable slice and decide accept, rework, or pause.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

Prepare the final founder or user review using [./templates/acceptance-review-brief.md](./templates/acceptance-review-brief.md).

If acceptance progress spans sessions, slices, or parallel verification work, first create a task-local `Acceptance Ledger` using [./templates/acceptance-ledger.md](./templates/acceptance-ledger.md); keep it update-only by advancing status / checklist / evidence references instead of rewriting the full acceptance spec every round.

Canonical script surface:

- [./scripts/new_acceptance_ledger.sh](./scripts/new_acceptance_ledger.sh) `--work-item <WI-xxxx> <scope>`

If acceptance criteria depend on volatile external facts, require the `research` bundle `dispatch` mode plus fresh source-note support or mark those claims as needing freshness check.

If the user accepts the slice and the task enters closure, queue a post-acceptance compounding review. When role-boundary gaps are discovered, create a role change proposal before any runtime role mutation.
