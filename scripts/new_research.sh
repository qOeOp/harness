#!/bin/sh
set -eu

scope="${1:-company}"
title="${2:-untitled-research}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ "$scope" = "company" ]; then
  target=".harness/workspace/briefs/${slug}.md"
else
  target=".harness/workspace/departments/${scope}/workspace/memos/${date}-${slug}.md"
fi

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Research Memo

- Date: $date
- Owner:
- Question: $title
- Scope:
- Research dispatch: .harness/workspace/research/dispatches/...md / n/a
- Verification date:
- Verification mode: internal-only / web-verified / mixed
- Freshness level: stable / volatile
- Sources reviewed:
- Conflicting sources:
- Earliest-source check:
- Strongest evidence:
- Strongest counter-evidence:
- Unknowns:
- Risks:
- Recommendation:
EOF

echo "$target"
