#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

work_item_id=""
operation_id=""
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  cat <<EOF >&2
usage: $0 [--work-item <WI-xxxx>] [--operation-id <id>] <title>

Role change proposals are task-scoped compounding artifacts.
Pass --work-item explicitly.
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --work-item)
      [ "$#" -ge 2 ] || usage
      work_item_id="$2"
      shift 2
      ;;
    --operation-id)
      [ "$#" -ge 2 ] || usage
      operation_id="$2"
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

title="${1:-}"
[ -n "$title" ] || usage

slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
if [ -z "$work_item_id" ]; then
  echo "role change proposal requires --work-item <WI-xxxx>; task-local routing is explicit in v2." >&2
  exit 1
fi

require_work_item "$work_item_id" >/dev/null
ensure_task_directory_skeleton "$work_item_id"
target="$(canonical_work_item_closure_dir "$work_item_id")/${date}-${slug}-role-change-proposal.md"

mkdir -p "$(dirname "$target")"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

cat >"$target" <<EOF
# Role Change Proposal

- Linked work items: $work_item_id
- Date: $date
- Proposal owner:
- Acceptance artifact:
- Signals reviewed:
- Existing roles consulted:
- Problem observed:
- Why current role coverage is insufficient:
- Decision type: create / edit / merge / retire
- Proposed role slug: $slug
- Proposed write scope: .harness/workspace/roles/
- Required interfaces:
- Provider impact: none / user-owned adapter update / manual follow-up
- Risks:
- Validation plan:
- Runtime Role Manager handoff:
EOF

require_explicit_state_actor "$actor" "$0"
work_item_file=$(require_work_item "$work_item_id")
expected_version=$(field_value "$work_item_file" "State version")

if [ -n "$operation_id" ]; then
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    --operation-id "$operation_id" \
    "$work_item_id" \
    "$target" \
    "role-change-proposal" \
    "draft" >/dev/null
else
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    "$work_item_id" \
    "$target" \
    "role-change-proposal" \
    "draft" >/dev/null
fi

echo "$target"
