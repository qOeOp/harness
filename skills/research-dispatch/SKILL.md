---
name: research-dispatch
description: Use when an internal discussion touches volatile external facts and needs a research owner before formal decisions.
---

Read [../../docs/workflows/internal-research-routing.md](../../docs/workflows/internal-research-routing.md).
Read [../../docs/workflows/volatile-research-default.md](../../docs/workflows/volatile-research-default.md).
Read [../../docs/workflows/task-artifact-routing.md](../../docs/workflows/task-artifact-routing.md).
Use [../../docs/templates/research-dispatch.md](../../docs/templates/research-dispatch.md).
Default to a task-local dispatch under `.harness/tasks/<task-id>/working/` before a volatile topic moves into formal requirements, research, or decision output.
Only promote the dispatch into `.harness/workspace/research/dispatches/` when `advanced governance mode` is explicitly enabled and the dispatch needs cross-task visibility.
