---
name: research-dispatch
description: Use when an internal discussion touches volatile external facts and needs a research owner before formal decisions.
---

This is a compatibility entrypoint for the [research bundle](../research/SKILL.md).

Read [../research/manifest.toml](../research/manifest.toml).
Read [../research/SKILL.md](../research/SKILL.md).

Operate in `dispatch` mode.
Read [../research/refs/internal-research-routing.md](../research/refs/internal-research-routing.md).
Read [../research/refs/volatile-research-default.md](../research/refs/volatile-research-default.md).
Read [../research/refs/task-artifact-routing.md](../research/refs/task-artifact-routing.md).
Prefer [../research/templates/research-dispatch.md](../research/templates/research-dispatch.md).
Default to a task-local dispatch under `.harness/tasks/<task-id>/attachments/` before a volatile topic moves into formal requirements, research, or decision output.
Only promote the dispatch into `.harness/workspace/research/dispatches/` when `advanced governance mode` is explicitly enabled and the dispatch needs cross-task visibility.
