#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

expected_from_status=""
expected_version=""
operation_id=""
current_blocker=""
next_handoff=""

usage() {
  echo "usage: $0 --expected-from-status <status> --expected-version <version> [--operation-id <id>] <work-item-id> <done|killed> [current-blocker] [next-handoff] [reason]" >&2
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
terminal_status="${2:-}"
current_blocker="${3:-}"
next_handoff="${4:-}"
reason="${5:-terminal transition}"

if [ -z "$work_item_id" ] || [ -z "$terminal_status" ] || [ -z "$expected_from_status" ] || [ -z "$expected_version" ]; then
  usage
fi

case "$terminal_status" in
  done|killed) ;;
  *)
    echo "finalize_work_item only supports done or killed, got: $terminal_status" >&2
    exit 1
    ;;
esac

if ! is_valid_work_item_status "$expected_from_status"; then
  echo "invalid expected-from-status: $expected_from_status" >&2
  exit 1
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$work_item_id" "finalize-$terminal_status")
fi

transition_operation_id="${operation_id}-transition"
cleanup_operation_id="${operation_id}-cleanup"
work_item_file=$(require_work_item "$work_item_id")
current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")

if [ "$current_status" = "$terminal_status" ]; then
  if [ "$expected_from_status" != "$terminal_status" ]; then
    echo "expected-from-status mismatch for already-terminal item: wanted $expected_from_status but found $current_status" >&2
    exit 1
  fi
  if [ "$expected_version" != "$current_version" ]; then
    echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
    exit 1
  fi
  post_transition_file="$work_item_file"
  post_transition_version="$current_version"
else
  STATE_ALLOW_TERMINAL_TRANSITION=1 "$script_dir/transition_work_item.sh" \
    --expected-from-status "$expected_from_status" \
    --expected-version "$expected_version" \
    --operation-id "$transition_operation_id" \
    "$work_item_id" \
    "$terminal_status" \
    "$current_blocker" \
    "$next_handoff" \
    "$reason" >/dev/null

  post_transition_file=$(require_work_item "$work_item_id")
  post_transition_version=$(field_value "$post_transition_file" "State version")
fi

"$script_dir/cleanup_terminal_work_item.sh" \
  --expected-version "$post_transition_version" \
  --operation-id "$cleanup_operation_id" \
  "$work_item_id" \
  "terminal cleanup after $terminal_status" >/dev/null

echo "$post_transition_file"
