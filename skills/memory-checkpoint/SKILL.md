---
name: memory-checkpoint
description: Use after a founder decision or a completed work cycle to append a decision entry and a status snapshot.
---

Read [../../docs/memory/memory-architecture.md](../../docs/memory/memory-architecture.md) before making changes.
Read [../../docs/workflows/task-artifact-routing.md](../../docs/workflows/task-artifact-routing.md) before making changes.

Default to task-local writeback first:

- `.harness/tasks/<task-id>/outputs/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/tasks/<task-id>/progress.md` when the goal is recovery

Only append `.harness/workspace/decisions/log/` and `.harness/workspace/status/snapshots/` when `advanced governance mode` is explicitly enabled and the checkpoint truly needs cross-task visibility.
