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

forbidden_path() {
  [ ! -e "$1" ] || fail "source repo must not contain consumer/runtime surface: $1"
}

require_file "SKILL.md"
require_dir "skills"
require_dir "roles"
require_dir "scripts"
require_dir "docs"
require_dir "references"

require_file "docs/project-structure.md"
require_file "docs/memory/memory-architecture.md"
require_file "references/layering.md"
require_file "references/runtime-workspace.md"
require_dir "references/contracts"
require_file "references/contracts/task-record-runtime-tree-v2.toml"
require_file "references/top-level-surface.md"
require_file "references/specs/README.md"
require_file "roles/README.md"
require_file "roles/runtime-role-manager.md"
require_dir "skills/research"
require_file "skills/research/SKILL.md"
require_file "skills/research/manifest.toml"
require_file "skills/research/refs/README.md"
require_file "skills/research/templates/research-dispatch.md"
require_file "skills/research/templates/research-memo.md"
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
require_exec "skills/research/scripts/new_dispatch.sh"
require_exec "skills/research/scripts/new_memo.sh"

forbidden_path ".harness"
forbidden_path ".agents/skills/harness"
forbidden_path "AGENTS.md"
forbidden_path "CLAUDE.md"
forbidden_path "GEMINI.md"
forbidden_path ".claude"
forbidden_path ".codex"
forbidden_path ".gemini"
forbidden_path "roles/learning-evolution-lead.md"
forbidden_path "roles/market-intelligence-lead.md"
forbidden_path "roles/position-operations-lead.md"
forbidden_path "roles/risk-office-lead.md"
forbidden_path "roles/strategy-research-lead.md"
forbidden_path "references/specs/2026-03-25-harness-invoke-first-vnext-spec-v1.md"
forbidden_path "references/specs/2026-03-25-harness-vnext-round1-reduction-inventory-v1.toml"
forbidden_path "references/specs/2026-03-26-harness-surface-buckets-v1.md"
forbidden_path "references/specs/2026-03-27-codex-worktree-convergence-matrix-v1.md"

require_contains "docs/memory/memory-architecture.md" '默认 runtime memory 是 `task-scoped`'
require_contains "docs/memory/memory-architecture.md" '.harness/tasks/<task-id>/task.md'
require_contains "docs/memory/memory-architecture.md" 'advanced governance mode'
require_contains "docs/memory/memory-architecture.md" 'task.md` 既负责任务真相，也负责恢复协议。'
require_contains "docs/workflows/agent-operator-contract.md" '在 framework source repo 中，先看 `SKILL.md`、`references/layering.md` 与 `references/runtime-workspace.md`'
require_contains "docs/workflows/agent-operator-contract.md" '在 materialized consumer runtime 中，先看 `.harness/entrypoint.md`'
require_contains "docs/workflows/task-artifact-routing.md" '`task-local first, governance by explicit promotion`'
require_contains "docs/workflows/task-artifact-routing.md" '.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md'
require_contains "skills/research/SKILL.md" 'This bundle owns the `research` capability as one bounded entity.'
require_contains "skills/research/manifest.toml" 'bundle_slug = "research"'
require_contains "skills/research/manifest.toml" 'operation_modes = ['
require_contains "skills/research-dispatch/SKILL.md" '.harness/tasks/<task-id>/attachments/'
require_contains "skills/research-memo/SKILL.md" '.harness/tasks/<task-id>/attachments/'
require_contains "skills/decision-pack/SKILL.md" '.harness/tasks/<task-id>/attachments/'
require_contains "docs/workflows/provider-deltas/gemini.md" 'harness 不生成、不修改这些文件'
require_contains "docs/workflows/tool-adapter-capability-map.md" 'harness 不生成、不修改、不校验'
require_contains "docs/workflows/tool-adapter-capability-map.md" '名字路由 / 地址簿同样属于 user-owned integration'
require_contains "roles/README.md" '本仓库不再维护 provider-owned generated role mirrors'
require_contains "roles/README.md" '.harness/workspace/roles/'
require_contains "roles/README.md" '`runtime-role-manager`'
require_contains "roles/README.md" '`policy_allowed_entrypoints`'
require_contains "docs/workflows/consumer-runtime-routing.md" 'consumer runtime route table'
require_contains "docs/workflows/consumer-runtime-routing.md" '$HOME/.harness/consumer-runtime-routes.tsv'
require_contains "docs/workflows/consumer-runtime-routing.md" '`--consumer-runtime <name>`'
require_contains "docs/workflows/post-acceptance-compounding-loop.md" 'completion candidate -> acceptance -> compounding review -> role change proposal -> runtime-role-manager execution'
require_contains "docs/workflows/task-artifact-routing.md" 'role-change-proposal.md'
require_contains "docs/workflows/agent-operator-contract.md" 'scripts/runtime_role_manager.sh'
require_contains "docs/workflows/agent-operator-contract.md" '`policy_*`'
require_contains "docs/organization/decision-rights.md" '`Role Change Proposal`'
require_contains "docs/workflows/agile-runnable-demo-policy.md" 'post-acceptance compounding review'
require_contains "roles/runtime-role-manager.md" 'policy_allowed_entrypoints: scripts/runtime_role_manager.sh'
require_contains "references/specs/README.md" '`references/specs/` 只保留仍贴近当前 contract 或实现收敛方向的 spec。'
require_contains "SKILL.md" 'task-record-runtime-tree-v2.toml'

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
