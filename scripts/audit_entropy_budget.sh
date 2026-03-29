#!/bin/sh
set -eu

quiet=""
contract="references/contracts/active-surface-entropy-budget-v1.toml"

usage() {
  cat <<'EOF' >&2
usage: ./scripts/audit_entropy_budget.sh [--quiet] [--contract <path>]
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quiet)
      quiet="--quiet"
      shift
      ;;
    --contract)
      [ "$#" -ge 2 ] || usage
      contract="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ ! -f "SKILL.md" ] || [ ! -d "skills" ] || [ ! -d "roles" ] || [ -d ".harness" ]; then
  echo "audit_entropy_budget.sh only validates the framework source repo active surface." >&2
  exit 1
fi

[ -f "$contract" ] || {
  echo "missing entropy budget contract: $contract" >&2
  exit 1
}

contract_value() {
  key="$1"
  awk -F'=' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value = $2
      sub(/^[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$contract"
}

require_contract_value() {
  key="$1"
  value=$(contract_value "$key")
  if [ -z "$value" ]; then
    echo "missing contract value '$key' in $contract" >&2
    exit 1
  fi
  printf '%s\n' "$value"
}

count_lines_for_files() {
  if [ "$#" -eq 0 ]; then
    printf '0\n'
    return 0
  fi

  awk '
    FNR == 1 { files += 1 }
    { lines += 1 }
    END { print lines + 0 }
  ' "$@"
}

append_detail() {
  line="$1"
  detail_lines="${detail_lines}${line}
"
}

check_max() {
  label="$1"; actual="$2"; max="$3"
  if [ "$actual" -lt "$max" ]; then append_detail "- ${label}: ${actual}/${max}"; return 0; fi
  if [ "$actual" -eq "$max" ]; then append_detail "- ${label}: ${actual}/${max} (at ceiling)"; return 0; fi
  ok=0
  append_detail "- budget breach: ${label} ${actual} > ${max}"
}

say() {
  [ "$quiet" = "--quiet" ] || printf '%s\n' "$1"
}

schema_version=$(require_contract_value "schema_version")
contract_kind=$(require_contract_value "contract_kind")
budget_mode=$(require_contract_value "budget_mode")
budget_change_requires_explicit_decision=$(require_contract_value "budget_change_requires_explicit_decision")

[ "$schema_version" = "1" ] || {
  echo "unsupported schema_version '$schema_version' in $contract" >&2
  exit 1
}

[ "$contract_kind" = "active-surface-entropy-budget" ] || {
  echo "unexpected contract_kind '$contract_kind' in $contract" >&2
  exit 1
}

max_total_active_files=$(require_contract_value "max_total_active_files")
max_total_active_lines=$(require_contract_value "max_total_active_lines")
max_readme_lines=$(require_contract_value "max_readme_lines")
max_docs_files=$(require_contract_value "max_docs_files")
max_docs_lines=$(require_contract_value "max_docs_lines")
max_skills_files=$(require_contract_value "max_skills_files")
max_skills_lines=$(require_contract_value "max_skills_lines")
max_roles_files=$(require_contract_value "max_roles_files")
max_roles_lines=$(require_contract_value "max_roles_lines")
max_scripts_files=$(require_contract_value "max_scripts_files")
max_scripts_lines=$(require_contract_value "max_scripts_lines")
max_active_reference_files=$(require_contract_value "max_active_reference_files")
max_active_reference_lines=$(require_contract_value "max_active_reference_lines")

readme_lines=$(wc -l < README.md | tr -d ' ')

docs_files=$(find docs -type f | wc -l | tr -d ' ')
docs_lines=$(find docs -type f -exec cat {} + | wc -l | tr -d ' ')

skills_files=$(find skills -type f | wc -l | tr -d ' ')
skills_lines=$(find skills -type f -exec cat {} + | wc -l | tr -d ' ')

roles_files=$(find roles -type f | wc -l | tr -d ' ')
roles_lines=$(find roles -type f -exec cat {} + | wc -l | tr -d ' ')

scripts_files=$(find scripts -type f | wc -l | tr -d ' ')
scripts_lines=$(find scripts -type f -exec cat {} + | wc -l | tr -d ' ')

reference_file_list=$(find references -path 'references/archive' -prune -o -type f -print)
if [ -n "$reference_file_list" ]; then
  set -- $reference_file_list
  active_reference_files=$#
  active_reference_lines=$(count_lines_for_files "$@")
else
  active_reference_files=0
  active_reference_lines=0
fi

total_active_files=$((1 + docs_files + skills_files + roles_files + scripts_files + active_reference_files))
total_active_lines=$((readme_lines + docs_lines + skills_lines + roles_lines + scripts_lines + active_reference_lines))

ok=1
detail_lines=""

check_max "README lines" "$readme_lines" "$max_readme_lines"
check_max "docs files" "$docs_files" "$max_docs_files"
check_max "docs lines" "$docs_lines" "$max_docs_lines"
check_max "skills files" "$skills_files" "$max_skills_files"
check_max "skills lines" "$skills_lines" "$max_skills_lines"
check_max "roles files" "$roles_files" "$max_roles_files"
check_max "roles lines" "$roles_lines" "$max_roles_lines"
check_max "scripts files" "$scripts_files" "$max_scripts_files"
check_max "scripts lines" "$scripts_lines" "$max_scripts_lines"
check_max "active reference files" "$active_reference_files" "$max_active_reference_files"
check_max "active reference lines" "$active_reference_lines" "$max_active_reference_lines"
check_max "total active files" "$total_active_files" "$max_total_active_files"
check_max "total active lines" "$total_active_lines" "$max_total_active_lines"

status="ok"; growth_state="headroom-available"
[ "$ok" -eq 1 ] || status="fail"
[ "$ok" -eq 1 ] || growth_state="breached"
if [ "$growth_state" = "headroom-available" ] && { [ "$total_active_files" -eq "$max_total_active_files" ] || [ "$total_active_lines" -eq "$max_total_active_lines" ]; }; then growth_state="saturated"; fi

say "entropy budget audit: $status"
say "- Budget mode: $budget_mode | explicit decision required: $budget_change_requires_explicit_decision | growth state: $growth_state"
say "- Active totals: files $total_active_files/$max_total_active_files | lines $total_active_lines/$max_total_active_lines | headroom files $((max_total_active_files - total_active_files)) | lines $((max_total_active_lines - total_active_lines))"
[ -n "$detail_lines" ] && [ "$quiet" != "--quiet" ] && printf '%s' "$detail_lines"

if [ "$ok" -eq 1 ]; then
  exit 0
fi

exit 1
