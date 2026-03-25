#!/bin/sh
set -eu

date="${1:-$(date +%F)}"
target=".harness/workspace/status/digests/${date}-company-digest.md"

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

{
  printf '# Company Daily Digest\n\n'
  printf -- '- Date: %s\n' "$date"
  printf -- '- Owner: Chief of Staff\n'
  printf -- '- Department reports reviewed:\n'

  if [ -s "$reports_tmp" ]; then
    while IFS= read -r report; do
      [ -n "$report" ] || continue
      printf '  - %s\n' "$report"
    done <"$reports_tmp"
  else
    printf '  - none yet\n'
  fi

  printf -- '- Company-wide inputs:\n'
  printf '  - Review department snapshots below and synthesize common inputs.\n'
  printf -- '- Company-wide outputs:\n'
  printf '  - Review department snapshots below and synthesize shipped outputs.\n'
  printf -- '- Key blockers:\n'
  printf '  - Review department blockers below and collapse duplicates.\n'
  printf -- '- Cross-department risks:\n'
  printf '  - Review failed handoffs and process friction below.\n'
  printf -- '- Decisions at risk:\n'
  printf '  - Fill after reviewing blockers and unresolved dependencies.\n'
  printf -- '- Escalations for Founder:\n'
  printf '  - Fill only if a blocker truly requires Founder intervention.\n'
  printf '\n'
} >"$target"

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
