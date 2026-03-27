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
  echo "usage: $0 --expected-version <version> [--operation-id <id>] <work-item-id> <artifact-path> <new-status> [artifact-type]" >&2
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
new_status="${3:-}"
artifact_type="${4:-}"

if [ -z "$work_item_id" ] || [ -z "$artifact_path" ] || [ -z "$new_status" ] || [ -z "$expected_version" ]; then
  usage
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

if ! is_valid_artifact_status "$new_status"; then
  echo "invalid artifact status: $new_status" >&2
  exit 1
fi

work_item_file=$(require_work_item "$work_item_id")

if [ ! -f "$artifact_path" ]; then
  echo "missing artifact: $artifact_path" >&2
  exit 1
fi

if [ -z "$artifact_type" ]; then
  artifact_type=$(linked_artifact_type_for_path "$work_item_file" "$artifact_path" || true)
fi

if [ -z "$artifact_type" ]; then
  echo "artifact type is required when artifact is not already linked: $artifact_path" >&2
  exit 1
fi

current_status=$(linked_artifact_status_for_path "$work_item_file" "$artifact_path" || true)
if [ "$current_status" = "$new_status" ]; then
  printf '%s\n' "$artifact_path"
  exit 0
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$work_item_id" "artifact-status-$new_status")
fi

"$script_dir/link_work_item_artifact.sh" \
  --expected-version "$expected_version" \
  --operation-id "$operation_id" \
  "$work_item_id" \
  "$artifact_path" \
  "$artifact_type" \
  "$new_status" >/dev/null

printf '%s\n' "$artifact_path"
