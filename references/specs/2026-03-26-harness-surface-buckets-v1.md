# Harness Surface Buckets v1

- Status: proposal
- Date: 2026-03-26
- Scope: classify the current repository surface into `core task runtime`, `advanced governance mode`, `internal plumbing`, and `delete`
- Design center: [2026-03-25-harness-invoke-first-vnext-spec-v1.md](./2026-03-25-harness-invoke-first-vnext-spec-v1.md)

## Divergent Hypotheses

1. Keep a single mixed surface
   - task execution, company governance, provider adapters, and source-maintainer plumbing all coexist in the default story
2. Split into two products
   - one product for task execution
   - one separate product for governance
3. Keep one product with four explicit buckets
   - `core task runtime`
   - `advanced governance mode`
   - `internal plumbing`
   - `delete`

## First Principles

`core task runtime` exists to answer:

1. what is the task
2. what is the current state
3. how do we resume
4. what artifacts belong to this task
5. how do we close it cleanly

`advanced governance mode` exists to answer:

1. how multiple streams of work stay coordinated over time
2. who owns decisions and escalation
3. what cadence, audits, and organizational memory exist above a single task

`internal plumbing` exists to answer:

1. how this source repo is maintained
2. how optional provider packaging works
3. how source-level audits and generation keep the framework honest

`delete` means:

1. the item conflicts with invoke-first
2. the item only exists to support install-first or overlay-first assumptions
3. the item should not survive as an active surface

## Convergence

The correct default product surface is:

1. a small `core task runtime`
2. an opt-in `advanced governance mode`
3. hidden `internal plumbing`
4. aggressive deletion of overlay-first leftovers

## Core Task Runtime

These files or surfaces belong to the default `/harness` experience.

### References

1. `references/layering.md`
   - keep, but rewrite around invoke -> optional runtime -> internal packaging
2. `references/runtime-workspace.md`
   - keep, but rewrite around minimal task runtime
3. `references/top-level-surface.md`
   - keep, but rewrite around zero-ceremony invocation and no default top-level takeover

### Workflows

1. `docs/workflows/document-routing-and-lifecycle.md`
   - core entry and lifecycle logic, but must be rewritten around `/harness`
2. `docs/workflows/decision-workflow.md`
   - keep as the task-level decision spine
3. `docs/workflows/internal-research-routing.md`
   - keep for volatile or evidence-heavy tasks
4. `docs/workflows/volatile-research-default.md`
   - keep for freshness discipline
5. `docs/workflows/work-item-progress-protocol.md`
   - keep as a core recovery primitive
6. `docs/workflows/work-item-interrupt-protocol.md`
   - keep as a core pause/resume primitive
7. `docs/workflows/code_review.md`
   - keep when `/harness` is used on code tasks

### Skills

1. `skills/brainstorming-session/SKILL.md`
   - keep as early-stage task framing
2. `skills/acceptance-review/SKILL.md`
   - keep as a task closure and quality primitive
3. `skills/decision-pack/SKILL.md`
   - keep for explicit decision packaging
4. `skills/memory-checkpoint/SKILL.md`
   - keep for resumability
5. `skills/requirements-meeting/SKILL.md`
   - keep as a task-framing surface
6. `skills/research-dispatch/SKILL.md`
   - keep for volatile external questions
7. `skills/research-memo/SKILL.md`
   - keep for evidence-bearing work

### Scripts

1. `scripts/lib_state.sh`
   - core state helper layer
2. `scripts/new_work_item.sh`
   - core task creation
3. `scripts/work_item_ctl.sh`
   - core task control surface
4. `scripts/select_work_item.sh`
   - core task routing
5. `scripts/open_current_work_item.sh`
   - core current-task opener
6. `scripts/start_work_item.sh`
   - core controlled start
7. `scripts/pause_work_item.sh`
   - core controlled pause
8. `scripts/resume_work_item.sh`
   - core controlled resume
9. `scripts/transition_work_item.sh`
   - core transition engine
10. `scripts/update_work_item_fields.sh`
    - core task mutation support
11. `scripts/complete_work_item.sh`
    - core closure
12. `scripts/finalize_work_item.sh`
    - core terminal-state handling
13. `scripts/upsert_work_item_progress.sh`
    - core recovery writeback
14. `scripts/link_work_item_artifact.sh`
    - core artifact linkage
15. `scripts/new_decision.sh`
    - core task-level decision artifact
16. `scripts/new_research.sh`
    - core research artifact
17. `scripts/new_research_dispatch.sh`
    - core dispatch artifact
18. `scripts/new_source_note.sh`
    - core source evidence artifact
19. `scripts/new_checkpoint.sh`
    - core resumability artifact, but semantics should be reduced to task scope
20. `scripts/archive_brief.sh`
    - core archive support, if briefs remain part of the reduced runtime
21. `scripts/prune_brief_redirects.sh`
    - core cleanup support, if reduced runtime still uses redirect stubs
22. `scripts/validate_freshness_gate.sh`
    - core protection for volatile external conclusions
23. `scripts/sweep_state_drift.sh`
    - core runtime hygiene

