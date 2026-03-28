---
name: harness
description: Use when updating, auditing, or restructuring the harness execution substrate itself, including source-repo contracts, capability-bundle surfaces, task-record runtime layout, and top-level surface reduction.
---

# Harness

Use this skill when the task is about the harness system itself rather than a product feature.

This includes:

1. agent execution substrate design
2. `.harness/` task-record runtime workspace
3. capability-bundle and role surface design
4. source-repo contract, audit, and runtime materialization design
5. top-level surface reduction and compaction
6. machine-readable runtime contracts and verification surfaces

## Core Rule

The harness has two distinct homes, but this repository owns only one of them:

1. clean framework source in this repository
2. repo-local runtime and instance state in a separate consumer repo under `.harness/`

Do not introduce a third functional layer such as:

1. `legacy/`
2. `archive/`
3. “temporary canonical” directories

## Read In This Order

1. [references/layering.md](references/layering.md)
2. [references/runtime-workspace.md](references/runtime-workspace.md)
3. [references/contracts/task-record-runtime-tree-v2.toml](references/contracts/task-record-runtime-tree-v2.toml)
4. [references/top-level-surface.md](references/top-level-surface.md)

Only read additional framework specs if the task needs historical derivation.

## Expected Outputs

Prefer producing one of:

1. a tighter contract
2. a machine-readable inventory or schema
3. a reduced top-level surface
4. a sharper verification surface

Avoid producing free-floating analysis without a concrete control artifact.

## Working Rules

1. Treat this repository root as the clean framework source repo.
2. Treat `.harness/` as consumer-repo runtime, not as part of this source repo.
3. Treat any installed harness copy outside this repo as user-managed distribution, not as source-of-truth inside this repo.
4. If a file does not belong to framework source, runtime contract, or explicit archive, it should be deleted.
5. Prefer machine-readable contracts over prose-only plans.
6. Do not multiply provider-specific projections or provider-owned overlays.
