#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

work_item_id=""
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  echo "usage: $0 [--work-item <WI-xxxx>] [company|<department>] <title>" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --work-item)
      [ "$#" -ge 2 ] || usage
      work_item_id="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      break
      ;;
  esac
done

scope="${1:-company}"
title="${2:-untitled-research}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ -n "$work_item_id" ]; then
  require_work_item "$work_item_id" >/dev/null
  ensure_task_directory_skeleton "$work_item_id"
  set_current_task_id "$work_item_id"
  target="$(canonical_work_item_refs_dir "$work_item_id")/${date}-${slug}-research-memo.md"
elif [ "$scope" = "company" ]; then
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

- Linked work items: ${work_item_id:-n/a}
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

if [ -n "$work_item_id" ]; then
  require_explicit_state_actor "$actor" "$0"
  work_item_file=$(require_work_item "$work_item_id")
  expected_version=$(field_value "$work_item_file" "State version")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    "$work_item_id" \
    "$target" \
    "research-memo" \
    "draft" >/dev/null
fi

echo "$target"
