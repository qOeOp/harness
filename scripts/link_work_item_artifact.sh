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
  echo "usage: $0 --expected-version <version> [--operation-id <id>] <work-item-id> <artifact-path> <artifact-type> <artifact-status>" >&2
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
artifact_path="${2:-}"
artifact_type="${3:-}"
artifact_status="${4:-}"

if [ -z "$work_item_id" ] || [ -z "$artifact_path" ] || [ -z "$artifact_type" ] || [ -z "$artifact_status" ]; then
  usage
fi

if [ -z "$expected_version" ]; then
  usage
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

if [ ! -f "$artifact_path" ]; then
  echo "missing artifact: $artifact_path" >&2
  exit 1
fi

if ! is_valid_artifact_status "$artifact_status"; then
  echo "invalid artifact status: $artifact_status" >&2
  exit 1
fi

acquire_work_item_lock "$work_item_id"
work_item_file=$(require_work_item_for_write "$work_item_id")
current_version=$(field_value "$work_item_file" "State version")
current_status=$(field_value "$work_item_file" "Status")
current_last_operation_id=$(field_value "$work_item_file" "Last operation ID")
current_last_transition_event=$(field_value "$work_item_file" "Last transition event")
existing_entry=$(linked_artifact_entry_for_path "$work_item_file" "$artifact_path" || true)
desired_entry="$artifact_path|$artifact_type|$artifact_status"

if ! is_nonnegative_integer "$current_version"; then
  echo "invalid current state version in $work_item_file: $current_version" >&2
  exit 1
fi

if [ "$expected_version" != "$current_version" ]; then
  echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
  exit 1
fi

if [ -n "$operation_id" ] && [ "$current_last_operation_id" = "$operation_id" ] && [ -f "$current_last_transition_event" ]; then
  if [ "$existing_entry" = "$desired_entry" ] && artifact_has_work_item_link "$artifact_path" "$work_item_id"; then
    echo "$work_item_file"
    echo "$artifact_path"
    exit 0
  fi
  echo "operation id already used for a different artifact mutation: $operation_id" >&2
  exit 1
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$work_item_id" "link-artifact")
fi

if [ "$existing_entry" = "$desired_entry" ] && artifact_has_work_item_link "$artifact_path" "$work_item_id"; then
  echo "$work_item_file"
  echo "$artifact_path"
  exit 0
fi

updated_artifact_entries=$(updated_linked_artifacts_value "$(field_value "$work_item_file" "Linked attachments")" "$artifact_path" "$artifact_type" "$artifact_status")
upsert_task_ref_index_entry "$work_item_id" "$artifact_path" "$artifact_type" "$artifact_status"
next_version=$((current_version + 1))
upsert_artifact_work_item_links "$artifact_path" "$work_item_id"
event_path=$(write_transition_event "$work_item_id" "$current_status" "$current_status" "$actor" "artifact link updated" "$(field_value "$work_item_file" "Current blocker")" "$(field_value "$work_item_file" "Next handoff")" "$operation_id" "$current_status" "$expected_version" "$current_version" "$next_version" "$(field_value_or_none "$work_item_file" "Interrupt marker")" "$(field_value_or_none "$work_item_file" "Resume target")" "artifact-link")
rewrite_work_item_header_snapshot "$work_item_file" \
  "Linked attachments" "$updated_artifact_entries" \
  "Updated at" "$(date +%F)" \
  "State version" "$next_version" \
  "Last operation ID" "$operation_id" \
  "Last transition event" "$event_path"
sync_recovery_snapshot_if_present "$work_item_file"
refresh_boards_if_enabled

echo "$work_item_file"
echo "$artifact_path"
