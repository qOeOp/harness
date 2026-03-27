# Task Artifact Routing

Canonical source:

- [docs/workflows/task-artifact-routing.md](../../../docs/workflows/task-artifact-routing.md)

Research-specific routing summary:

1. `research-dispatch`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md`
2. `research-memo`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-memo.md`
3. `source-note`
   - `.harness/tasks/<task-id>/attachments/sources/<date>-<slug>.md`

Default rule:

`task-local first, governance by explicit promotion`
