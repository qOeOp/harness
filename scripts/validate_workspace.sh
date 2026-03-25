#!/bin/sh
set -eu

quiet="${1:-}"
ok=1
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

check_file() {
  if [ ! -e "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing: $1"
  fi
}

check_exec() {
  if [ ! -x "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "not executable: $1"
  fi
}

check_contains() {
  file="$1"
  pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing pattern '$pattern' in $file"
  fi
}

check_dir() {
  if [ ! -d "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing directory: $1"
  fi
}

check_file "README.md"
check_file "CLAUDE.md"
check_file "AGENTS.md"
check_file "GEMINI.md"
check_file ".harness/entrypoint.md"
check_file ".harness/workspace/departments/README.md"
check_file ".agents/skills/harness/docs/organization/org-chart.md"
check_file ".agents/skills/harness/docs/organization/department-map.md"
check_file ".agents/skills/harness/docs/organization/company-os-runtime-data-map.md"
check_file ".agents/skills/harness/docs/charter/company-charter.md"
check_file ".agents/skills/harness/docs/workflows/decision-workflow.md"
check_file ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md"
check_file ".agents/skills/harness/docs/workflows/agent-operator-contract.md"
check_file ".agents/skills/harness/docs/workflows/provider-deltas/codex.md"
check_file ".agents/skills/harness/docs/workflows/provider-deltas/gemini.md"
check_file ".agents/skills/harness/docs/charter/document-types-and-writing-style.md"
check_file ".agents/skills/harness/docs/workflows/code_review.md"
check_file ".harness/workspace/decisions/log/README.md"
check_file ".harness/workspace/current/README.md"
check_file ".harness/workspace/research/dispatches/README.md"
check_file ".harness/workspace/status/digests/README.md"
check_file ".harness/workspace/status/process-audits/README.md"
check_file ".harness/workspace/status/snapshots/README.md"
check_file ".harness/workspace/research/sources/README.md"
check_file ".harness/workspace/intake/inbox/README.md"
check_file ".harness/workspace/state/README.md"
check_file ".harness/workspace/state/items/README.md"
check_file ".harness/workspace/state/boards/README.md"
check_file ".harness/workspace/state/board-refreshes/README.md"
check_file ".harness/workspace/state/progress/README.md"
check_file ".harness/workspace/state/transitions/README.md"
check_file ".claude/settings.json"
check_file ".codex/config.toml"
check_file ".gemini/settings.json"
check_exec ".githooks/pre-commit"
check_exec ".githooks/pre-push"
check_file ".github/workflows/governance-gates.yml"

check_dir ".agents/skills/harness/docs/charter"
check_dir ".agents/skills/harness/docs/organization"
check_dir ".agents/skills/harness/docs/workflows"
check_dir ".agents/skills/harness/docs/workflows/provider-deltas"
check_dir ".agents/skills/harness/docs/templates"
check_dir ".harness/workspace/current"
check_dir ".harness/workspace/archive"
check_dir ".harness/workspace/state"
check_dir ".harness/workspace/state/items"
check_dir ".harness/workspace/state/boards"
check_dir ".harness/workspace/state/board-refreshes"
check_dir ".harness/workspace/state/progress"
check_dir ".harness/workspace/state/transitions"
check_dir ".agents/skills"
check_dir ".claude/agents"
check_dir ".claude/skills"
check_dir ".codex/agents"
check_dir ".agents/skills/harness/scripts"

for dept in .harness/workspace/departments/*; do
  [ -d "$dept" ] || continue
  [ "$dept" = ".harness/workspace/departments/README.md" ] && continue
  case "$(basename "$dept")" in
    README.md) continue ;;
  esac
  check_file "$dept/README.md"
  check_file "$dept/AGENTS.md"
  check_file "$dept/CLAUDE.md"
  check_file "$dept/GEMINI.md"
  check_file "$dept/charter.md"
  check_file "$dept/interfaces.md"
  check_file "$dept/workspace/README.md"
  check_dir "$dept/workspace/intake"
  check_dir "$dept/workspace/memos"
  check_dir "$dept/workspace/outputs"
  check_dir "$dept/workspace/reports"
  check_dir "$dept/workspace/reports/daily"
  check_dir "$dept/workspace/reports/retros"
done

for current_file in .harness/workspace/current/*.md; do
  [ -f "$current_file" ] || continue
  case "$(basename "$current_file")" in
    README.md) ;;
    *) check_file "$current_file" ;;
  esac
done

for file in .claude/agents/*.md; do
  [ -f "$file" ] || continue
  base=$(basename "$file" .md)
  codex_base=$(printf "%s" "$base" | sed 's/-lead$//')
  check_file ".codex/agents/$codex_base.toml"
done

for file in .agents/skills/harness/scripts/*.sh; do
  [ -f "$file" ] || continue
  check_exec "$file"
done

check_exec ".agents/skills/harness/scripts/sync_claude_skill_projections.sh"
check_exec ".agents/skills/harness/scripts/sync_agent_projections.sh"
check_exec ".agents/skills/harness/scripts/audit_role_schema.sh"

for file in .claude/commands/*.md .claude/skills/*/SKILL.md .agents/skills/harness/SKILL.md .agents/skills/harness/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  check_file "$file"
done

for file in .agents/skills/harness/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  slug=$(basename "$(dirname "$file")")
  check_file ".claude/skills/$slug/SKILL.md"
  check_contains ".claude/skills/$slug/SKILL.md" ".agents/skills/harness/skills/$slug/SKILL.md"
  check_contains ".claude/skills/$slug/SKILL.md" "AUTO-GENERATED projection"
done

check_file ".agents/skills/harness/roles/README.md"

for role_file in .agents/skills/harness/roles/*.md; do
  [ -f "$role_file" ] || continue
  [ "$(basename "$role_file")" = "README.md" ] && continue

  check_contains "$role_file" "schema_version: 1"
  check_contains "$role_file" "slug: "
  check_contains "$role_file" "claude_file: "
  check_contains "$role_file" "codex_file: "
  check_contains "$role_file" "## Canonical Instructions"

  claude_projection=$(awk 'NR == 1 && $0 == "---" { in_frontmatter = 1; next } in_frontmatter && $0 == "---" { exit } in_frontmatter && index($0, "claude_file: ") == 1 { print substr($0, length("claude_file: ") + 1); exit }' "$role_file")
  codex_projection=$(awk 'NR == 1 && $0 == "---" { in_frontmatter = 1; next } in_frontmatter && $0 == "---" { exit } in_frontmatter && index($0, "codex_file: ") == 1 { print substr($0, length("codex_file: ") + 1); exit }' "$role_file")

  check_file ".claude/agents/$claude_projection"
  check_file ".codex/agents/$codex_projection"
  check_contains ".claude/agents/$claude_projection" "AUTO-GENERATED projection"
  check_contains ".claude/agents/$claude_projection" "$(basename "$role_file")"
  check_contains ".codex/agents/$codex_projection" "AUTO-GENERATED projection"
  check_contains ".codex/agents/$codex_projection" ".agents/skills/harness/roles/$(basename "$role_file" .md).md"
done

if grep -Fq "block-dangerous-bash.sh" ".claude/settings.json" || [ -f ".claude/hooks/block-dangerous-bash.sh" ]; then
  check_exec ".claude/hooks/block-dangerous-bash.sh"
fi

if grep -Fq "volatile-prompt-research.py" ".claude/settings.json" || [ -f ".claude/hooks/volatile-prompt-research.py" ]; then
  check_exec ".claude/hooks/volatile-prompt-research.py"
  check_contains ".claude/settings.json" "UserPromptSubmit"
  check_contains ".claude/settings.json" "volatile-prompt-research.py"
fi

if grep -Fq "subagent-volatile-research.py" ".claude/settings.json" || [ -f ".claude/hooks/subagent-volatile-research.py" ]; then
  check_exec ".claude/hooks/subagent-volatile-research.py"
  check_contains ".claude/settings.json" "SubagentStart"
  check_contains ".claude/settings.json" "subagent-volatile-research.py"
fi

for file in .claude/agents/*.md; do
  [ -f "$file" ] || continue
  if grep -Fq "WebSearch" "$file"; then
    check_contains "$file" "volatile-research-default.md"
  fi
done

for file in \
  .claude/agents/general-manager.md \
  .claude/agents/compounding-engineering-lead.md \
  .claude/agents/market-intelligence-lead.md \
  .claude/agents/strategy-research-lead.md \
  .claude/agents/position-operations-lead.md \
  .claude/agents/risk-office-lead.md \
  .claude/agents/learning-evolution-lead.md \
  .claude/agents/product-thesis-lead.md \
  .claude/agents/risk-quality-lead.md \
  .claude/agents/workflow-automation-lead.md
do
  [ -f "$file" ] || continue
  check_contains "$file" "WebSearch"
done

check_contains ".agents/skills/harness/skills/research-memo/SKILL.md" "volatile-research-default.md"
check_contains ".agents/skills/harness/skills/research-memo/SKILL.md" "internal-research-routing.md"
check_contains ".agents/skills/harness/skills/research-dispatch/SKILL.md" "internal-research-routing.md"
check_contains ".agents/skills/harness/skills/research-dispatch/SKILL.md" ".harness/workspace/research/dispatches/"
check_contains ".agents/skills/harness/skills/decision-pack/SKILL.md" "volatile-research-default.md"
check_contains ".agents/skills/harness/skills/decision-pack/SKILL.md" "internal-research-routing.md"
check_contains ".agents/skills/harness/skills/brainstorming-session/SKILL.md" "volatile-research-default.md"
check_contains ".agents/skills/harness/skills/requirements-meeting/SKILL.md" "volatile-research-default.md"
check_contains ".agents/skills/harness/skills/vision-meeting/SKILL.md" "volatile-research-default.md"
check_contains ".agents/skills/harness/skills/governance-meeting/SKILL.md" "volatile-research-default.md"

for file in \
  .claude/skills/research-memo/SKILL.md \
  .claude/skills/decision-pack/SKILL.md \
  .claude/skills/brainstorming-session/SKILL.md \
  .claude/skills/requirements-meeting/SKILL.md \
  .claude/skills/vision-meeting/SKILL.md \
  .claude/skills/governance-meeting/SKILL.md \
  .claude/skills/acceptance-review/SKILL.md
do
  [ -f "$file" ] || continue
  check_contains "$file" "WebSearch"
done

check_contains ".codex/agents/general-manager.toml" "volatile-research-default.md"
check_contains ".codex/agents/general-manager.toml" "research-dispatch"
check_contains ".codex/agents/knowledge-memory.toml" "web-verified"

check_contains "README.md" ".harness/entrypoint.md"
check_contains "README.md" ".harness/workspace/current/product-vision.md"
check_contains "README.md" "code_review.md"
check_contains "README.md" "agent-operator-contract.md"
check_contains "README.md" "GEMINI.md"
check_contains "CLAUDE.md" ".harness/entrypoint.md"
check_contains "AGENTS.md" ".harness/entrypoint.md"
check_contains "AGENTS.md" "GEMINI"
check_contains ".harness/entrypoint.md" ".agents/skills/harness/SKILL.md"
check_contains ".harness/entrypoint.md" ".harness/README.md"
check_contains ".harness/entrypoint.md" ".harness/compatibility.toml"
check_contains ".harness/entrypoint.md" ".harness/migration-inventory.toml"
check_contains ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" ".harness/entrypoint.md"
check_contains ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" "code_review.md"
check_contains ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" "agent-operator-contract.md"
check_contains ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" "provider-deltas/"
check_contains ".agents/skills/harness/docs/workflows/agent-operator-contract.md" "code_review.md"
check_contains ".agents/skills/harness/docs/workflows/agent-operator-contract.md" "provider-deltas/codex.md"
check_contains ".agents/skills/harness/docs/workflows/agent-operator-contract.md" "provider-deltas/gemini.md"

if [ -d ".gemini/agents" ] || grep -Fq '"enableAgents"' ".gemini/settings.json"; then
  check_dir ".gemini/agents"
  if grep -Fq '"enableAgents": true' ".gemini/settings.json"; then
    check_contains ".gemini/settings.json" "\"experimental\""
  fi
fi

check_contains ".agents/skills/harness/docs/templates/research-memo.md" "Research dispatch"
check_contains ".agents/skills/harness/docs/templates/decision-pack.md" "Research dispatch"

if git rev-parse --git-dir >/dev/null 2>&1; then
  hooks_path=$(git config --get core.hooksPath || true)
  if [ "$hooks_path" != ".githooks" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "git core.hooksPath is not set to .githooks"
  fi
fi

if ! "$script_dir/audit_document_system.sh" --quiet >/dev/null 2>&1; then
  ok=0
  [ "$quiet" = "--quiet" ] || echo "document routing audit failed"
fi

if ! "$script_dir/audit_tool_parity.sh" --quiet >/dev/null 2>&1; then
  ok=0
  [ "$quiet" = "--quiet" ] || echo "tool parity audit failed"
fi

if ! "$script_dir/audit_doc_style.sh" --quiet >/dev/null 2>&1; then
  ok=0
  [ "$quiet" = "--quiet" ] || echo "doc style audit failed"
fi

if ! "$script_dir/audit_state_system.sh" --quiet >/dev/null 2>&1; then
  ok=0
  [ "$quiet" = "--quiet" ] || echo "state system audit failed"
fi

if ! "$script_dir/audit_role_schema.sh" --quiet >/dev/null 2>&1; then
  ok=0
  [ "$quiet" = "--quiet" ] || echo "role schema audit failed"
fi

if [ "$ok" -eq 1 ]; then
  [ "$quiet" = "--quiet" ] || echo "workspace baseline: ok"
  exit 0
fi

exit 1
