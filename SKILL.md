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

The harness has only two functional homes:

1. clean framework source in the local `harness` skill carrier
2. repo-local runtime and instance state in `.harness/`

Do not introduce a third functional layer such as:

1. `legacy/`
2. `archive/`
3. `compat/`
4. “temporary canonical” directories

## Read In This Order

1. [references/layering.md](references/layering.md)
2. [references/runtime-workspace.md](references/runtime-workspace.md)
3. [references/top-level-surface.md](references/top-level-surface.md)

Only read additional framework specs if the task needs historical derivation.

## Expected Outputs

Prefer producing one of:

1. a tighter contract
2. a machine-readable inventory or schema
3. a migration script input
4. a reduced top-level surface

Avoid producing free-floating analysis without a concrete control artifact.

## Working Rules

1. Treat `.agents/skills/harness/` as the future clean framework carrier.
2. Treat `.harness/` as the only repo-local runtime workspace.
3. If a file does not belong to either, it should be deleted.
4. Prefer machine-readable contracts over prose-only plans.
5. Do not multiply provider-specific projections unless the projection strategy itself is the task.
