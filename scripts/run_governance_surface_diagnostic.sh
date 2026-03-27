#!/bin/sh
set -eu

usage() {
  echo "usage: $0 [--mode auto|source|consumer] [--write <output.md>]" >&2
  exit 1
}

output_path=""
mode="auto"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      [ "$#" -ge 2 ] || usage
      mode="$2"
      shift 2
      ;;
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
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))
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

detect_mode() {
  if [ "$mode" != "auto" ]; then
    printf '%s\n' "$mode"
    return 0
  fi

  if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".agents/skills/harness" ]; then
    printf '%s\n' "source"
    return 0
  fi

  if [ -d ".agents/skills/harness" ] || [ -d ".harness" ]; then
    printf '%s\n' "consumer"
    return 0
  fi

  echo "unable to auto-detect governance diagnostic mode; use --mode source or --mode consumer" >&2
  exit 1
}

mode=$(detect_mode)

case "$mode" in
  source|consumer) ;;
  *) echo "invalid mode: $mode" >&2; exit 1 ;;
esac

if [ "$mode" = "source" ]; then
  run_check "validate_source_repo" "$script_dir/validate_source_repo.sh"
  run_check "audit_role_schema" "$script_dir/audit_role_schema.sh"

  source_skills=$(find skills -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  source_roles=$(find roles -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
  source_scripts=$(find scripts -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  source_docs=$(find docs -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  source_references=$(find references -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

  cat >"$report_file" <<EOF
# Governance Surface Diagnostic

- Date: $(date +%F)
- Mode: source
- Scope: framework source contracts, canonical role/skill surface, source-repo hygiene
- Canonical capability surface: \`agents + skills\`

## Baseline Checks

$(cat "$check_file")

## Capability Inventory

- Canonical skills: $source_skills
- Canonical roles: $source_roles
- Source scripts: $source_scripts
- Source docs: $source_docs
- Source references: $source_references

## Usage Notes

1. source 模式只评估 framework source repo，不读取 consumer runtime 或 installed carrier。
2. 若要诊断真实安装态，请在 dogfood / consumer repo 运行同一脚本的 consumer 模式。
3. 若 OS 结构发生变化，应先更新本脚本，再更新 cadence 或 audit 模板。
EOF
else
  run_check "validate_workspace" "$script_dir/validate_workspace.sh"
  run_check "audit_document_system" "$script_dir/audit_document_system.sh"
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

  canonical_skills=$(find .agents/skills/harness/skills -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
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
- Mode: consumer
- Scope: routing docs, workspace baseline, state system, brief layer, adapter surface
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

1. consumer 模式评估 installed skill carrier、runtime workspace 与 provider adapters。
2. 若要把结果沉淀成周期性治理产物，可运行：
   \`./.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh --mode consumer --write .harness/workspace/status/process-audits/\$(date +%F)-governance-surface-diagnostic.md\`
3. 若要审计 framework source repo，请在 source repo 运行：
   \`./scripts/run_governance_surface_diagnostic.sh --mode source\`
EOF
fi

if [ -n "$output_path" ]; then
  mkdir -p "$(dirname "$output_path")"
  cp "$report_file" "$output_path"
  echo "wrote governance surface diagnostic: $output_path"
else
  cat "$report_file"
fi
