#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

expected_version=""
operation_id=""

usage() {
  echo "usage: $0 --expected-version <version> [--operation-id <id>] <work-item-id> [next-handoff] [reason]" >&2
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
next_handoff="${2:-none}"
reason="${3:-}"

if [ -z "$work_item_id" ] || [ -z "$expected_version" ]; then
  usage
fi

work_item_file=$(require_work_item "$work_item_id")
current_status=$(field_value "$work_item_file" "Status")
interrupt_marker=$(field_value_or_none "$work_item_file" "Interrupt marker")
resume_target=$(field_value_or_none "$work_item_file" "Resume target")

if [ "$current_status" != "paused" ]; then
  echo "work item is not paused: $work_item_id ($current_status)" >&2
  exit 1
fi

if value_is_missing "$interrupt_marker" || value_is_missing "$resume_target"; then
  echo "paused work item is missing interrupt metadata: $work_item_id" >&2
  exit 1
fi

if [ -z "$reason" ]; then
  reason="work item resumed after $interrupt_marker via ./.agents/skills/harness/scripts/resume_work_item.sh"
fi

if [ -n "$operation_id" ]; then
  exec "$script_dir/transition_work_item.sh" \
    --expected-from-status paused \
    --expected-version "$expected_version" \
    --operation-id "$operation_id" \
    --interrupt-marker none \
    --resume-target none \
    "$work_item_id" \
    "$resume_target" \
    none \
    "$next_handoff" \
    "$reason"
fi

exec "$script_dir/transition_work_item.sh" \
  --expected-from-status paused \
  --expected-version "$expected_version" \
  --interrupt-marker none \
  --resume-target none \
  "$work_item_id" \
  "$resume_target" \
  none \
  "$next_handoff" \
  "$reason"
