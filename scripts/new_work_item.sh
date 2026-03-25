#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

type="${1:-}"
title="${2:-}"
owner="${3:-Chief of Staff}"
priority="${4:-medium}"
sponsor="${5:-chief-of-staff}"
actor="${STATE_ACTOR:-}"
require_explicit_state_actor "$actor" "$0"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

if [ -z "$type" ] || [ -z "$title" ]; then
  echo "usage: $0 <type> <title> [owner] [priority] [sponsor]" >&2
  exit 1
fi

if ! is_valid_type "$type"; then
  echo "invalid type: $type" >&2
  exit 1
fi

if ! is_valid_priority "$priority"; then
  echo "invalid priority: $priority" >&2
  exit 1
fi

ensure_state_dirs
id=$(next_work_item_id)
date=$(date +%F)
target=$(work_item_path "$id")
operation_id=$(default_operation_id "$id" "create")

cat >"$target" <<EOF
# Work Item

- Schema version: $work_item_schema_version
- State authority: $work_item_state_authority
- State version: 1
- Last operation ID: $operation_id
- ID: $id
- Title: $title
- Type: $type
- Status: backlog
- Priority: $priority
- Owner: $owner
- Sponsor: $sponsor
- Objective: none
- Ready criteria: none
- Done criteria: none
- Required artifacts: none
- Why it matters: fill-me
- Decision needed: none
- Deadline: none
- Created at: $date
- Updated at: $date
- Due review at: none
- Founder escalation: not-needed
- Required departments: none
- Participation records: none
- Linked artifacts: none
- Last transition event: none
- Interrupt marker: none
- Resume target: none
- Blocked by: none
- Blocks: none
- Current blocker: none
- Next handoff: none

## Summary

- fill-me

## Notes

- Seeded by ./.agents/skills/harness/scripts/new_work_item.sh on $date.
EOF

event_path=$(write_transition_event "$id" "none" "backlog" "$actor" "work item created" "none" "none" "$operation_id" "none" "0" "0" "1" "none" "none" "state-transition")
replace_field "$target" "Last transition event" "$event_path"
"$script_dir/refresh_boards.sh" >/dev/null

echo "$target"
