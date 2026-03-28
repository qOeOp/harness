# Internal Research Routing

Canonical source:

- [docs/workflows/internal-research-routing.md](../../../docs/workflows/internal-research-routing.md)

Bundle-level routing rule:

1. `dispatch` is the front door when a volatile topic needs an owner, scope, or freshness window.
2. `memo` is the synthesis artifact after evidence collection.
3. If a work item exists, route both artifacts into `.harness/tasks/<task-id>/attachments/`.
4. Promote to shared surfaces only when explicit shared writeback is enabled and the output needs cross-task visibility.
