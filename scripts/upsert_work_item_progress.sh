#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

expected_version=""
operation_id=""
actor="${STATE_ACTOR:-}"

usage() {
  echo "usage: $0 [--expected-version <version>] [--operation-id <id>] <work-item-id> <current-focus> <next-command> [recovery-notes]" >&2
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
current_focus="${2:-}"
next_command="${3:-}"
recovery_notes="${4:-none}"

if [ -z "$work_item_id" ] || [ -z "$current_focus" ] || [ -z "$next_command" ]; then
  usage
fi

ensure_state_dirs
acquire_work_item_lock "$work_item_id"
work_item_file=$(require_work_item_for_write "$work_item_id")
ensure_task_directory_skeleton "$work_item_id"
progress_path=$(work_item_progress_path_for_write "$work_item_id")
today=$(date +%F)
created_at=""

current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
current_operation_id=$(field_value "$work_item_file" "Last operation ID")

if [ -f "$progress_path" ]; then
  created_at=$(field_value "$progress_path" "Created at")
else
  created_at=""
fi

if [ -z "$created_at" ]; then
  created_at="$today"
fi

rewrite_progress_snapshot_file "$progress_path" \
  "Linked work items" "$work_item_id" \
  "Work Item" "$work_item_id" \
  "Created at" "$created_at" \
  "Updated at" "$today" \
  "Status snapshot" "$current_status" \
  "State version snapshot" "$current_version" \
  "Last operation ID snapshot" "$current_operation_id" \
  "Current focus" "$current_focus" \
  "Next command" "$next_command" \
  "Recovery notes" "$recovery_notes"

existing_entry=$(linked_artifact_entry_for_path "$work_item_file" "$progress_path" || true)
desired_entry="$progress_path|progress-artifact|active"

if [ "$existing_entry" != "$desired_entry" ] || ! artifact_has_work_item_link "$progress_path" "$work_item_id"; then
  require_explicit_state_actor "$actor" "$0"

  if [ -z "$expected_version" ]; then
    echo "expected-version is required when linking a new progress artifact" >&2
    exit 1
  fi

  if ! is_nonnegative_integer "$expected_version"; then
    echo "invalid expected-version: $expected_version" >&2
    exit 1
  fi

  if [ -z "$operation_id" ]; then
    operation_id=$(default_operation_id "$work_item_id" "link-progress")
  fi

  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    --operation-id "$operation_id" \
    "$work_item_id" \
    "$progress_path" \
    "progress-artifact" \
    "active" >/dev/null
fi

current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
current_operation_id=$(field_value "$work_item_file" "Last operation ID")

rewrite_progress_snapshot_file "$progress_path" \
  "Linked work items" "$work_item_id" \
  "Work Item" "$work_item_id" \
  "Updated at" "$today" \
  "Status snapshot" "$current_status" \
  "State version snapshot" "$current_version" \
  "Last operation ID snapshot" "$current_operation_id"

case "$current_status" in
  in-progress|paused)
    claim_current_task_id_for_execution "$work_item_id" "$current_status"
    ;;
  *)
    ensure_current_task_pointer
    ;;
esac

echo "$progress_path"
