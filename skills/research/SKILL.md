---
name: research
description: Use when a task needs disciplined research routing, especially when volatile external facts may require a dispatch before a memo or recommendation.
---

# Research

This bundle owns the `research` capability as one bounded entity.

It supports two primary output modes:

1. `dispatch`
   - assign a research owner and freshness requirements before formal decisions
2. `memo`
   - synthesize evidence, counter-evidence, unknowns, and recommendation

## Read Order

1. [manifest.toml](./manifest.toml)
2. [refs/README.md](./refs/README.md)
3. [refs/volatile-research-default.md](./refs/volatile-research-default.md)
4. [refs/internal-research-routing.md](./refs/internal-research-routing.md)
5. [refs/task-artifact-routing.md](./refs/task-artifact-routing.md)

## Default Operating Sequence

1. Determine whether the topic is `stable`, `volatile-by-default`, or `unknown`.
2. If the topic is volatile and no research owner exists yet, start with `dispatch`.
3. Gather fresh official sources or source-note support before producing formal recommendations.
4. Produce a `memo` only after the evidence boundary is clear enough to separate:
   - evidence
   - counter-evidence
   - unknowns
   - recommendation
5. Default all formal outputs to `.harness/tasks/<task-id>/attachments/`.

Only promote to `.harness/workspace/*` when `advanced governance mode` is explicitly enabled and the research truly needs cross-task visibility.

## Preferred Assets

1. Dispatch template: [templates/research-dispatch.md](./templates/research-dispatch.md)
2. Memo template: [templates/research-memo.md](./templates/research-memo.md)
3. Dispatch script: [scripts/new_dispatch.sh](./scripts/new_dispatch.sh)
4. Memo script: [scripts/new_memo.sh](./scripts/new_memo.sh)

## Output Expectation

Prefer artifact-first execution:

1. write the formal dispatch or memo to a task-local artifact
2. return the artifact path
3. keep only the summary and next action in the main conversation context
