#!/bin/sh
set -eu

quiet="${1:-}"
ok=1

say() {
  [ "$quiet" = "--quiet" ] || echo "$1"
}
fail() {
  ok=0
  say "$1"
}
require_file() {
  [ -e "$1" ] || fail "missing: $1"
}
require_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
}

require_exec() {
  [ -x "$1" ] || fail "not executable: $1"
}

require_contains() {
  file="$1"
  pattern="$2"
  grep -Fq -- "$pattern" "$file" || fail "missing pattern '$pattern' in $file"
}

require_redirect_stub() {
  file="$1"
  target="$2"
  require_contains "$file" 'Legacy redirect only.'
  require_contains "$file" "$target"
  require_contains "$file" 'skill-owned template'
}

require_legacy_redirect_stub() {
  file="$1"
  target="$2"
  require_contains "$file" 'Legacy redirect only.'
  require_contains "$file" "$target"
}

forbid_contains() {
  file="$1"
  pattern="$2"
  if grep -Fq -- "$pattern" "$file"; then
    fail "found retired pattern '$pattern' in $file"
  fi
}

forbidden_path() {
  [ ! -e "$1" ] || fail "source repo must not contain consumer/runtime surface: $1"
}

require_files() {
  for path in "$@"; do
    require_file "$path"
  done
}

require_dirs() {
  for path in "$@"; do
    require_dir "$path"
  done
}

require_execs() {
  for path in "$@"; do
    require_exec "$path"
  done
}

forbidden_paths() {
  for path in "$@"; do
    forbidden_path "$path"
  done
}

require_patterns() {
  file="$1"
  shift
  for pattern in "$@"; do
    require_contains "$file" "$pattern"
  done
}

forbid_patterns() {
  file="$1"
  shift
  for pattern in "$@"; do
    forbid_contains "$file" "$pattern"
  done
}

require_redirect_pairs() {
  while [ "$#" -gt 1 ]; do
    require_redirect_stub "$1" "$2"
    shift 2
  done
}

require_legacy_redirect_pairs() {
  while [ "$#" -gt 1 ]; do
    require_legacy_redirect_stub "$1" "$2"
    shift 2
  done
}

require_files "SKILL.md"
require_dirs "skills" "roles" "scripts" "docs" "references"

