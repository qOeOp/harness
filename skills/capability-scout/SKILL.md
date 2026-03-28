---
name: capability-scout
description: Use when scouting external skills, agents, repos, or workflows and converting the best patterns into a local harness capability.
---

# Capability Scout

This bundle owns the `capability-scout` meta layer.

It exists for one reusable loop:

1. find external capability candidates
2. compare them against first-principles needs
3. decide what to adopt, wrap, port, mimic, or reject
4. turn the result into a local harness skill plan

## Read Order

1. [manifest.toml](./manifest.toml)
2. [refs/README.md](./refs/README.md)
3. [refs/scouting-loop.md](./refs/scouting-loop.md)
4. [refs/absorption-criteria.md](./refs/absorption-criteria.md)
5. [refs/output-contract.md](./refs/output-contract.md)

## Default Operating Sequence

1. Define the target capability and the non-negotiable constraints.
2. Search the ecosystem for skills, agents, repos, or focused components.
3. Separate candidates into:
   - adopt
   - wrap
   - port
   - mimic
   - reject
4. Produce a `capability scout report`.
5. If one or more candidates are absorbable, produce a `skill absorption plan`.
6. Only then implement the new local bundle.

## Preferred Assets

1. Scout template: [templates/capability-scout-report.md](./templates/capability-scout-report.md)
2. Absorption template: [templates/skill-absorption-plan.md](./templates/skill-absorption-plan.md)
3. Scout script: [scripts/new_scout_report.sh](./scripts/new_scout_report.sh)
4. Absorption script: [scripts/new_absorption_plan.sh](./scripts/new_absorption_plan.sh)

## Output Expectation

Prefer artifact-first execution:

1. write the scout report
2. write the absorption plan
3. implement only the bounded local slice that survives evaluation
