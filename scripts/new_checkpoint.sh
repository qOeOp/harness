#!/bin/sh
set -eu

label="${1:-checkpoint}"
slug=$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
mkdir -p .harness/workspace/status/snapshots
target=".harness/workspace/status/snapshots/${date}-${slug}.md"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Status Snapshot

- Date: $date
- Label: $label
- New decisions:
- Open risks:
- Follow-ups:
- What changed in current state:
EOF

echo "$target"
