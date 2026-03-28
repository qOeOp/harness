# Layering

Canonical layering model:

1. invoke surface
   - user enters through `/harness`
   - no install ritual is required before first value
2. optional task runtime
   - `.harness/`
   - appears only when the task needs continuity, traceability, or resumability
3. optional cross-task mode
   - decision logs, digests, founder queues, and other derived views
   - only enabled when the user explicitly upgrades beyond a single-task runtime
4. internal source maintenance
   - this repository
   - owns `SKILL.md`, `skills/`, `roles/`, `scripts/`, `docs/`, `references/`
   - may keep archive and maintenance-only derivation, but that is not the primary product mental model

Boundary reminder:

1. `/harness` is the primary product entrypoint
2. `.harness/` is runtime state, not a prerequisite
3. cross-task views are not baseline task usage
4. source-repo maintenance is an internal concern, not the main story
