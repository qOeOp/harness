#!/bin/sh
set -eu

title="${1:-untitled-dispatch}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
target=".harness/workspace/research/dispatches/${date}-${slug}.md"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Research Dispatch

- Date: $date
- Dispatcher:
- Topic: $title
- Volatile status: volatile-by-default / stable / unknown
- Research owner:
- Required freshness window:
- Required source types:
- Required deliverable:
- Downstream consumer:
- Blocking status: open / blocked / satisfied / not-needed
- Notes:
EOF

echo "$target"
