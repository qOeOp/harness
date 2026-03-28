---
name: memory-checkpoint
description: Use after a founder decision or a completed work cycle to write a task-local checkpoint first, then promote a shared snapshot only when truly needed.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).
Use [./templates/checkpoint.md](./templates/checkpoint.md) as the canonical checkpoint shape.

Default to task-local writeback first:

- `.harness/tasks/<task-id>/attachments/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/tasks/<task-id>/task.md` `## Recovery` when the goal is recovery

Canonical script surface:

- [./scripts/new_checkpoint.sh](./scripts/new_checkpoint.sh) `[--work-item <WI-xxxx>] <label>`
- add `--promote-shared-writeback` only when the snapshot truly needs cross-task visibility
- `--promote-governance` remains a compatibility alias

Only append `.harness/workspace/decisions/log/` and `.harness/workspace/status/snapshots/` when shared writeback is explicitly enabled and the checkpoint truly needs cross-task visibility.
