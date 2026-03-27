#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

expected_version=""
operation_id=""
actor="${STATE_ACTOR:-}"
require_explicit_state_actor "$actor" "$0"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  echo "usage: $0 --expected-version <version> [--operation-id <id>] <work-item-id> [reason]" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-version)
      [ "$#" -ge 2 ] || usage
      expected_version="$2"
      shift 2
      ;;
    --operation-id)
      [ "$#" -ge 2 ] || usage
      operation_id="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage
      ;;
    *)
      break
      ;;
  esac
done

work_item_id="${1:-}"
reason="${2:-terminal cleanup complete}"

if [ -z "$work_item_id" ] || [ -z "$expected_version" ]; then
  usage
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

acquire_runtime_lock
acquire_work_item_lock "$work_item_id"
work_item_file=$(require_work_item_for_write "$work_item_id")
status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")

case "$status" in
  done|killed) ;;
  *)
    echo "work item is not terminal: $work_item_id ($status)" >&2
    exit 1
    ;;
esac

if ! is_nonnegative_integer "$current_version"; then
  echo "invalid current state version in $work_item_file: $current_version" >&2
  exit 1
fi

if [ "$expected_version" != "$current_version" ]; then
  echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
  exit 1
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$work_item_id" "terminal-cleanup")
fi

dependent_items=""
for candidate in $(list_work_items); do
  candidate_id=$(field_value "$candidate" "ID")
  [ "$candidate_id" = "$work_item_id" ] && continue
  blocked_by=$(field_value "$candidate" "Blocked by")
  if csv_contains_value "$blocked_by" "$work_item_id"; then
    if [ -z "$dependent_items" ]; then
      dependent_items="$candidate_id"
    else
      dependent_items="${dependent_items},$candidate_id"
    fi
  fi
done

if [ "$status" = "killed" ] && ! value_is_missing "$dependent_items"; then
  echo "cannot cleanup killed work item while dependents still reference it: $dependent_items" >&2
  exit 1
fi

blocked_by=$(field_value "$work_item_file" "Blocked by")
blocks=$(field_value "$work_item_file" "Blocks")
current_blocker=$(field_value "$work_item_file" "Current blocker")
next_handoff=$(field_value "$work_item_file" "Next handoff")
interrupt_marker=$(field_value_or_none "$work_item_file" "Interrupt marker")
resume_target=$(field_value_or_none "$work_item_file" "Resume target")
root_cleanup_needed=0

for candidate_value in "$blocked_by" "$blocks" "$current_blocker" "$next_handoff" "$interrupt_marker" "$resume_target"; do
  if ! value_is_missing "$candidate_value"; then
    root_cleanup_needed=1
    break
  fi
done

if [ "$root_cleanup_needed" -ne 1 ]; then
  refresh_boards_if_enabled
  echo "$work_item_file"
  exit 0
fi

next_version=$((current_version + 1))
event_path=$(write_transition_event \
  "$work_item_id" \
  "$status" \
  "$status" \
  "$actor" \
  "$reason" \
  "none" \
  "none" \
  "$operation_id" \
  "$status" \
  "$current_version" \
  "$current_version" \
  "$next_version" \
  "none" \
  "none" \
  "terminal-cleanup")
rewrite_work_item_header_snapshot "$work_item_file" \
  "Blocked by" "none" \
  "Blocks" "none" \
  "Current blocker" "none" \
  "Next handoff" "none" \
  "Interrupt marker" "none" \
  "Resume target" "none" \
  "Updated at" "$(date +%F)" \
  "State version" "$next_version" \
  "Last operation ID" "$operation_id" \
  "Last transition event" "$event_path"
sync_recovery_snapshot_if_present "$work_item_file"
refresh_boards_if_enabled

echo "$work_item_file"
