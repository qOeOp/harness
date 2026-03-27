---
name: memory-checkpoint
description: Use after a founder decision or a completed work cycle to write a task-local checkpoint first, then promote a governance snapshot only when truly needed.
---

Read [../../docs/memory/memory-architecture.md](../../docs/memory/memory-architecture.md) before making changes.
Read [../../docs/workflows/task-artifact-routing.md](../../docs/workflows/task-artifact-routing.md) before making changes.

Default to task-local writeback first:

- `.harness/tasks/<task-id>/attachments/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/tasks/<task-id>/task.md` `## Recovery` when the goal is recovery

Canonical script surface:

- `./scripts/new_checkpoint.sh [--work-item <WI-xxxx>] <label>`
- add `--promote-governance` only when the snapshot truly needs cross-task visibility

Only append `.harness/workspace/decisions/log/` and `.harness/workspace/status/snapshots/` when `advanced governance mode` is explicitly enabled and the checkpoint truly needs cross-task visibility.
