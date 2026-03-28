# Acceptance Review Refs

Read these refs when the `acceptance-review` bundle is active.

Recommended order:

1. [docs/workflows/volatile-research-default.md](../../../docs/workflows/volatile-research-default.md)
2. [docs/workflows/internal-research-routing.md](../../../docs/workflows/internal-research-routing.md)
3. [docs/workflows/task-artifact-routing.md](../../../docs/workflows/task-artifact-routing.md)
4. [docs/workflows/work-item-recovery-protocol.md](../../../docs/workflows/work-item-recovery-protocol.md)
5. [docs/workflows/post-acceptance-compounding-loop.md](../../../docs/workflows/post-acceptance-compounding-loop.md)

Use the `research` bundle `dispatch` mode when external volatile facts affect acceptance criteria.
Use an `Acceptance Ledger` when acceptance criteria or verification progress must survive more than one session; keep it update-only by advancing status, checklist rows, and evidence references instead of rewriting the full acceptance spec.
