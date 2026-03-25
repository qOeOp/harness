#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

actor="${STATE_ACTOR:-}"
require_explicit_state_actor "$actor" "$0"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"
selection="${1:-all}"

insert_interrupt_fields() {
  file="$1"
  tmp=$(mktemp)
  awk '
    BEGIN {
      inserted = 0
    }
    {
      print
      if ($0 ~ /^- Last transition event: /) {
        print "- Interrupt marker: none"
        print "- Resume target: none"
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        exit 2
      }
    }
  ' "$file" >"$tmp" || {
    rc=$?
    rm -f "$tmp"
    return "$rc"
  }
  mv "$tmp" "$file"
}

process_work_item() {
  work_item_file="$1"
  work_item_id=$(field_value "$work_item_file" "ID")
  current_status=$(field_value "$work_item_file" "Status")
  current_version=$(field_value "$work_item_file" "State version")
  interrupt_marker=$(field_value_or_none "$work_item_file" "Interrupt marker")
  resume_target=$(field_value_or_none "$work_item_file" "Resume target")

  if ! value_is_missing "$interrupt_marker" || ! value_is_missing "$resume_target"; then
    return 0
  fi

  operation_id=$(default_operation_id "$work_item_id" "backfill-interrupt-fields")
  next_version=$((current_version + 1))

  insert_interrupt_fields "$work_item_file"
  replace_field "$work_item_file" "Updated at" "$(date +%F)"
  replace_field "$work_item_file" "State version" "$next_version"
  replace_field "$work_item_file" "Last operation ID" "$operation_id"
  event_path=$(write_transition_event \
    "$work_item_id" \
    "$current_status" \
    "$current_status" \
    "$actor" \
    "interrupt marker fields backfilled" \
    "$(field_value "$work_item_file" "Current blocker")" \
    "$(field_value "$work_item_file" "Next handoff")" \
    "$operation_id" \
    "$current_status" \
    "$current_version" \
    "$current_version" \
    "$next_version" \
    "none" \
    "none" \
    "schema-migration")
  replace_field "$work_item_file" "Last transition event" "$event_path"
  sync_progress_snapshot_if_present "$work_item_file"
}

case "$selection" in
  all)
    for work_item_file in $(list_work_items); do
      process_work_item "$work_item_file"
    done
    ;;
  WI-*)
    process_work_item "$(require_work_item "$selection")"
    ;;
  *)
    echo "usage: $0 [all|WI-xxxx]" >&2
    exit 1
    ;;
esac

"$script_dir/refresh_boards.sh" >/dev/null
echo "interrupt fields: ok"
