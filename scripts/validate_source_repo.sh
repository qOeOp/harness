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
  grep -Fq "$pattern" "$file" || fail "missing pattern '$pattern' in $file"
}

forbid_contains() {
  file="$1"
  pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    fail "found retired pattern '$pattern' in $file"
  fi
}

forbidden_path() {
  [ ! -e "$1" ] || fail "source repo must not contain consumer/runtime surface: $1"
}

require_file "SKILL.md"
require_dir "skills"
require_dir "roles"
require_dir "scripts"
require_dir "docs"
require_dir "references"

for skill_dir in skills/*; do
  [ -d "$skill_dir" ] || continue
  require_file "$skill_dir/SKILL.md"
  require_file "$skill_dir/manifest.toml"
  require_file "$skill_dir/refs/README.md"
done

require_file "docs/project-structure.md"
require_file "docs/memory/memory-architecture.md"
require_file "references/layering.md"
require_file "references/runtime-workspace.md"
require_dir "references/contracts"
require_file "references/contracts/task-record-runtime-tree-v2.toml"
require_file "references/top-level-surface.md"
require_file "references/specs/README.md"
require_file "docs/organization/decision-rights.md"
require_file "roles/README.md"
require_file "roles/runtime-role-manager.md"
require_dir "skills/research"
require_file "skills/research/SKILL.md"
require_file "skills/research/manifest.toml"
require_file "skills/research/refs/README.md"
require_file "skills/research/templates/research-dispatch.md"
require_file "skills/research/templates/research-brief.md"
require_file "skills/research/templates/research-memo.md"
require_file "skills/research/templates/source-note.md"
require_file "skills/research/templates/evidence-ledger.md"
require_file "scripts/research/browser_extract.py"
require_file "scripts/research/crawl4ai_extract.py"
require_file "scripts/research/lib_extract.py"
require_file "scripts/research/lib_local_browser.py"
require_file "scripts/research/lib_runtime_paths.py"
require_file "scripts/research/lib_search.py"
require_file "scripts/research/local_browser_profiles.py"
require_file "scripts/research/run_crawl4ai_isolated.sh"
require_file "scripts/research/search_auto.py"
require_file "docs/workflows/agent-operator-contract.md"
require_file "docs/workflows/consumer-runtime-routing.md"
require_file "docs/workflows/task-artifact-routing.md"
require_file "docs/workflows/post-acceptance-compounding-loop.md"
require_file "docs/workflows/provider-deltas/gemini.md"
require_file "docs/workflows/tool-adapter-capability-map.md"
require_file "roles/README.md"
require_file "docs/templates/role-change-proposal.md"

require_exec "scripts/materialize_runtime_fixture.sh"
require_exec "scripts/run_state_validation_slice.sh"
require_exec "scripts/audit_role_schema.sh"
require_exec "scripts/new_role.sh"
require_exec "scripts/edit_role.sh"
require_exec "scripts/enforce_role_policy.sh"
require_exec "scripts/resolve_consumer_runtime_root.sh"
require_exec "scripts/new_role_change_proposal.sh"
require_exec "scripts/runtime_role_manager.sh"
require_exec "scripts/research_ctl.sh"
require_exec "scripts/research/run_crawl4ai_isolated.sh"
require_exec "skills/research/scripts/new_dispatch.sh"
require_exec "skills/research/scripts/new_brief.sh"
require_exec "skills/research/scripts/new_memo.sh"
require_exec "skills/research/scripts/new_source_note.sh"
require_exec "skills/research/scripts/new_ledger.sh"
require_exec "skills/decision-pack/scripts/new_decision.sh"
require_exec "skills/memory-checkpoint/scripts/new_checkpoint.sh"

forbidden_path ".harness"
forbidden_path ".agents/skills/harness"
forbidden_path "AGENTS.md"
forbidden_path "CLAUDE.md"
forbidden_path "GEMINI.md"
forbidden_path "README_CLAUDE.md"
forbidden_path "README_CODEX.md"
forbidden_path "README_GEMINI.md"
forbidden_path ".claude"
forbidden_path ".codex"
forbidden_path ".gemini"
forbidden_path "roles/learning-evolution-lead.md"
forbidden_path "roles/market-intelligence-lead.md"
forbidden_path "roles/position-operations-lead.md"
forbidden_path "roles/risk-office-lead.md"
forbidden_path "roles/strategy-research-lead.md"
forbidden_path "skills/research-memo"
forbidden_path "skills/research-dispatch"
forbidden_path "skills/researcher"
forbidden_path "skills/daily-digest"
forbidden_path "skills/governance-meeting"
forbidden_path "skills/retro"
forbidden_path "scripts/researcher"
forbidden_path "scripts/researcher_ctl.sh"
forbidden_path "scripts/new_researcher_brief.sh"
forbidden_path "scripts/new_company_digest.sh"
forbidden_path "scripts/new_daily_report.sh"
forbidden_path "scripts/new_retro.sh"
forbidden_path "docs/workflows/founder-governance-meeting-loop.md"
forbidden_path "docs/workflows/company-bootstrap-loop.md"
forbidden_path "docs/organization/org-chart.md"
forbidden_path "docs/organization/workstream-map.md"
forbidden_path "docs/organization/governance-capability-map.md"
forbidden_path "docs/organization/company-os-runtime-data-map.md"
forbidden_path "docs/organization/compounding-engineering-lead.md"
forbidden_path "docs/templates/company-daily-digest.md"
forbidden_path "docs/templates/governance-meeting-brief.md"
forbidden_path "docs/templates/daily-workstream-report.md"
forbidden_path "docs/templates/workstream-bootstrap-brief.md"
forbidden_path "docs/templates/workstream-retro.md"
forbidden_path "references/specs/2026-03-25-harness-invoke-first-vnext-spec-v1.md"
forbidden_path "references/specs/2026-03-25-harness-vnext-round1-reduction-inventory-v1.toml"
forbidden_path "references/specs/2026-03-26-harness-surface-buckets-v1.md"
forbidden_path "references/specs/2026-03-27-codex-worktree-convergence-matrix-v1.md"

require_contains "docs/memory/memory-architecture.md" '默认 runtime memory 是 `task-scoped`'
require_contains "docs/memory/memory-architecture.md" '.harness/tasks/<task-id>/task.md'
require_contains "docs/memory/memory-architecture.md" 'cross-task mode'
require_contains "docs/memory/memory-architecture.md" 'task.md` 既负责任务真相，也负责恢复协议。'
require_contains "README.md" 'control surfaces'
require_contains "docs/workflows/agent-operator-contract.md" '在 framework source repo 中，先看 `SKILL.md`、`references/layering.md` 与 `references/runtime-workspace.md`'
require_contains "docs/workflows/agent-operator-contract.md" '在 materialized consumer runtime 中，先看 `.harness/entrypoint.md`'
require_contains "docs/workflows/task-artifact-routing.md" '`task-local first, shared writeback by explicit promotion`'
require_contains "docs/workflows/task-artifact-routing.md" '.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md'
require_contains "skills/research/SKILL.md" 'This bundle owns the `research` capability as one bounded entity.'
require_contains "skills/research/manifest.toml" 'bundle_slug = "research"'
require_contains "skills/research/manifest.toml" 'operation_modes = ['
require_contains "skills/decision-pack/manifest.toml" 'bundle_slug = "decision-pack"'
require_contains "skills/memory-checkpoint/manifest.toml" 'bundle_slug = "memory-checkpoint"'
require_contains "scripts/new_research.sh" 'skills/research/templates/research-memo.md'
require_contains "scripts/new_research_dispatch.sh" 'skills/research/templates/research-dispatch.md'
require_contains "scripts/new_research_brief.sh" 'skills/research/templates/research-brief.md'
require_contains "scripts/new_source_note.sh" 'skills/research/templates/source-note.md'
require_contains "scripts/new_decision.sh" 'skills/decision-pack/templates/decision-pack.md'
require_contains "scripts/new_checkpoint.sh" 'skills/memory-checkpoint/templates/checkpoint.md'
require_contains "roles/general-manager.md" '`research` bundle 的 `dispatch` mode'
require_contains "skills/meeting-router/SKILL.md" '`research` bundle `dispatch` requirements'
require_contains "skills/decision-pack/SKILL.md" '.harness/tasks/<task-id>/attachments/'
require_contains "docs/workflows/provider-deltas/gemini.md" 'harness 不生成、不修改这些文件'
require_contains "docs/workflows/tool-adapter-capability-map.md" 'harness 不生成、不修改、不校验'
require_contains "docs/workflows/tool-adapter-capability-map.md" '名字路由 / 地址簿同样属于 user-owned integration'
require_contains "skills/research/refs/runtime-contract.md" 'configured SearXNG instance'
require_contains "skills/research/refs/runtime-contract.md" 'optional heavy-duty headless crawler'
require_contains "skills/research/refs/runtime-contract.md" '.harness/runtime/research/'
require_contains "references/runtime-workspace.md" '.harness/runtime/'
require_contains "docs/project-structure.md" '.harness/runtime/'
require_contains "skills/research/manifest.toml" '.harness/runtime/research/'
require_contains "references/contracts/task-record-runtime-tree-v2.toml" '.harness/runtime'
require_contains "references/contracts/capability-bundle-manifest-v1.toml" 'runtime_local_support_roots_may_be_explicit = true'
require_contains "roles/README.md" '本仓库不再维护 provider-owned generated role mirrors'
require_contains "roles/README.md" '.harness/workspace/roles/'
require_contains "roles/README.md" '`runtime-role-manager`'
require_contains "roles/README.md" '`policy_allowed_entrypoints`'
require_contains "roles/README.md" '这些角色是 execution substrate 的路由节点，不是公司职位投影。'
require_contains "docs/workflows/consumer-runtime-routing.md" 'consumer runtime route table'
require_contains "docs/workflows/consumer-runtime-routing.md" '$HOME/.harness/consumer-runtime-routes.tsv'
require_contains "docs/workflows/consumer-runtime-routing.md" '`--consumer-runtime <name>`'
require_contains "docs/workflows/post-acceptance-compounding-loop.md" 'completion candidate -> acceptance -> compounding review -> role change proposal -> runtime-role-manager execution'
require_contains "docs/workflows/task-artifact-routing.md" 'role-change-proposal.md'
require_contains "docs/workflows/agent-operator-contract.md" 'scripts/runtime_role_manager.sh'
require_contains "docs/workflows/agent-operator-contract.md" '`policy_*`'
require_contains "docs/organization/decision-rights.md" '`Role Change Proposal`'
require_contains "docs/workflows/agile-runnable-demo-policy.md" 'post-acceptance compounding review'
require_contains "docs/workflows/founder-meeting-taxonomy.md" 'Founder-facing 正式会议当前只保留 4 类'
require_contains "docs/workflows/founder-intake-evolution-loop.md" '`general-manager`'
require_contains "docs/workflows/governance-surface-audit.md" '# Surface Audit'
require_contains "roles/runtime-role-manager.md" 'policy_allowed_entrypoints: scripts/runtime_role_manager.sh'
require_contains "references/specs/README.md" '`references/specs/` 只保留仍贴近当前 contract 或实现收敛方向的 spec。'
require_contains "SKILL.md" 'task-record-runtime-tree-v2.toml'
require_contains "roles/general-manager.md" '你是默认任务编排负责人。'
require_contains "docs/workflows/volatile-research-default.md" '上游输入 -> task loop 的入口'
require_contains "docs/workflows/internal-research-routing.md" 'repo/task 内部路由'
require_contains "docs/workflows/agile-runnable-demo-policy.md" '最终决策人（例如 Founder）'
require_contains "docs/templates/frontier-scan.md" 'What fits this harness now:'
require_contains "docs/templates/decision-pack.md" 'Ask from user / approver:'
forbid_contains "roles/general-manager.md" '你是本项目的职业经理人。'
forbid_contains "docs/workflows/volatile-research-default.md" 'Founder -> company 的入口'
forbid_contains "docs/workflows/internal-research-routing.md" '`Chief of Staff`'
forbid_contains "docs/workflows/founder-meeting-taxonomy.md" '`Chief of Staff`'
forbid_contains "docs/workflows/founder-intake-evolution-loop.md" '`General Manager / Chief of Staff`'
forbid_contains "docs/workflows/agile-runnable-demo-policy.md" '本公司遵循的 agile 原则'
forbid_contains "docs/templates/research-memo.md" 'promoted governance dispatch'
forbid_contains "docs/templates/decision-pack.md" 'promoted governance dispatch'

if command -v markdownlint >/dev/null 2>&1; then
  markdownlint README.md >/dev/null 2>&1 || fail "README.md failed markdownlint"
else
  fail "missing command: markdownlint (required subtractive-governance control)"
fi

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