for skill_dir in skills/*; do
  [ -d "$skill_dir" ] || continue
  require_file "$skill_dir/SKILL.md"
  require_file "$skill_dir/manifest.toml"
  require_file "$skill_dir/refs/README.md"
done

require_dirs "references/contracts" "skills/research"
require_files \
  "docs/project-structure.md" "docs/charter/harness-charter.md" \
  "docs/memory/memory-architecture.md" "references/layering.md" \
  "references/runtime-workspace.md" "references/contracts/task-record-runtime-tree-v2.toml" \
  "references/contracts/active-surface-entropy-budget-v1.toml" "references/top-level-surface.md" \
  "references/specs/README.md" "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" \
  "docs/organization/decision-rights.md" "roles/README.md" \
  "roles/runtime-role-manager.md" "skills/research/SKILL.md" \
  "skills/research/manifest.toml" "skills/research/refs/README.md" \
  "skills/research/templates/research-dispatch.md" "skills/research/templates/research-brief.md" \
  "skills/research/templates/research-memo.md" "skills/research/templates/source-note.md" \
  "skills/research/templates/evidence-ledger.md" "skills/acceptance-review/templates/acceptance-ledger.md" \
  "scripts/research/browser_extract.py" "scripts/research/crawl4ai_extract.py" \
  "scripts/research/lib_extract.py" "scripts/research/lib_local_browser.py" \
  "scripts/research/lib_runtime_paths.py" "scripts/research/lib_search.py" \
  "scripts/research/local_browser_profiles.py" "scripts/research/run_crawl4ai_isolated.sh" \
  "scripts/research/search_auto.py" "docs/workflows/agent-operator-contract.md" \
  "docs/workflows/consumer-runtime-routing.md" "docs/workflows/task-artifact-routing.md" \
  "docs/workflows/post-acceptance-compounding-loop.md" "docs/workflows/surface-audit.md" \
  "docs/workflows/provider-deltas/gemini.md" "docs/workflows/tool-adapter-capability-map.md" \
  "docs/templates/role-change-proposal.md" "skills/os-audit/templates/surface-audit.md"

require_execs \
  "scripts/materialize_runtime_fixture.sh" "scripts/run_surface_diagnostic.sh" \
  "scripts/run_governance_surface_diagnostic.sh" "scripts/run_shared_writeback_surface_diagnostic.sh" \
  "scripts/audit_entropy_budget.sh" "scripts/run_state_validation_slice.sh" \
  "scripts/audit_role_schema.sh" "scripts/new_role.sh" \
  "scripts/edit_role.sh" "scripts/enforce_role_policy.sh" \
  "scripts/resolve_consumer_runtime_root.sh" "scripts/new_role_change_proposal.sh" \
  "scripts/runtime_role_manager.sh" "scripts/research_ctl.sh" \
  "scripts/research/run_crawl4ai_isolated.sh" "skills/research/scripts/new_dispatch.sh" \
  "skills/research/scripts/new_brief.sh" "skills/research/scripts/new_memo.sh" \
  "skills/research/scripts/new_source_note.sh" "skills/research/scripts/new_ledger.sh" \
  "skills/decision-pack/scripts/new_decision.sh" "skills/memory-checkpoint/scripts/new_checkpoint.sh" \
  "skills/acceptance-review/scripts/new_acceptance_ledger.sh" "scripts/new_acceptance_ledger.sh"

forbidden_paths \
  ".harness" ".agents/skills/harness" "AGENTS.md" "CLAUDE.md" "GEMINI.md" \
  "README_CLAUDE.md" "README_CODEX.md" "README_GEMINI.md" ".claude" ".codex" ".gemini" \
  "roles/learning-evolution-lead.md" "roles/market-intelligence-lead.md" "roles/position-operations-lead.md" \
  "roles/risk-office-lead.md" "roles/strategy-research-lead.md" "skills/research-memo" \
  "skills/research-dispatch" "skills/researcher" "skills/daily-digest" "skills/governance-meeting" \
  "skills/retro" "scripts/researcher" "scripts/researcher_ctl.sh" \
  "scripts/new_researcher_brief.sh" "scripts/new_company_digest.sh" "scripts/new_daily_report.sh" \
  "scripts/new_retro.sh" "docs/workflows/founder-governance-meeting-loop.md" \
  "docs/workflows/company-bootstrap-loop.md" "docs/charter/company-charter.md" \
  "docs/organization/org-chart.md" "docs/organization/workstream-map.md" \
  "docs/organization/governance-capability-map.md" "docs/organization/company-os-runtime-data-map.md" \
  "docs/organization/compounding-engineering-lead.md" "docs/templates/company-daily-digest.md" \
  "docs/templates/governance-meeting-brief.md" "docs/templates/daily-workstream-report.md" \
  "docs/templates/workstream-bootstrap-brief.md" "docs/templates/workstream-retro.md" \
  "references/specs/2026-03-25-harness-invoke-first-vnext-spec-v1.md" \
  "references/specs/2026-03-25-harness-vnext-round1-reduction-inventory-v1.toml" \
  "references/specs/2026-03-26-harness-surface-buckets-v1.md" \
  "references/specs/2026-03-27-codex-worktree-convergence-matrix-v1.md"

require_contains "docs/memory/memory-architecture.md" '默认 runtime memory 是 `task-scoped`'
require_contains "docs/memory/memory-architecture.md" '.harness/tasks/<task-id>/task.md'
require_contains "docs/memory/memory-architecture.md" 'cross-task mode'
require_contains "docs/memory/memory-architecture.md" 'task.md` 既负责任务真相，也负责恢复协议。'
require_contains "docs/memory/memory-architecture.md" 'project memory / subagent memory'
require_contains "docs/memory/memory-architecture.md" 'provider-side stored state'
require_contains "docs/memory/memory-architecture.md" 'capture / redaction / disable policy'
require_contains "README.md" 'control surfaces'
require_contains "docs/workflows/agent-operator-contract.md" '在 framework source repo 中，先看 `SKILL.md`、`references/layering.md` 与 `references/runtime-workspace.md`'
require_contains "docs/workflows/agent-operator-contract.md" '在 materialized consumer runtime 中，先看 `.harness/entrypoint.md`'
require_contains "docs/workflows/agent-operator-contract.md" '`prompt shape / runtime config surface`'
require_contains "docs/workflows/agent-operator-contract.md" 'exact-prefix 稳定'
require_contains "docs/workflows/task-artifact-routing.md" '`task-local first, shared writeback by explicit promotion`'
require_contains "docs/workflows/task-artifact-routing.md" '.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md'
require_contains "skills/research/SKILL.md" 'This bundle owns the `research` capability as one bounded entity.'
require_contains "skills/research/manifest.toml" 'bundle_slug = "research"'
require_contains "skills/research/manifest.toml" 'operation_modes = ['
require_contains "skills/decision-pack/manifest.toml" 'bundle_slug = "decision-pack"'
require_contains "skills/memory-checkpoint/manifest.toml" 'bundle_slug = "memory-checkpoint"'
require_contains "skills/acceptance-review/manifest.toml" 'bundle_slug = "acceptance-review"'
require_contains "skills/acceptance-review/manifest.toml" 'acceptance-ledger'
require_contains "scripts/new_research.sh" 'skills/research/templates/research-memo.md'
require_contains "scripts/new_research_dispatch.sh" 'skills/research/templates/research-dispatch.md'
require_contains "scripts/new_research_brief.sh" 'skills/research/templates/research-brief.md'
require_contains "scripts/new_source_note.sh" 'skills/research/templates/source-note.md'
require_contains "scripts/new_decision.sh" 'skills/decision-pack/templates/decision-pack.md'
require_contains "scripts/new_checkpoint.sh" 'skills/memory-checkpoint/templates/checkpoint.md'
require_contains "scripts/new_acceptance_ledger.sh" 'skills/acceptance-review/templates/acceptance-ledger.md'
require_contains "roles/general-manager.md" '`research` bundle 的 `dispatch` mode'
require_contains "skills/meeting-router/SKILL.md" '`research` bundle `dispatch` requirements'
require_contains "skills/decision-pack/SKILL.md" '.harness/tasks/<task-id>/attachments/'
require_contains "skills/acceptance-review/SKILL.md" 'Acceptance Ledger'
require_contains "skills/acceptance-review/SKILL.md" 'update-only'
require_contains "skills/acceptance-review/templates/acceptance-ledger.md" 'Current acceptance status (update-only ledger; status / checklist / evidence reference):'
require_contains "docs/workflows/provider-deltas/codex.md" 'prompt shape stability'
require_contains "docs/workflows/provider-deltas/codex.md" 'tool 集合或枚举顺序'
require_contains "docs/workflows/provider-deltas/gemini.md" 'harness 不生成、不修改这些文件'
require_contains "docs/workflows/provider-deltas/gemini.md" 'Projection Config Changes Are Explicit Boundaries'
require_contains "docs/workflows/tool-adapter-capability-map.md" 'harness 不生成、不修改、不校验'
require_contains "docs/workflows/tool-adapter-capability-map.md" '名字路由 / 地址簿同样属于 user-owned integration'
require_contains "docs/workflows/tool-adapter-capability-map.md" '`roots/list`'
for needle in '`roots/list`' 'host-managed auth' '`tool_use` / `tool_result` `_meta`'; do require_contains "docs/workflows/tool-adapter-capability-map.md" "$needle"; done
for needle in 'discovery scope + operational boundary' 'path 映射' 'tool annotation / execution metadata' 'untrusted server' 'planning + safety surface' 'cheap、idempotent、re-entrant'; do require_contains "docs/workflows/tool-adapter-capability-map.md" "$needle"; done
for needle in 'discovery scope + operational boundary' 'path mapping' '`roots/list`' 'host-managed auth'; do require_contains "roles/workflow-automation-lead.md" "$needle"; done
require_contains "skills/research/refs/runtime-contract.md" 'configured SearXNG instance'
require_contains "skills/research/refs/runtime-contract.md" 'optional heavy-duty headless crawler'
require_contains "skills/research/refs/runtime-contract.md" '.harness/runtime/research/'
for needle in '.harness/runtime/' 'explicit schema / format version' 'migrate or fail closed' 'provider-side stored state' 'zero-retention / ZDR-safe 前提' 'wakeup handle + deadline / expiry' 'stable operation id' 'shadow polling state'; do require_contains "references/runtime-workspace.md" "$needle"; done
require_contains "docs/project-structure.md" '.harness/runtime/'
require_contains "docs/project-structure.md" 'capability-specific templates 默认放在 `skills/*/templates/`'
require_contains "skills/research/manifest.toml" '.harness/runtime/research/'
forbid_contains "skills/research/manifest.toml" 'docs/templates/'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" '.harness/runtime'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'durable_state_requires_explicit_version = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'slow_human_gates_require_pause_resume = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'resume_is_checkpoint_relative_reentry = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'checkpoint_durability_or_flush_boundary_must_be_explicit = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'async_delivery_model = "at-least-once"'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'exact_prefix_stability_is_runtime_discipline = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'mid_run_config_change_requires_explicit_transition = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'runtime_revision_binding_required = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'active_run_must_not_silent_hot_swap = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'source_provenance_must_survive_display_projection = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'required_metadata_files = ['
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'stale_reclaim_policy = "expired-lease-or-dead-pid"'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'active_statuses_require_assignee_worktree_claim = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'runtime_local_support_roots_may_be_explicit = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'capability_is_not_agent_identity = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'skill_surface_is_not_standalone_enforcement = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'remote_or_user_supplied_bundle_is_untrusted_until_curated = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'executable_bundle_catalog_requires_review_and_version_pin = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'user_selectable_bundle_is_not_security_baseline = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'bundle_local_memory_is_instruction_surface_when_auto_injected = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'bundle_local_memory_is_persisted_data_when_durable = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'worker_large_or_structured_results_should_write_to_artifact_first = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'worker_return_should_prefer_handle_locator_or_summary = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'multi_level_transcript_copy_chain_is_anti_pattern = true'
require_contains "roles/README.md" '本仓库不再维护 provider-owned generated role mirrors'
require_contains "roles/README.md" '.harness/workspace/roles/'
require_contains "roles/README.md" '`runtime-role-manager`'
require_contains "roles/README.md" '`policy_allowed_entrypoints`'
require_contains "roles/README.md" '这些角色是 execution substrate 的路由节点，不是公司职位投影。'
require_contains "roles/general-manager.md" '必须推动任务进入 `paused` 并写清 `resume target`'
require_contains "roles/compounding-engineering-lead.md" 'remote / marketplace / user-supplied skill 默认视为潜在不可信的 instruction + code surface'
require_contains "roles/compounding-engineering-lead.md" '20-50 个真实失败、真实工单或代表性边界条件'
require_contains "roles/compounding-engineering-lead.md" 'regression sample'
require_contains "docs/workflows/consumer-runtime-routing.md" 'consumer runtime route table'
require_contains "docs/workflows/consumer-runtime-routing.md" '$HOME/.harness/consumer-runtime-routes.tsv'
require_contains "docs/workflows/consumer-runtime-routing.md" '`--consumer-runtime <name>`'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'Prompt Shape / Runtime Config Boundary'
require_contains "docs/memory/memory-architecture.md" 'prompt shape / runtime config surface'
require_contains "docs/workflows/post-acceptance-compounding-loop.md" 'completion candidate -> acceptance -> compounding review -> role change proposal -> runtime-role-manager execution'
require_contains "docs/workflows/task-artifact-routing.md" 'role-change-proposal.md'
require_contains "docs/workflows/task-artifact-routing.md" 'Acceptance Ledger'
require_contains "docs/workflows/task-artifact-routing.md" 'update-only'
require_contains "docs/workflows/agent-operator-contract.md" 'scripts/runtime_role_manager.sh'
require_contains "docs/workflows/agent-operator-contract.md" '`policy_*`'
require_contains "docs/workflows/agent-operator-contract.md" 'paused + interrupt metadata + formal resume transition'
require_contains "docs/workflows/agent-operator-contract.md" 'schema / format version'
require_contains "docs/workflows/agent-operator-contract.md" 'capability packet'
require_contains "docs/workflows/agent-operator-contract.md" 'full parent session transcript'
require_contains "docs/workflows/agent-operator-contract.md" '`max turns / iterations`'
require_contains "docs/workflows/agent-operator-contract.md" 'deterministic / code-graded gate'
require_contains "docs/workflows/agent-operator-contract.md" 'content hash'
require_contains "docs/workflows/agent-operator-contract.md" '不做静默 hot-swap'
require_contains "docs/workflows/agent-operator-contract.md" 'tool choice 是否合理'
require_contains "docs/workflows/agent-operator-contract.md" 'schema fit 是否正确'
require_contains "docs/workflows/agent-operator-contract.md" 'versioned control surface'
require_contains "docs/workflows/agent-operator-contract.md" 'steerability surface'
require_contains "docs/workflows/agent-operator-contract.md" 'at-least-once delivery'
require_contains "docs/workflows/agent-operator-contract.md" 'human approval'
require_contains "docs/workflows/agent-operator-contract.md" '`MCP roots`、OAuth audience / scope、tool allowlist、permission mode'
require_contains "docs/workflows/agent-operator-contract.md" 'content hash'
require_contains "docs/workflows/agent-operator-contract.md" 'remote / marketplace / user-supplied skill'
require_contains "docs/workflows/agent-operator-contract.md" 'provider / SDK continuation handle'
require_contains "docs/workflows/agent-operator-contract.md" 'instruction continuity'
require_contains "docs/workflows/agent-operator-contract.md" 'serialized app / agent / session context'
require_contains "docs/workflows/agent-operator-contract.md" 'provider-side stored state'
require_contains "docs/workflows/agent-operator-contract.md" 'subagent memory directory /'
for needle in 'wakeup handle + deadline' 'stable operation id' 'version marker' '`roots/list`' 'host-managed auth' 'out-of-band elicitation' '`tool_use` / `tool_result` `_meta`'; do require_contains "docs/workflows/agent-operator-contract.md" "$needle"; done
require_contains "docs/workflows/agent-operator-contract.md" 'capture policy、'
require_contains "docs/workflows/agent-operator-contract.md" 'blocking preflight、'
require_contains "docs/workflows/agent-operator-contract.md" 'guardrail coverage'
require_contains "docs/workflows/agent-operator-contract.md" 'audience-bound token'
require_contains "docs/workflows/agent-operator-contract.md" 'passthrough 给上游 API'
require_contains "docs/workflows/agent-operator-contract.md" '20-50 个来自真实失败'
require_contains "docs/workflows/agent-operator-contract.md" 'regression sample'
require_contains "docs/workflows/agent-operator-contract.md" 'tool name / description /'
require_contains "docs/workflows/agent-operator-contract.md" 'argument schema / output contract'
require_contains "docs/workflows/agent-operator-contract.md" 'page token'
for needle in '双重上报或默默复用冲突语义' 'exact trajectory /' 'path 映射' 'partial credit'; do require_contains "docs/workflows/agent-operator-contract.md" "$needle"; done
require_contains "docs/workflows/provider-deltas/codex.md" 'full-context fork'
require_contains "docs/workflows/provider-deltas/codex.md" 'budget / stop boundary'
require_contains "docs/organization/decision-rights.md" '`Role Change Proposal`'
require_contains "docs/organization/decision-rights.md" '本文件定义的是默认 routing / approval control surface，不是组织图。'
require_contains "docs/workflows/agile-runnable-demo-policy.md" 'post-acceptance compounding review'
require_contains "docs/workflows/founder-meeting-taxonomy.md" 'Founder-facing 正式会议当前只保留 4 类'
require_contains "docs/workflows/founder-meeting-taxonomy.md" '这些 `meeting` 名字是 routing label 和 output contract，不是周期性治理仪式，也不是组织结构投影。'
require_contains "docs/workflows/founder-intake-evolution-loop.md" '`general-manager`'
require_contains "docs/workflows/surface-audit.md" '# Surface Audit'
require_contains "docs/workflows/surface-audit.md" 'run_surface_diagnostic.sh'
require_contains "docs/workflows/surface-audit.md" 'audit_entropy_budget.sh'
require_contains "docs/workflows/surface-audit.md" 'compaction-only mode'
require_contains "docs/workflows/document-routing-and-lifecycle.md" '慢速 human review / approval / feedback'
require_contains "docs/workflows/document-routing-and-lifecycle.md" 'cheap baseline check'
require_contains "docs/workflows/document-routing-and-lifecycle.md" '兼容别名保留'
require_contains "docs/workflows/document-routing-and-lifecycle.md" 'audit_entropy_budget.sh'
require_contains "docs/workflows/work-item-recovery-protocol.md" '等待 human approval / review / feedback 跨 session 时'
require_contains "docs/workflows/work-item-recovery-protocol.md" 'cheap baseline check'
require_contains "docs/workflows/work-item-recovery-protocol.md" 'checkpoint-relative re-entry'
for needle in 'wakeup handle + deadline' 'stable operation id'; do require_contains "docs/workflows/work-item-recovery-protocol.md" "$needle"; done
require_contains "docs/workflows/work-item-interrupt-protocol.md" 'instruction-pointer continuation'
require_contains "roles/runtime-role-manager.md" 'policy_allowed_entrypoints: scripts/runtime_role_manager.sh'
require_contains "references/specs/README.md" '`references/specs/` 只保留仍贴近当前 contract 或实现收敛方向的 spec。'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'schema / format version'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" '慢速 human approval / review / feedback'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'budget / stop boundary'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'checkpoint-relative、node-level re-entry'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'durability / flush boundary'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" '不做静默 hot-swap'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'artifact path、locator'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'at-least-once delivery'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'trust analysis'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'lock dir 元数据默认应带 `owner`'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" '`Claimed at`、`Claim expires at` 与 `Lease version`'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'Acceptance Ledger'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'cheap baseline check'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'content hash'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'provider / SDK continuation handle'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'serialized app / agent / session context'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'provider-side stored state'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'subagent memory directory /'
for needle in 'wakeup handle' 'stable operation id' 'version marker' '`roots/list`' 'host-managed auth' 'out-of-band elicitation' '`tool_use` / `tool_result` `_meta`'; do require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" "$needle"; done
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'capture policy、'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'blocking preflight、'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'audience-bound token'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'verbatim continuation payload'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'update-only'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'page token'
for needle in '双重上报或语义冲突' 'typed schema' 'Verification / Eval Boundary' 'exact trajectory /' 'path 映射' 'partial credit' 'receiver-generated handle' 'shadow polling state' 'cheap、idempotent、re-entrant'; do require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" "$needle"; done
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'budget / stop boundary'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'full parent transcript'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'steerability surface'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'remote / marketplace / user-supplied skill'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'version pin'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'bundle-local memory'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'persisted data 与 capability grant'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" 'artifact path / locator'
require_contains "references/specs/2026-03-27-harness-capability-bundle-contract-v1.md" '口耳相传'
require_contains "SKILL.md" 'task-record-runtime-tree-v2.toml'
require_contains "roles/general-manager.md" '你是默认任务编排负责人。'
require_contains "docs/workflows/volatile-research-default.md" '上游输入 -> task loop 的入口'
require_contains "docs/workflows/internal-research-routing.md" 'repo/task 内部路由'
require_contains "docs/workflows/agile-runnable-demo-policy.md" '最终决策人（例如 Founder）'
require_contains "docs/research/frontier-practices-2026.md" '当前 source repo 的 first hop 是：'
require_contains "docs/research/frontier-practices-2026.md" 'provider-owned adapter surface'
require_contains "docs/research/frontier-practices-2026.md" '更强的 provider-neutral institutional context'
require_contains "docs/templates/frontier-scan.md" 'What fits this harness now:'
require_contains "skills/decision-pack/templates/decision-pack.md" 'Ask from user / approver:'
require_contains "skills/decision-pack/SKILL.md" 'Ask from user / approver'
require_contains "docs/workflows/decision-workflow.md" 'skills/founder-brief/templates/founder-brief.md'
require_contains "docs/workflows/decision-workflow.md" 'skills/research/templates/research-memo.md'
require_contains "docs/workflows/decision-workflow.md" 'skills/decision-pack/templates/decision-pack.md'
require_contains "docs/workflows/volatile-research-default.md" 'skills/research/templates/research-dispatch.md'
require_contains "docs/workflows/internal-research-routing.md" 'skills/research/templates/research-dispatch.md'
require_contains "docs/workflows/process-compounding-cadence.md" 'skills/process-audit/templates/process-audit.md'
require_contains "docs/workflows/process-compounding-cadence.md" 'skills/os-audit/templates/surface-audit.md'
require_contains "references/specs/2026-03-27-harness-task-record-runtime-contract-v2.md" 'audit_entropy_budget.sh'
require_contains "README.md" 'audit_entropy_budget.sh'
require_contains "README.md" 'active-surface entropy budget'
require_contains "README.md" 'compaction-only mode'
require_contains "references/contracts/active-surface-entropy-budget-v1.toml" 'budget_mode = "freeze-by-default"'
require_contains "references/contracts/active-surface-entropy-budget-v1.toml" 'active_reference_scope = "references/ excluding references/archive/"'
require_redirect_stub "docs/templates/acceptance-review-brief.md" 'skills/acceptance-review/templates/acceptance-review-brief.md'
require_redirect_stub "docs/templates/brainstorming-notes.md" 'skills/brainstorming-session/templates/brainstorming-notes.md'
require_redirect_stub "docs/templates/decision-pack.md" 'skills/decision-pack/templates/decision-pack.md'
require_redirect_stub "docs/templates/founder-brief.md" 'skills/founder-brief/templates/founder-brief.md'
require_redirect_stub "docs/templates/governance-surface-audit.md" 'skills/os-audit/templates/surface-audit.md'
require_redirect_stub "docs/templates/process-audit.md" 'skills/process-audit/templates/process-audit.md'
require_redirect_stub "docs/templates/requirements-meeting-brief.md" 'skills/requirements-meeting/templates/requirements-meeting-brief.md'
require_redirect_stub "docs/templates/research-dispatch.md" 'skills/research/templates/research-dispatch.md'
require_redirect_stub "docs/templates/research-memo.md" 'skills/research/templates/research-memo.md'
require_redirect_stub "docs/templates/source-note.md" 'skills/research/templates/source-note.md'
require_redirect_stub "docs/templates/vision-meeting-brief.md" 'skills/vision-meeting/templates/vision-meeting-brief.md'
require_contains "scripts/materialize_runtime_fixture.sh" 'schema / format version'
require_contains "scripts/materialize_runtime_fixture.sh" 'pause the task and resume later'
require_contains "scripts/materialize_runtime_fixture.sh" 'budget / stop boundary'
require_contains "scripts/materialize_runtime_fixture.sh" 'renewable claim-expiry metadata'
require_contains "scripts/materialize_runtime_fixture.sh" 'cheap baseline check'
require_contains "scripts/materialize_runtime_fixture.sh" 'at-least-once delivery'
require_contains "scripts/materialize_runtime_fixture.sh" 'instruction-pointer continuation'
require_contains "scripts/materialize_runtime_fixture.sh" 'external-evidence provenance'
require_contains "scripts/materialize_runtime_fixture.sh" 'provider-side stored state'
require_contains "scripts/materialize_runtime_fixture.sh" 'Auto-injected project memory or subagent memory'
require_contains "scripts/materialize_runtime_fixture.sh" 'Built-in tracing defaults require explicit capture / redaction / disable policy'
require_contains "scripts/lib_consumer_runtime_routes.sh" 'Shared writeback runtime'
require_contains "scripts/new_work_item.sh" 'owner="${3:-General Manager}"'
require_contains "scripts/new_work_item.sh" 'sponsor="${5:-general-manager}"'
require_contains "docs/workflows/work-item-recovery-protocol.md" 'budget / stop boundary'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'worker_payload_should_be_minimal_capability_packet = true'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'worker_payload_must_not_include = ['
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'long_running_execution_requires_explicit_budget_boundary = true'
require_contains "skills/memory-checkpoint/templates/checkpoint.md" '- Flush boundary:'
require_contains "skills/memory-checkpoint/templates/checkpoint.md" '- Crash-safe through:'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'provider_or_sdk_handles_are_transport_state_only = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'transport_continuity_does_not_imply_instruction_continuity = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'serialized_context_requires_explicit_version = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'serialized_context_must_not_store_raw_secrets = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'provider_background_or_pollable_modes_may_require_provider_stored_state = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'auto_injected_memory_is_instruction_surface = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'builtin_tracing_defaults_require_explicit_capture_policy = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'side_effect_prevention_requires_blocking_preflight_or_wrapper = true'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'mcp_oauth_tokens_must_be_audience_bound = true'
for needle in 'cross_run_wait_requires_deadline_or_expiry = true' 'approval_interrupt_and_async_resume_require_stable_operation_id = true' 'approval_interrupt_and_async_resume_require_version_marker = true' 'resume_pairs_by_operation_id_not_display_order = true' 'server_to_client_discovery_requests_are_request_scoped_only = true' 'sensitive_auth_should_prefer_host_managed_or_out_of_band = true' 'trace_correlation_should_flow_via_protocol_metadata = true'; do require_contains "references/contracts/task-record-runtime-tree-v2.toml" "$needle"; done
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'tool outputs should prefer handles, locators, or page tokens over inline blobs when large or paged'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" 'update-only acceptance ledger under attachments/ with status/checklist plus evidence references rather than full-spec rewrites'
for needle in 'builtin_tracing_must_avoid_double_reporting_or_semantic_conflict = true' 'deterministic_gate_precedes_trace_or_llm_eval = true' 'exact_trajectory_is_not_default_pass_condition = true' 'multi_component_eval_may_award_partial_credit = true' 'mcp_roots_are_operational_boundary_not_just_discovery_scope = true' 'mcp_root_exposure_and_path_mapping_require_explicit_validation = true' 'receiver_generated_background_handles_should_be_reused = true' 'runtime_must_not_create_shadow_polling_state_when_protocol_exposes_handle = true' 'resume_or_compact_may_retrigger_dynamic_hooks = true' 'hook_logic_should_be_cheap_idempotent_and_reentrant = true' 'untrusted_tool_annotations_are_planning_or_routing_hints_only = true'; do require_contains "references/contracts/task-record-runtime-tree-v2.toml" "$needle"; done
forbid_contains "roles/general-manager.md" '你是本项目的职业经理人。'
forbid_contains "scripts/new_work_item.sh" 'Chief of Staff'
forbid_contains "docs/workflows/volatile-research-default.md" 'Founder -> company 的入口'
forbid_contains "docs/workflows/internal-research-routing.md" '`Chief of Staff`'
forbid_contains "docs/workflows/founder-meeting-taxonomy.md" '`Chief of Staff`'
forbid_contains "docs/workflows/founder-intake-evolution-loop.md" '`General Manager / Chief of Staff`'
forbid_contains "docs/organization/decision-rights.md" '`General Manager / Chief of Staff`'
forbid_contains "docs/workflows/agile-runnable-demo-policy.md" '本公司遵循的 agile 原则'
forbid_contains "docs/templates/research-memo.md" 'promoted governance dispatch'
forbid_contains "docs/templates/decision-pack.md" 'promoted governance dispatch'
forbid_contains "skills/research/templates/research-memo.md" 'promoted governance dispatch'
forbid_contains "skills/decision-pack/templates/decision-pack.md" 'promoted governance dispatch'
forbid_contains "skills/decision-pack/templates/decision-pack.md" 'Ask from Founder:'
forbid_contains "docs/research/frontier-practices-2026.md" '根级宪法文件：`CLAUDE.md` 与 `AGENTS.md`'

if command -v markdownlint >/dev/null 2>&1; then
  markdownlint README.md >/dev/null 2>&1 || fail "README.md failed markdownlint"
else
  fail "missing command: markdownlint (required entropy-reduction control)"
fi

if ! ./scripts/audit_entropy_budget.sh --quiet >/dev/null 2>&1; then
  fail "entropy budget audit failed"
fi

require_legacy_redirect_stub "docs/workflows/governance-surface-audit.md" 'docs/workflows/surface-audit.md'
require_legacy_redirect_stub "skills/os-audit/templates/governance-surface-audit.md" 'surface-audit.md'

if rg -n '/Users/[^/]+/.+/(\\.agents/skills/harness|\\.harness)/|/Users/[^/]+/.+/AGENTS\\.md|/Users/[^/]+/.+/CLAUDE\\.md|/Users/[^/]+/.+/GEMINI\\.md|/Users/[^/]+/.+/(\\.codex|\\.gemini)/' \
  --glob '!references/archive/**' \
  --glob '!docs/research/frontier-practices-2026.md' \
  . >/dev/null 2>&1; then
  fail "found consumer-specific absolute paths outside archive/"
fi

if rg -n -i '\boverlay\b|carrier' \
  docs \
  references \
  roles \
  SKILL.md \
  --glob '!references/archive/**' \
  --glob '!docs/research/**' >/dev/null 2>&1; then
  fail "found retired projection/overlay/carrier language in active source docs"
fi

if [ "$ok" -eq 1 ]; then
  say "source repo audit: ok"
  exit 0
fi

exit 1
