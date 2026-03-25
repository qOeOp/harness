#!/bin/sh
set -eu

title="${1:-untitled-source}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
target=".harness/workspace/research/sources/${date}-${slug}.md"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Source Note

- Date: $date
- Source: $title
- URL:
- Type:
- Accessed date: $date
- Trust level:
- Notes:
EOF

echo "$target"
