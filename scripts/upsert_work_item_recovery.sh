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
current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
today=$(date +%F)

if [ -n "$expected_version" ]; then
  if ! is_nonnegative_integer "$expected_version"; then
    echo "invalid expected-version: $expected_version" >&2
    exit 1
  fi

  if [ "$expected_version" != "$current_version" ]; then
    echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
    exit 1
  fi
fi

rewrite_work_item_recovery_section "$work_item_file" "$current_focus" "$next_command" "$recovery_notes"
rewrite_work_item_header_snapshot "$work_item_file" "Updated at" "$today"

echo "$work_item_file"
