#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

workstream="${1:-}"
title="${2:-daily-report}"

if [ -z "$workstream" ]; then
  echo "usage: $0 <workstream> [title]" >&2
  exit 1
fi

require_advanced_governance_runtime_artifact "workstream daily report" || exit 1

base=".harness/workspace/workstreams/${workstream}/workspace/reports/daily"
if [ ! -d "$base" ]; then
  echo "unknown workstream daily reports path: $base" >&2
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
# Daily Workstream Report

- Date: $date
- Workstream: $workstream
- Owner:
- Inputs received:
- Outputs shipped:
- Current blockers:
- Failed or delayed handoffs:
- Process friction observed:
- Suggested improvements:
EOF

echo "$target"