## Advanced Governance Mode

These surfaces remain valuable, but they should only appear after an explicit upgrade from a single-task runtime into a broader operating system.

### Organization

1. `docs/organization/company-os-runtime-data-map.md`
2. `docs/organization/compounding-engineering-lead.md`
3. `docs/organization/decision-rights.md`
4. `docs/organization/department-map.md`
5. `docs/organization/org-chart.md`

Reason:
they define an organization, not a default task protocol.

### Governance Workflows

1. `docs/workflows/company-bootstrap-loop.md`
2. `docs/workflows/founder-governance-meeting-loop.md`
3. `docs/workflows/founder-intake-evolution-loop.md`
4. `docs/workflows/founder-meeting-taxonomy.md`
5. `docs/workflows/governance-surface-audit.md`
6. `docs/workflows/process-compounding-cadence.md`
7. `docs/workflows/board-refresh-ledger.md`
8. `docs/workflows/retrospective-compaction-and-trap-check.md`
9. `docs/workflows/work-item-trace-taxonomy.md`
10. `docs/workflows/worktree-parallelism.md`
11. `docs/workflows/agile-runnable-demo-policy.md`

Reason:
these govern recurring coordination, escalation, institutional memory, or multi-stream operation above a single task.

### Governance Skills

1. `skills/daily-digest/SKILL.md`
2. `skills/founder-brief/SKILL.md`
3. `skills/governance-meeting/SKILL.md`
4. `skills/meeting-router/SKILL.md`
5. `skills/os-audit/SKILL.md`
6. `skills/process-audit/SKILL.md`
7. `skills/retro/SKILL.md`
8. `skills/vision-meeting/SKILL.md`

Reason:
they are not needed for a default `/harness` task loop, but they become useful once the user upgrades into a longer-running governance system.

### Governance Scripts

1. `scripts/new_company_digest.sh`
2. `scripts/new_daily_report.sh`
3. `scripts/new_intake.sh`
4. `scripts/new_retro.sh`
5. `scripts/refresh_boards.sh`
6. `scripts/report_brief_registry.sh`
7. `scripts/report_brief_working_set.sh`
8. `scripts/render_founder_review_page.js`
9. `scripts/render_founder_review_page.sh`

Reason:
these are higher-order coordination utilities, not minimum task runtime controls.

## Internal Plumbing

These surfaces may remain in the source repo, but they should not be part of the user-facing story.

### Source-Maintainer Docs

1. `docs/project-structure.md`
   - internal source-repo map after rewrite
2. `docs/workflows/tool-adapter-capability-map.md`
   - internal adapter honesty reference
3. `docs/workflows/provider-deltas/codex.md`
   - internal provider delta
4. `docs/workflows/provider-deltas/gemini.md`
   - internal provider delta
5. `roles/README.md`
   - internal role-source maintenance guide

### Roles

1. `roles/*.md`

Reason:
roles remain useful for internal execution design, but they should not be the user's first mental model of `/harness`.

### Source-Maintainer Scripts

1. `scripts/audit_doc_style.sh`
2. `scripts/audit_document_system.sh`
3. `scripts/audit_local_commit_signing.sh`
4. `scripts/audit_repo_trust_boundary.sh`
5. `scripts/audit_role_schema.sh`
6. `scripts/audit_state_system.sh`
7. `scripts/backfill_interrupt_fields.sh`
8. `scripts/cleanup_terminal_work_item.sh`
9. `scripts/edit_role.sh`
10. `scripts/enable_git_hooks.sh`
11. `scripts/github_projects_sync_adapter.sh`
12. `scripts/new_role.sh`
13. `scripts/new_worktree.sh`
14. `scripts/rehash_state_events.sh`
15. `scripts/run_governance_surface_diagnostic.sh`
16. `scripts/run_state_validation_slice.sh`
17. `scripts/setup_local_ssh_commit_signing.sh`
18. `scripts/sync_agent_projections.sh`
19. `scripts/sync_claude_skill_projections.sh`
20. `scripts/validate_source_repo.sh`
21. `scripts/validate_workspace.sh`

Reason:
these keep the source repo and optional packaging honest, but they are not the primary product verbs.

## Delete

These surfaces conflict with invoke-first or are no longer worth keeping active.

1. `scripts/sync_tool_entrypoints.sh`
   - delete from active surface
   - it only exists to preserve overlay-first mirrored entrypoints
2. `references/specs/2026-03-25-harness-framework-and-dogfood-layering-spec-v2.md`
   - already deleted from active surface
3. `references/specs/2026-03-25-top-level-surface-reduction-spec-v1.md`
   - already deleted from active surface
4. `scripts/audit_tool_parity.sh`
   - already deleted from active surface

## Sharp Boundary

If the user invokes `/harness` and expects help with one task, they should mostly touch:

1. `core task runtime`

If the user explicitly wants a persistent operating system with recurring rituals, organizational roles, and escalation paths, then they may upgrade into:

1. `advanced governance mode`

Everything else should either stay hidden as:

1. `internal plumbing`

or disappear from active surface as:

1. `delete`
