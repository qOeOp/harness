#!/bin/sh
set -eu

title="${1:-untitled-intake}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
target=".harness/workspace/intake/inbox/${date}-${slug}.md"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Material Intake

- Date: $date
- Submitted by:
- Type:
- Source:
- Summary: $title
- Why Vincent thinks it matters:
- Candidate workstreams affected:
- Immediate action requested:
- Initial triage:
- Notes:
EOF

echo "$target"
