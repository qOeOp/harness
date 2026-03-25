#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

ordered_transition_events_for_item() {
  work_item_id="$1"

  for candidate in $(find "$state_transitions_dir" -maxdepth 1 -type f -name "*-$work_item_id-*.md" -print | sort); do
    at=$(field_value "$candidate" "At")
    version_after=$(field_value_or_none "$candidate" "Version after")
    if is_nonnegative_integer "$version_after"; then
      version_key=$(printf '%09d' "$version_after")
    else
      version_key="000000000"
    fi
    printf '%s\t%s\t%s\t%s\n' "$at" "$version_key" "$(basename "$candidate")" "$candidate"
  done | sort | awk -F '\t' '{print $4}'
}

rehash_transition_chain_for_item() {
  work_item_id="$1"
  prev_event="none"
  prev_event_hash="none"

  for current_event in $(ordered_transition_events_for_item "$work_item_id"); do
    replace_field "$current_event" "Prev event" "$prev_event"
    replace_field "$current_event" "Prev event hash" "$prev_event_hash"
    replace_field "$current_event" "Event hash" "$(transition_event_hash "$current_event")"
    prev_event="$current_event"
    prev_event_hash=$(field_value "$current_event" "Event hash")
  done
}

rehash_transition_events() {
  for work_item_file in $(list_work_items); do
    work_item_id=$(field_value "$work_item_file" "ID")
    rehash_transition_chain_for_item "$work_item_id"
  done
}

rehash_board_refresh_events() {
  prev_event="none"
  prev_event_hash="none"

  for current_event in $(find "$state_board_refreshes_dir" -maxdepth 1 -type f -name 'BR-*.md' -print | sort); do
    replace_field "$current_event" "Prev event" "$prev_event"
    replace_field "$current_event" "Prev event hash" "$prev_event_hash"
    replace_field "$current_event" "Event hash" "$(board_refresh_event_hash "$current_event")"
    prev_event="$current_event"
    prev_event_hash=$(field_value "$current_event" "Event hash")
  done
}

rehash_transition_events
rehash_board_refresh_events
