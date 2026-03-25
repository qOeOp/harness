#!/bin/sh
set -eu

usage() {
  echo "usage: $0 [--write <output.md>]" >&2
  exit 1
}

output_path=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --write)
      [ "$#" -ge 2 ] || usage
      output_path="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../../.." && pwd)
cd "$repo_root"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

report_file="$tmpdir/report.md"
check_file="$tmpdir/checks.md"
brief_file="$tmpdir/brief.md"

run_check() {
  label="$1"
  shift

  output="$("$@" 2>&1 || true)"
  status="fail"

  if "$@" >/dev/null 2>&1; then
    status="pass"
  fi

  summary=$(printf '%s\n' "$output" | sed -n '1,3p' | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')
  [ -n "$summary" ] || summary="no output"

  printf -- "- \`%s\`: %s | %s\n" "$label" "$status" "$summary" >>"$check_file"
}

run_check "validate_workspace" "$script_dir/validate_workspace.sh"
run_check "audit_document_system" "$script_dir/audit_document_system.sh"
run_check "audit_tool_parity" "$script_dir/audit_tool_parity.sh"
run_check "audit_doc_style" "$script_dir/audit_doc_style.sh"
run_check "audit_role_schema" "$script_dir/audit_role_schema.sh"
run_check "audit_state_system" "$script_dir/audit_state_system.sh"
run_check "validate_freshness_gate" "$script_dir/validate_freshness_gate.sh"

brief_report=$("$script_dir/report_brief_registry.sh")
printf '%s\n' "$brief_report" | awk '
  /^- Date:/ {capture=1}
  /^## Recommended Reading Order$/ {capture=0}
  capture {print}
' >"$brief_file"

count_files() {
  find "$1" $2 | wc -l | tr -d ' '
}

canonical_skills=$(find .agents/skills/harness/skills -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
canonical_roles=$(find .agents/skills/harness/roles -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
claude_skills=$(find .claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
claude_agents=$(find .claude/agents -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
codex_agents=$(find .codex/agents -maxdepth 1 -type f -name '*.toml' 2>/dev/null | wc -l | tr -d ' ')
claude_commands=$(find .claude/commands -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
claude_hooks=$(find .claude/hooks -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
gemini_files=$(find .gemini -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ')
gemini_agents=$(find .gemini/agents -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

cat >"$report_file" <<EOF
# Governance Surface Diagnostic

- Date: $(date +%F)
- Mode: aggregate periodic diagnostic
- Scope: routing docs, workspace baseline, tool parity, state system, brief layer, adapter surface
- Canonical capability surface: \`agents + skills\`

## Baseline Checks

$(cat "$check_file")

## Capability Inventory

- Canonical skills: $canonical_skills
- Canonical roles: $canonical_roles
- Claude skills: $claude_skills
- Claude agents: $claude_agents
- Codex agents: $codex_agents
- Claude commands: $claude_commands
- Claude hooks: $claude_hooks
- Gemini adapter files: $gemini_files
- Gemini skill mode: direct \`.agents/skills/harness/skills\` alias
- Gemini agent mode: experimental \`.gemini/agents\` path, currently projected: $gemini_agents

## Brief Layer Snapshot

$(cat "$brief_file")

## Usage Notes

1. 这个脚本负责聚合当前 OS-level 诊断，不替代正式的 keep/delete/migrate 决策 artifact。
2. 若要把结果沉淀成周期性治理产物，可运行：
   \`./.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh --write .harness/workspace/status/process-audits/\$(date +%F)-governance-surface-diagnostic.md\`
3. 若 OS 结构发生变化，应先更新本脚本，再更新 cadence 或 audit 模板。
EOF

if [ -n "$output_path" ]; then
  mkdir -p "$(dirname "$output_path")"
  cp "$report_file" "$output_path"
  echo "wrote governance surface diagnostic: $output_path"
else
  cat "$report_file"
fi
