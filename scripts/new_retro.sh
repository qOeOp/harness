#!/bin/sh
set -eu

scope="${1:-}"
label="${2:-retro}"

if [ -z "$scope" ]; then
  echo "usage: $0 <company|department> [label]" >&2
  exit 1
fi

slug=$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ "$scope" = "company" ]; then
  target=".harness/workspace/status/process-audits/${date}-${slug}.md"
  cat >"$target" <<EOF
# Process Audit

- Date: $date
- Owner:
- Scope: company
- Signals reviewed:
- Repeated frictions:
- Cross-department failures:
- Candidate root causes:
- Proposed experiments:
- Risks of change:
- Recommendation:
EOF
  echo "$target"
  exit 0
fi

base=".harness/workspace/departments/${scope}/workspace/reports/retros"
if [ ! -d "$base" ]; then
  echo "unknown department retros path: $base" >&2
  exit 1
fi

target="${base}/${date}-${slug}.md"
if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Department Retro

- Date: $date
- Department: $scope
- Owner:
- Period covered:
- What worked:
- What slowed us down:
- Failed handoffs:
- Repeated mistakes:
- Improvements to try:
- What should be escalated:
EOF

echo "$target"
