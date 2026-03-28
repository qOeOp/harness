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
  echo "usage: $0 --expected-version <version> [--operation-id <id>] <work-item-id> <field> <value> [<field> <value> ...]" >&2
  exit 1
}

is_iso_date_or_none() {
  value="$1"
  case "$value" in
    none|????-??-??) return 0 ;;
    *) return 1 ;;
  esac
}

validate_work_item_reference_list() {
  current_id="$1"
  field_label="$2"
  value="$3"

  if value_is_missing "$value"; then
    return 0
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $value
  IFS=$old_ifs

  for raw_id in "$@"; do
    ref_id=$(trim "$raw_id")
    [ -n "$ref_id" ] || continue

    if [ "$ref_id" = "$current_id" ]; then
      echo "$field_label cannot reference self: $ref_id" >&2
      exit 1
    fi

    if [ ! -f "$(work_item_path "$ref_id")" ]; then
      echo "unknown work item in $field_label: $ref_id" >&2
      exit 1
    fi
  done
}

validate_field_update() {
  work_item_id="$1"
  field="$2"
  value="$3"

  case "$field" in
    Title|Owner|Sponsor|Objective|Ready\ criteria|Done\ criteria|Why\ it\ matters|Decision\ needed|Required\ artifacts|Current\ blocker|Next\ handoff|Assignee|Worktree|Current\ stage\ owner|Current\ stage\ role|Next\ gate)
      if [ -z "$value" ]; then
        echo "field must not be empty: $field" >&2
        exit 1
      fi
      ;;
    Priority)
      if ! is_valid_priority "$value"; then
        echo "invalid Priority: $value" >&2
        exit 1
      fi
      ;;
    Deadline|Due\ review\ at)
      if ! is_iso_date_or_none "$value"; then
        echo "invalid $field (expected YYYY-MM-DD or none): $value" >&2
        exit 1
      fi
      ;;
    Founder\ escalation)
      if ! is_valid_founder_escalation "$value"; then
        echo "invalid Founder escalation: $value" >&2
        exit 1
      fi
      ;;
    Claimed\ at|Claim\ expires\ at|Archived\ at)
      if ! is_iso_timestamp_or_none "$value"; then
        echo "invalid $field (expected ISO timestamp or none): $value" >&2
        exit 1
      fi
      ;;
    Lease\ version)
      if ! is_nonnegative_integer "$value"; then
        echo "invalid Lease version: $value" >&2
        exit 1
      fi
      ;;
    Decision\ status|Review\ status|QA\ status|UAT\ status|Acceptance\ status)
      if ! is_valid_gate_status "$value"; then
        echo "invalid $field: $value" >&2
        exit 1
      fi
      ;;
    Blocked\ by|Blocks)
      validate_work_item_reference_list "$work_item_id" "$field" "$value"
      ;;
    *)
      echo "field is not mutable via update_work_item_fields.sh: $field" >&2
      exit 1
      ;;
  esac
}

field_value_after_updates() {
  work_item_file="$1"
  pair_file="$2"
  target_field="$3"

  while IFS=$(printf '\t') read -r field value; do
    if [ "$field" = "$target_field" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  done <"$pair_file"

  field_value "$work_item_file" "$target_field"
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
if [ -z "$work_item_id" ]; then
  usage
fi
shift

if [ -z "$expected_version" ] || [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
  usage
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

acquire_work_item_lock "$work_item_id"
work_item_file=$(require_work_item_for_write "$work_item_id")
current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
last_operation_id=$(field_value "$work_item_file" "Last operation ID")
last_transition_event=$(field_value "$work_item_file" "Last transition event")

if ! is_nonnegative_integer "$current_version"; then
  echo "invalid current state version in $work_item_file: $current_version" >&2
  exit 1
fi

if [ "$expected_version" != "$current_version" ]; then
  echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
  exit 1
fi

pair_file=$(mktemp)
trap 'rm -f "$pair_file"' EXIT HUP INT TERM

requested_fields=""
changed_fields=""

while [ "$#" -gt 0 ]; do
  field="$1"
  value="$2"
  shift 2

  case ",$requested_fields," in
    *,"$field",*)
      echo "duplicate field update requested: $field" >&2
      exit 1
      ;;
  esac

  validate_field_update "$work_item_id" "$field" "$value"

  printf '%s\t%s\n' "$field" "$value" >>"$pair_file"
  requested_fields="${requested_fields}${field},"

  current_value=$(field_value "$work_item_file" "$field")
  if [ "$current_value" != "$value" ]; then
    if [ -z "$changed_fields" ]; then
      changed_fields="$field"
    else
      changed_fields="${changed_fields},$field"
    fi
  fi
done

if [ -n "$operation_id" ] && [ "$last_operation_id" = "$operation_id" ] && [ -f "$last_transition_event" ]; then
  while IFS=$(printf '\t') read -r field value; do
    if [ "$(field_value "$work_item_file" "$field")" != "$value" ]; then
      echo "operation id already used for a different field mutation: $operation_id" >&2
      exit 1
    fi
  done <"$pair_file"

  echo "$work_item_file"
  exit 0
fi

if [ -z "$changed_fields" ]; then
  echo "$work_item_file"
  exit 0
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$work_item_id" "update-fields")
fi

next_version=$((current_version + 1))
next_current_blocker=$(field_value_after_updates "$work_item_file" "$pair_file" "Current blocker")
next_handoff=$(field_value_after_updates "$work_item_file" "$pair_file" "Next handoff")
next_interrupt_marker=$(field_value_after_updates "$work_item_file" "$pair_file" "Interrupt marker")
next_resume_target=$(field_value_after_updates "$work_item_file" "$pair_file" "Resume target")

event_path=$(write_transition_event \
  "$work_item_id" \
  "$current_status" \
  "$current_status" \
  "$actor" \
  "work item fields updated: $changed_fields" \
  "$next_current_blocker" \
  "$next_handoff" \
  "$operation_id" \
  "$current_status" \
  "$expected_version" \
  "$current_version" \
  "$next_version" \
  "$next_interrupt_marker" \
  "$next_resume_target" \
  "field-update")
set -- "$work_item_file" \
  "Updated at" "$(date +%F)" \
  "State version" "$next_version" \
  "Last operation ID" "$operation_id" \
  "Last transition event" "$event_path"

while IFS=$(printf '\t') read -r field value; do
  set -- "$@" "$field" "$value"
done <"$pair_file"

rewrite_work_item_header_snapshot "$@"
sync_recovery_snapshot_if_present "$work_item_file"
refresh_boards_if_enabled

echo "$work_item_file"
