---
name: research
description: Use when a task needs disciplined research routing or active evidence collection, especially when volatile external facts require fresh source notes before a memo or recommendation.
---

# Research

This bundle owns the `research` capability as one bounded entity.

It supports five primary operation modes:

1. `dispatch`
   - assign a research owner and freshness requirements before formal decisions
2. `brief`
   - scope the collection plan before broad search or crawling
3. `collect`
   - execute search, extraction, crawl, and local ingest
4. `source-note`
   - compress one source into durable evidence
5. `memo`
   - synthesize evidence, counter-evidence, unknowns, and recommendation

## Read Order

1. [manifest.toml](./manifest.toml)
2. [refs/README.md](./refs/README.md)
3. [refs/volatile-research-default.md](./refs/volatile-research-default.md)
4. [refs/internal-research-routing.md](./refs/internal-research-routing.md)
5. [refs/task-artifact-routing.md](./refs/task-artifact-routing.md)
6. [refs/collection-operating-model.md](./refs/collection-operating-model.md)
7. [refs/tool-routing.md](./refs/tool-routing.md)
8. [refs/source-evaluation.md](./refs/source-evaluation.md)
9. [refs/runtime-contract.md](./refs/runtime-contract.md)

## Default Operating Sequence

1. Determine whether the topic is `stable`, `volatile-by-default`, or `unknown`.
2. If the topic is volatile and no research owner exists yet, start with `dispatch`.
3. Use `brief` when the collection plan is non-trivial or the topic spans many sources.
4. Use `collect` with the cheapest reliable route:
   - `search` for discovery
   - `extract-url` for known URLs
   - `crawl` for bounded same-host coverage
   - `ingest-local` for repo-local or local documents
5. Convert durable evidence into `source-note` artifacts before formal recommendations.
6. Use `evidence ledger` only when the run is long, multi-source, or likely to be resumed by another operator.
7. Produce a `memo` only after the evidence boundary is clear enough to separate:
   - evidence
   - counter-evidence
   - unknowns
   - recommendation
8. Default all formal outputs to `.harness/tasks/<task-id>/attachments/`.

Only promote to `.harness/workspace/*` when `advanced governance mode` is explicitly enabled and the research truly needs cross-task visibility.

## Artifact Posture

1. `source-note` is the default evidence artifact.
2. `memo` is the default synthesis artifact.
3. `research brief` is optional but preferred for non-trivial collection.
4. `evidence ledger` is optional and should not be mandatory paperwork.
5. `raw capture` is not a default formal artifact.
   - Keep raw material only when it is hard to reproduce, highly volatile, or needed for audit.
   - Prefer task-local `working/` or another non-canonical cache surface over formal attachment routing.

## Preferred Assets

1. Dispatch template: [templates/research-dispatch.md](./templates/research-dispatch.md)
2. Memo template: [templates/research-memo.md](./templates/research-memo.md)
3. Brief template: [templates/research-brief.md](./templates/research-brief.md)
4. Source-note template: [templates/source-note.md](./templates/source-note.md)
5. Optional ledger template: [templates/evidence-ledger.md](./templates/evidence-ledger.md)
6. Dispatch script: [scripts/new_dispatch.sh](./scripts/new_dispatch.sh)
7. Memo script: [scripts/new_memo.sh](./scripts/new_memo.sh)
8. Brief script: [scripts/new_brief.sh](./scripts/new_brief.sh)
9. Source-note script: [scripts/new_source_note.sh](./scripts/new_source_note.sh)
10. Optional ledger script: [scripts/new_ledger.sh](./scripts/new_ledger.sh)
11. Runtime control: [../../scripts/research_ctl.sh](../../scripts/research_ctl.sh)

## Output Expectation

Prefer artifact-first execution:

1. write the formal dispatch, source-note, or memo to a task-local artifact
2. use optional brief and optional ledger only when they reduce confusion
3. return the artifact path
4. keep only the summary and next action in the main conversation context
