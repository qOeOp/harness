#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
digest_template_path="$repo_root/skills/daily-digest/templates/company-daily-digest.md"

date="${1:-$(date +%F)}"
target=".harness/workspace/status/digests/${date}-company-digest.md"

render_company_digest_template() {
  report_summary="$1"

  [ -f "$digest_template_path" ] || {
    echo "missing template: $digest_template_path" >&2
    exit 1
  }

  awk \
    -v digest_date="$date" \
    -v report_summary="$report_summary" \
    '
      /^- Date:$/ { $0 = "- Date: " digest_date }
      /^- Owner:$/ { $0 = "- Owner: Chief of Staff" }
      /^- Department reports reviewed:$/ { $0 = "- Department reports reviewed: " report_summary }
      /^- Company-wide inputs:$/ { $0 = "- Company-wide inputs: Review department snapshots below and synthesize common inputs." }
      /^- Company-wide outputs:$/ { $0 = "- Company-wide outputs: Review department snapshots below and synthesize shipped outputs." }
      /^- Key blockers:$/ { $0 = "- Key blockers: Review department blockers below and collapse duplicates." }
      /^- Cross-department risks:$/ { $0 = "- Cross-department risks: Review failed handoffs and process friction below." }
      /^- Decisions at risk:$/ { $0 = "- Decisions at risk: Fill after reviewing blockers and unresolved dependencies." }
      /^- Escalations for Founder:$/ { $0 = "- Escalations for Founder: Fill only if a blocker truly requires Founder intervention." }
      { print }
    ' \
    "$digest_template_path"
}

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

extract_field() {
  file="$1"
  label="$2"

  awk -v label="$label" '
    BEGIN {
      prefix = "- " label ":"
      capture = 0
    }
    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value != "") {
        print value
      }
      capture = 1
      next
    }
    capture == 1 {
      if ($0 ~ /^-[[:space:]]/) {
        exit
      }
      if ($0 ~ /^[[:space:]]*$/) {
        next
      }
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print $0
    }
  ' "$file" | paste -sd ' ' -
}

reports_tmp=$(mktemp)
trap 'rm -f "$reports_tmp"' EXIT

find .harness/workspace/departments -path "*/workspace/reports/daily/${date}-*.md" ! -name README.md -type f | sort >"$reports_tmp"

if [ -s "$reports_tmp" ]; then
  report_summary="see department snapshots below"
else
  report_summary="none yet"
fi

render_company_digest_template "$report_summary" >"$target"
printf '\n' >>"$target"

if [ -s "$reports_tmp" ]; then
  {
    printf '## Department Snapshots\n\n'

    while IFS= read -r report; do
      [ -n "$report" ] || continue

      department=$(extract_field "$report" "Department")
      owner=$(extract_field "$report" "Owner")
      inputs=$(extract_field "$report" "Inputs received")
      outputs=$(extract_field "$report" "Outputs shipped")
      blockers=$(extract_field "$report" "Current blockers")
      handoffs=$(extract_field "$report" "Failed or delayed handoffs")
      friction=$(extract_field "$report" "Process friction observed")
      improvements=$(extract_field "$report" "Suggested improvements")

      [ -n "$department" ] || department="unknown"
      [ -n "$owner" ] || owner="unassigned"
      [ -n "$inputs" ] || inputs="none recorded"
      [ -n "$outputs" ] || outputs="none recorded"
      [ -n "$blockers" ] || blockers="none recorded"
      [ -n "$handoffs" ] || handoffs="none recorded"
      [ -n "$friction" ] || friction="none recorded"
      [ -n "$improvements" ] || improvements="none recorded"

      printf '### %s\n\n' "$department"
      printf -- '- Report: %s\n' "$report"
      printf -- '- Owner: %s\n' "$owner"
      printf -- '- Inputs received: %s\n' "$inputs"
      printf -- '- Outputs shipped: %s\n' "$outputs"
      printf -- '- Current blockers: %s\n' "$blockers"
      printf -- '- Failed or delayed handoffs: %s\n' "$handoffs"
      printf -- '- Process friction observed: %s\n' "$friction"
      printf -- '- Suggested improvements: %s\n' "$improvements"
      printf '\n'
    done <"$reports_tmp"
  } >>"$target"
fi

echo "$target"
