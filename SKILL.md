---
name: harness
description: Use when bootstrapping, updating, auditing, or restructuring the harness itself, including hosted-kernel contracts, repo-local .harness runtime layout, top-level surface reduction, and migration of framework source versus instance workspace.
---

# Harness

Use this skill when the task is about the harness system itself rather than a product feature.

This includes:

1. hosted-kernel design
2. `.harness/` runtime workspace
3. framework source versus runtime boundary
4. install / update / doctor / repair carrier design
5. top-level surface reduction
6. migration contracts for moving repo content into skill source or runtime

## Core Rule

The harness has two distinct homes, but this repository owns only one of them:

1. clean framework source in this repository
2. repo-local runtime and instance state in a separate consumer repo under `.harness/`

Do not introduce a third functional layer such as:

1. `legacy/`
2. `archive/`
3. `compat/`
4. “temporary canonical” directories

## Read In This Order

1. [references/layering.md](references/layering.md)
2. [references/runtime-workspace.md](references/runtime-workspace.md)
3. [references/contracts/minimum-core-runtime-tree.toml](references/contracts/minimum-core-runtime-tree.toml)
4. [references/top-level-surface.md](references/top-level-surface.md)

Only read additional framework specs if the task needs historical derivation.

## Expected Outputs

Prefer producing one of:

1. a tighter contract
2. a machine-readable inventory or schema
3. a migration script input
4. a reduced top-level surface

Avoid producing free-floating analysis without a concrete control artifact.

## Working Rules

1. Treat this repository root as the clean framework source carrier.
2. Treat `.harness/` as consumer-repo runtime, not as part of this source repo.
3. Treat installed `.agents/skills/harness/` as a projection target, not as source-of-truth inside this repo.
4. If a file does not belong to framework source or installation/projection logic, it should be deleted.
5. Prefer machine-readable contracts over prose-only plans.
6. Do not multiply provider-specific projections unless the projection strategy itself is the task.
