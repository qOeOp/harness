# Layering

Canonical layering model:

1. invoke surface
   - user enters through `/harness`
   - no install ritual is required before first value
2. optional task runtime
   - `.harness/`
   - appears only when the task needs continuity, traceability, or resumability
3. advanced governance mode
   - organization, cadence, escalation, and cross-task coordination
   - only enabled when the user explicitly upgrades beyond a single-task runtime
4. internal packaging and source maintenance
   - this repository
   - owns `SKILL.md`, `skills/`, `roles/`, `scripts/`, `docs/`, `references/`
   - may keep optional provider packaging, but that is not the primary product mental model

Boundary reminder:

1. `/harness` is the primary product entrypoint
2. `.harness/` is runtime state, not a prerequisite
3. advanced governance is not baseline task usage
4. provider packaging and source-repo maintenance are internal concerns, not the main story
