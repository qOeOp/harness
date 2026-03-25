#!/bin/sh
set -eu

scope="${1:-company}"
title="${2:-untitled-decision}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ "$scope" = "company" ]; then
  target=".harness/workspace/decisions/log/${date}-${slug}.md"
else
  target=".harness/workspace/departments/${scope}/workspace/outputs/${date}-${slug}.md"
fi

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Decision Pack

- Date: $date
- Owner:
- Decision: $title
- Why now:
- Research dispatch: .harness/workspace/research/dispatches/...md / n/a
- Verification date:
- Verification mode: internal-only / web-verified / mixed
- Sources reviewed:
- Evidence:
- Dissent:
- Risks:
- Freshness caveats:
- Tradeoffs:
- Ask from Founder:
- Next 7 days:
EOF

echo "$target"
