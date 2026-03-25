#!/bin/sh
set -eu

department="${1:-}"
title="${2:-daily-report}"

if [ -z "$department" ]; then
  echo "usage: $0 <department> [title]" >&2
  exit 1
fi

base=".harness/workspace/departments/${department}/workspace/reports/daily"
if [ ! -d "$base" ]; then
  echo "unknown department daily reports path: $base" >&2
  exit 1
fi

slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
target="${base}/${date}-${slug}.md"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Daily Department Report

- Date: $date
- Department: $department
- Owner:
- Inputs received:
- Outputs shipped:
- Current blockers:
- Failed or delayed handoffs:
- Process friction observed:
- Suggested improvements:
EOF

echo "$target"
