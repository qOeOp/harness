#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

expected_from_status=""
expected_version=""
operation_id=""
interrupt_marker=""

usage() {
  printf 'usage: %s --expected-from-status <status> --expected-version <version> --interrupt-marker <marker> [--operation-id <id>] <work-item-id> [current-blocker] [next-handoff] [reason]\n' "$(default_harness_command "pause_work_item.sh")" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-from-status)
      [ "$#" -ge 2 ] || usage
      expected_from_status="$2"
      shift 2
      ;;
    --expected-version)
      [ "$#" -ge 2 ] || usage
      expected_version="$2"
      shift 2
      ;;
    --interrupt-marker)
      [ "$#" -ge 2 ] || usage
      interrupt_marker="$2"
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
current_blocker="${2:-}"
next_handoff="${3:-}"
reason="${4:-}"

if [ -z "$work_item_id" ] || [ -z "$expected_from_status" ] || [ -z "$expected_version" ] || [ -z "$interrupt_marker" ]; then
  usage
fi

if ! is_valid_interrupt_marker "$interrupt_marker" || [ "$interrupt_marker" = "none" ]; then
  echo "invalid interrupt marker: $interrupt_marker" >&2
  exit 1
fi

if [ -z "$current_blocker" ]; then
  current_blocker=$(interrupt_default_blocker "$interrupt_marker")
fi

if [ -z "$reason" ]; then
  reason="work item paused for $interrupt_marker via $(default_harness_command "pause_work_item.sh")"
fi

if [ -n "$operation_id" ]; then
  set -- "$script_dir/transition_work_item.sh" \
    --expected-from-status "$expected_from_status" \
    --expected-version "$expected_version" \
    --operation-id "$operation_id" \
    --interrupt-marker "$interrupt_marker" \
    --resume-target "$expected_from_status" \
    "$work_item_id" \
    paused \
    "$current_blocker" \
    "$next_handoff" \
    "$reason"
else
  set -- "$script_dir/transition_work_item.sh" \
    --expected-from-status "$expected_from_status" \
    --expected-version "$expected_version" \
    --interrupt-marker "$interrupt_marker" \
    --resume-target "$expected_from_status" \
    "$work_item_id" \
    paused \
    "$current_blocker" \
    "$next_handoff" \
    "$reason"
fi

exec "$@"
