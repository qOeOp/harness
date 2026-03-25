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

work_item_file=$(require_work_item "$work_item_id")
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

if [ "$status" = "done" ] && ! value_is_missing "$dependent_items"; then
  old_ifs=${IFS- }
  IFS=','
  set -- $dependent_items
  IFS=$old_ifs

  for dependent_id in "$@"; do
    dependent_id=$(trim "$dependent_id")
    [ -n "$dependent_id" ] || continue
    dependent_file=$(require_work_item "$dependent_id")
    dependent_status=$(field_value "$dependent_file" "Status")
    dependent_blocked_by=$(field_value "$dependent_file" "Blocked by")
    dependent_current_version=$(field_value "$dependent_file" "State version")
    dependent_current_blocker=$(field_value "$dependent_file" "Current blocker")
    dependent_next_handoff=$(field_value "$dependent_file" "Next handoff")
    updated_blocked_by=$(csv_remove_value "$dependent_blocked_by" "$work_item_id")

    if [ "$updated_blocked_by" = "$dependent_blocked_by" ]; then
      continue
    fi

    dependent_operation_id="${operation_id}-release-${dependent_id}"
    dependent_next_version=$((dependent_current_version + 1))

    replace_field "$dependent_file" "Blocked by" "$updated_blocked_by"
    replace_field "$dependent_file" "Updated at" "$(date +%F)"
    replace_field "$dependent_file" "State version" "$dependent_next_version"
    replace_field "$dependent_file" "Last operation ID" "$dependent_operation_id"
    dependent_event=$(write_transition_event \
      "$dependent_id" \
      "$dependent_status" \
      "$dependent_status" \
      "$actor" \
      "released blocker $work_item_id during terminal cleanup" \
      "$dependent_current_blocker" \
      "$dependent_next_handoff" \
      "$dependent_operation_id" \
      "$dependent_status" \
      "$dependent_current_version" \
      "$dependent_current_version" \
      "$dependent_next_version" \
      "$(field_value_or_none "$dependent_file" "Interrupt marker")" \
      "$(field_value_or_none "$dependent_file" "Resume target")" \
      "blocker-release")
    replace_field "$dependent_file" "Last transition event" "$dependent_event"
    sync_progress_snapshot_if_present "$dependent_file"
  done
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

if [ "$status" = "done" ] && ! value_is_missing "$dependent_items"; then
  root_cleanup_needed=1
fi

if [ "$root_cleanup_needed" -ne 1 ]; then
  "$script_dir/refresh_boards.sh" >/dev/null
  echo "$work_item_file"
  exit 0
fi

next_version=$((current_version + 1))
replace_field "$work_item_file" "Blocked by" "none"
replace_field "$work_item_file" "Blocks" "none"
replace_field "$work_item_file" "Current blocker" "none"
replace_field "$work_item_file" "Next handoff" "none"
replace_field "$work_item_file" "Interrupt marker" "none"
replace_field "$work_item_file" "Resume target" "none"
replace_field "$work_item_file" "Updated at" "$(date +%F)"
replace_field "$work_item_file" "State version" "$next_version"
replace_field "$work_item_file" "Last operation ID" "$operation_id"
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
replace_field "$work_item_file" "Last transition event" "$event_path"
sync_progress_snapshot_if_present "$work_item_file"
"$script_dir/refresh_boards.sh" >/dev/null

echo "$work_item_file"
