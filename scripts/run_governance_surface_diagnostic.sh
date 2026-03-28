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

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -L)
. "$script_dir/lib_harness_paths.sh"
init_harness_paths "$script_dir"
repo_root="$HARNESS_REPO_ROOT"
cd "$repo_root"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

report_file="$tmpdir/report.md"
check_file="$tmpdir/checks.md"
brief_file="$tmpdir/brief.md"

run_check() {
  label="$1"
  shift

  status="fail"
  if output=$("$@" 2>&1); then
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

  if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
    printf '%s\n' "source"
    return 0
  fi

  if [ -d ".harness" ]; then
    printf '%s\n' "consumer"
    return 0
  fi

  echo "unable to auto-detect surface diagnostic mode; use --mode source or --mode consumer" >&2
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
  source_workflows=$(find docs/workflows -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  source_skill_refs=$(find skills -path '*/refs/*' -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  source_archive_refs=$(find references/archive -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  legacy_state_item_refs=$(rg -l '\.harness/workspace/state/items/' README.md docs scripts roles skills references --glob '!references/archive/**' --glob '!scripts/run_governance_surface_diagnostic.sh' 2>/dev/null | wc -l | tr -d ' ')
  shared_workspace_refs=$(rg -l '\.harness/workspace/(current|briefs|state)/' README.md docs scripts roles skills references --glob '!references/archive/**' --glob '!scripts/run_governance_surface_diagnostic.sh' 2>/dev/null | wc -l | tr -d ' ')

  cat >"$report_file" <<EOF
# Surface Diagnostic

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

## Surface Entropy Snapshot

- Workflow docs: $source_workflows
- Skill-local ref docs: $source_skill_refs
- Archive markdown snapshots: $source_archive_refs
- Legacy state-item residue refs: $legacy_state_item_refs
- Active files still mentioning shared workspace surfaces: $shared_workspace_refs

## Usage Notes

1. source 模式只评估 framework source repo，不读取 consumer runtime 或用户自管的安装副本。
2. 若要诊断真实安装态，请在 dogfood / consumer repo 运行同一脚本的 consumer 模式。
3. \`Surface Entropy Snapshot\` 只做暴露，不直接判定好坏；重点看 active surface 是否在增长时同步发生 compress / merge / archive。
4. 若 OS 结构发生变化，应先更新本脚本，再更新 cadence 或 audit 模板。
EOF
else
  run_check "validate_workspace" "$script_dir/validate_workspace.sh"
  run_check "audit_document_system" "$script_dir/audit_document_system.sh"
  run_check "audit_doc_style" "$script_dir/audit_doc_style.sh"
  run_check "audit_role_schema" "$script_dir/audit_role_schema.sh"
  run_check "audit_state_system" "$script_dir/audit_state_system.sh"
  run_check "validate_freshness_gate" "$script_dir/validate_freshness_gate.sh"

  if [ -d ".harness/workspace/briefs" ] || [ -d ".harness/workspace/current" ] || [ -d ".harness/workspace/archive/briefs" ]; then
    if brief_report=$("$script_dir/report_brief_registry.sh" 2>/dev/null); then
      printf '%s\n' "$brief_report" | awk '
        /^- Date:/ {capture=1}
        /^## Recommended Reading Order$/ {capture=0}
        capture {print}
      ' >"$brief_file"
    else
      cat >"$brief_file" <<'EOF'
- Brief registry snapshot unavailable
- Reason: brief workspace exists but the registry report failed; inspect the harness `scripts/report_brief_registry.sh`
EOF
    fi
  else
    cat >"$brief_file" <<'EOF'
- Brief registry status: not materialized
- Reason: minimum-core runtime does not include the shared brief workspace by default
EOF
  fi

  all_tasks=$("$script_dir/query_work_items.sh" --all --record 2>/dev/null | awk 'END { print NR + 0 }')
  active_tasks=$("$script_dir/query_work_items.sh" --record 2>/dev/null | awk 'END { print NR + 0 }')
  archived_tasks=$(awk "BEGIN { print $all_tasks - $active_tasks }")
  recovery_backed_tasks=$(find .harness/tasks -mindepth 2 -maxdepth 2 -type f -name 'task.md' -exec grep -l '^## Recovery$' {} \; 2>/dev/null | wc -l | tr -d ' ')
  transition_events=$(find .harness/tasks -path '*/history/transitions/TX-*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  governance_dirs=$(find .harness/workspace -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

  cat >"$report_file" <<EOF
# Surface Diagnostic

- Date: $(date +%F)
- Mode: consumer
- Scope: harness-owned runtime docs, workspace baseline, state system, optional brief layer
- Canonical capability surface: \`.harness/\`

## Baseline Checks

$(cat "$check_file")

## Capability Inventory

- Active tasks: $active_tasks
- Archived-status tasks: $archived_tasks
- Task records with Recovery: $recovery_backed_tasks
- Transition events: $transition_events
- Shared workspace directories: $governance_dirs

## Brief Layer Snapshot

$(cat "$brief_file")

## Usage Notes

1. consumer 模式只评估 harness-owned runtime surface，不评估 provider adapters 或 skill install location。
2. 若要把结果沉淀成周期性 surface audit，可运行：
   \`./scripts/run_governance_surface_diagnostic.sh --mode consumer --write .harness/workspace/status/process-audits/\$(date +%F)-surface-diagnostic.md\`
3. 若要审计 framework source repo，请在 source repo 运行：
   \`./scripts/run_governance_surface_diagnostic.sh --mode source\`
EOF
fi

if [ -n "$output_path" ]; then
  mkdir -p "$(dirname "$output_path")"
  cp "$report_file" "$output_path"
  echo "wrote surface diagnostic: $output_path"
else
  cat "$report_file"
fi
