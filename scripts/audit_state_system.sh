#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

quiet="${1:-}"
ok=1

fail() {
  ok=0
  [ "$quiet" = "--quiet" ] || echo "$1"
}

require_dir() {
  if [ ! -d "$1" ]; then
    fail "missing directory: $1"
  fi
}

require_file() {
  if [ ! -f "$1" ]; then
    fail "missing file: $1"
  fi
}

require_dir "$state_root"
require_dir "$state_items_dir"
require_dir "$state_boards_dir"
require_dir "$state_board_refreshes_dir"
require_dir "$state_progress_dir"
require_dir "$state_transitions_dir"
require_file "$state_boards_dir/company.md"
require_file "$state_boards_dir/founder.md"
require_file "$state_board_refreshes_dir/README.md"
require_file "$state_progress_dir/README.md"

for department in $(list_departments); do
  require_file ".harness/workspace/departments/$department/workspace/board.md"
done

for board_refresh_file in $(list_board_refresh_events); do
  board_refresh_at=$(field_value "$board_refresh_file" "At")
  board_refresh_actor=$(field_value "$board_refresh_file" "Actor")
  board_refresh_invoker=$(field_value "$board_refresh_file" "Invoker")
  board_refresh_targets=$(field_value "$board_refresh_file" "Targets")
  board_refresh_prev=$(field_value "$board_refresh_file" "Prev event")
  board_refresh_prev_hash=$(field_value "$board_refresh_file" "Prev event hash")
  board_refresh_hash=$(field_value "$board_refresh_file" "Event hash")

  for pair in \
    "At:$board_refresh_at" \
    "Actor:$board_refresh_actor" \
    "Invoker:$board_refresh_invoker" \
    "Targets:$board_refresh_targets" \
    "Prev event:$board_refresh_prev" \
    "Prev event hash:$board_refresh_prev_hash" \
    "Event hash:$board_refresh_hash"
  do
    label=${pair%%:*}
    value=${pair#*:}
    if [ -z "$value" ]; then
      fail "missing board refresh field '$label' in $board_refresh_file"
    fi
  done

  if value_is_missing "$board_refresh_actor" || [ "$board_refresh_actor" = "system" ]; then
    fail "invalid board refresh actor '$board_refresh_actor' in $board_refresh_file"
  fi

  expected_board_refresh_hash=$(board_refresh_event_hash "$board_refresh_file")
  if [ "$board_refresh_hash" != "$expected_board_refresh_hash" ]; then
    fail "board refresh event hash mismatch in $board_refresh_file"
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $board_refresh_targets
  IFS=$old_ifs

  for raw_target in "$@"; do
    board_target=$(trim "$raw_target")
    [ -n "$board_target" ] || continue

    if ! is_valid_board_refresh_target "$board_target"; then
      fail "invalid board refresh target '$board_target' in $board_refresh_file"
      continue
    fi

    if [ ! -f "$board_target" ]; then
      fail "missing board refresh target '$board_target' in $board_refresh_file"
    fi
  done

  if [ "$board_refresh_prev" != "none" ]; then
    if [ ! -f "$board_refresh_prev" ]; then
      fail "missing previous board refresh event '$board_refresh_prev' in $board_refresh_file"
    elif [ "$(field_value "$board_refresh_prev" "Event hash")" != "$board_refresh_prev_hash" ]; then
      fail "previous board refresh event hash mismatch in $board_refresh_file"
    fi
  elif [ "$board_refresh_prev_hash" != "none" ]; then
    fail "board refresh prev event hash must be none when prev event is none in $board_refresh_file"
  fi
done

for progress_file in $(find "$state_progress_dir" -maxdepth 1 -type f -name 'WI-*.md' | sort); do
  progress_work_item=$(field_value "$progress_file" "Work Item")
  progress_updated_at=$(field_value "$progress_file" "Updated at")
  progress_status_snapshot=$(field_value "$progress_file" "Status snapshot")
  progress_state_version_snapshot=$(field_value "$progress_file" "State version snapshot")
  progress_operation_snapshot=$(field_value "$progress_file" "Last operation ID snapshot")
  progress_current_focus=$(field_value "$progress_file" "Current focus")
  progress_next_command=$(field_value "$progress_file" "Next command")
  progress_recovery_notes=$(field_value "$progress_file" "Recovery notes")

  for pair in \
    "Work Item:$progress_work_item" \
    "Updated at:$progress_updated_at" \
    "Status snapshot:$progress_status_snapshot" \
    "State version snapshot:$progress_state_version_snapshot" \
    "Last operation ID snapshot:$progress_operation_snapshot" \
    "Current focus:$progress_current_focus" \
    "Next command:$progress_next_command" \
    "Recovery notes:$progress_recovery_notes"
  do
    label=${pair%%:*}
    value=${pair#*:}
    if [ -z "$value" ]; then
      fail "missing progress field '$label' in $progress_file"
    fi
  done

  if [ ! -f "$(work_item_path "$progress_work_item")" ]; then
    fail "progress file points to missing work item '$progress_work_item' in $progress_file"
  fi

  if ! artifact_has_work_item_link "$progress_file" "$progress_work_item"; then
    fail "progress file '$progress_file' does not link back to $progress_work_item"
  fi

  if ! is_valid_work_item_status "$progress_status_snapshot"; then
    fail "invalid progress status snapshot '$progress_status_snapshot' in $progress_file"
  fi

  if ! is_nonnegative_integer "$progress_state_version_snapshot"; then
    fail "invalid progress state version snapshot '$progress_state_version_snapshot' in $progress_file"
  fi

  current_progress_version=$(field_value "$(work_item_path "$progress_work_item")" "State version")
  if is_nonnegative_integer "$current_progress_version" && [ "$progress_state_version_snapshot" -gt "$current_progress_version" ]; then
    fail "progress snapshot version is ahead of work item in $progress_file"
  fi
done

for event_file in $(find "$state_transitions_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort); do
  event_work_item=$(field_value "$event_file" "Work Item")
  event_from=$(field_value "$event_file" "From")
  event_prev=$(field_value "$event_file" "Prev event")
  event_prev_hash=$(field_value "$event_file" "Prev event hash")
  event_hash=$(field_value "$event_file" "Event hash")
  event_to=$(field_value "$event_file" "To")
  event_operation_id=$(field_value_or_none "$event_file" "Operation ID")
  event_type=$(field_value_or_none "$event_file" "Event type")
  event_interrupt_marker=$(field_value_or_none "$event_file" "Interrupt marker")
  event_resume_target=$(field_value_or_none "$event_file" "Resume target")

  for pair in \
    "Work Item:$event_work_item" \
    "Prev event:$event_prev" \
    "Prev event hash:$event_prev_hash" \
    "Event hash:$event_hash"
  do
    label=${pair%%:*}
    value=${pair#*:}
    if [ -z "$value" ]; then
      fail "missing transition field '$label' in $event_file"
    fi
  done

  expected_hash=$(transition_event_hash "$event_file")
  if [ "$event_hash" != "$expected_hash" ]; then
    fail "event hash mismatch in $event_file"
  fi

  if [ "$event_prev" != "none" ]; then
    if [ ! -f "$event_prev" ]; then
      fail "missing previous event '$event_prev' in $event_file"
    else
      prev_work_item=$(field_value "$event_prev" "Work Item")
      prev_event_hash=$(field_value "$event_prev" "Event hash")
      if [ "$prev_work_item" != "$event_work_item" ]; then
        fail "previous event work item mismatch in $event_file"
      fi
      if [ "$prev_event_hash" != "$event_prev_hash" ]; then
        fail "previous event hash mismatch in $event_file"
      fi
    fi
  else
    if [ "$event_prev_hash" != "none" ]; then
      fail "prev event hash must be none when prev event is none in $event_file"
    fi
  fi

  if ! is_valid_interrupt_marker "$event_interrupt_marker"; then
    fail "invalid interrupt marker '$event_interrupt_marker' in $event_file"
  fi

  if ! is_valid_resume_target "$event_resume_target"; then
    fail "invalid resume target '$event_resume_target' in $event_file"
  fi

  if ! value_is_missing "$event_type"; then
    if ! is_valid_trace_event_type "$event_type"; then
      fail "invalid event type '$event_type' in $event_file"
    fi

    if value_is_missing "$event_operation_id"; then
      fail "typed event missing operation id in $event_file"
    fi

    case "$event_type" in
      approval-pause)
        if [ "$event_to" != "paused" ]; then
          fail "approval-pause event must transition to paused in $event_file"
        fi
        ;;
      resume)
        if [ "$event_from" != "paused" ] || [ "$event_to" = "paused" ] || [ "$event_to" = "killed" ]; then
          fail "resume event must leave paused for a non-paused, non-killed status in $event_file"
        fi
        ;;
      artifact-link|field-update|terminal-cleanup|schema-migration|blocker-release|board-refresh)
        if [ "$event_from" != "$event_to" ]; then
          fail "$event_type event must keep From and To equal in $event_file"
        fi
        ;;
    esac
  fi

  if [ "$event_to" = "paused" ]; then
    if value_is_missing "$event_interrupt_marker"; then
      fail "paused event missing interrupt marker in $event_file"
    fi
    if value_is_missing "$event_resume_target"; then
      fail "paused event missing resume target in $event_file"
    fi
  elif [ "$event_interrupt_marker" != "none" ] || [ "$event_resume_target" != "none" ]; then
    fail "non-paused event must clear interrupt metadata in $event_file"
  fi
done

for file in $(list_work_items); do
  schema_version=$(field_value "$file" "Schema version")
  state_authority=$(field_value "$file" "State authority")
  state_version=$(field_value "$file" "State version")
  last_operation_id=$(field_value "$file" "Last operation ID")
  id=$(field_value "$file" "ID")
  title=$(field_value "$file" "Title")
  type=$(field_value "$file" "Type")
  status=$(field_value "$file" "Status")
  priority=$(field_value "$file" "Priority")
  owner=$(field_value "$file" "Owner")
  sponsor=$(field_value "$file" "Sponsor")
  objective=$(field_value "$file" "Objective")
  ready_criteria=$(field_value "$file" "Ready criteria")
  done_criteria=$(field_value "$file" "Done criteria")
  required_artifacts=$(field_value "$file" "Required artifacts")
  why_it_matters=$(field_value "$file" "Why it matters")
  decision_needed=$(field_value "$file" "Decision needed")
  deadline=$(field_value "$file" "Deadline")
  created_at=$(field_value "$file" "Created at")
  updated_at=$(field_value "$file" "Updated at")
  founder_escalation=$(field_value "$file" "Founder escalation")
  required_departments=$(field_value "$file" "Required departments")
  participation_records=$(field_value "$file" "Participation records")
  linked_artifacts=$(field_value "$file" "Linked artifacts")
  last_transition_event=$(field_value "$file" "Last transition event")
  interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")
  resume_target=$(field_value_or_none "$file" "Resume target")
  blocked_by=$(field_value "$file" "Blocked by")
  blocks=$(field_value "$file" "Blocks")
  current_blocker=$(field_value "$file" "Current blocker")
  next_handoff=$(field_value "$file" "Next handoff")

  for pair in \
    "Schema version:$schema_version" \
    "State authority:$state_authority" \
    "State version:$state_version" \
    "Last operation ID:$last_operation_id" \
    "ID:$id" \
    "Title:$title" \
    "Type:$type" \
    "Status:$status" \
    "Priority:$priority" \
    "Owner:$owner" \
    "Sponsor:$sponsor" \
    "Objective:$objective" \
    "Ready criteria:$ready_criteria" \
    "Done criteria:$done_criteria" \
    "Required artifacts:$required_artifacts" \
    "Why it matters:$why_it_matters" \
    "Decision needed:$decision_needed" \
    "Deadline:$deadline" \
    "Created at:$created_at" \
    "Updated at:$updated_at" \
    "Founder escalation:$founder_escalation" \
    "Required departments:$required_departments" \
    "Participation records:$participation_records" \
    "Linked artifacts:$linked_artifacts" \
    "Last transition event:$last_transition_event" \
    "Interrupt marker:$interrupt_marker" \
    "Resume target:$resume_target" \
    "Blocked by:$blocked_by" \
    "Blocks:$blocks" \
    "Current blocker:$current_blocker" \
    "Next handoff:$next_handoff"
  do
    label=${pair%%:*}
    value=${pair#*:}
    if [ -z "$value" ]; then
      fail "missing field '$label' in $file"
    fi
  done

  if ! work_item_header_schema_matches "$file"; then
    fail "work item header schema mismatch in $file"
  fi
  if [ "$(basename "$file" .md)" != "$id" ]; then
    fail "id does not match filename in $file"
  fi
  if [ "$schema_version" != "$work_item_schema_version" ]; then
    fail "invalid schema version '$schema_version' in $file"
  fi
  if [ "$state_authority" != "$work_item_state_authority" ]; then
    fail "invalid state authority '$state_authority' in $file"
  fi
  if ! is_nonnegative_integer "$state_version" || [ "$state_version" -lt 1 ]; then
    fail "invalid state version '$state_version' in $file"
  fi
  is_valid_type "$type" || fail "invalid type '$type' in $file"
  is_valid_work_item_status "$status" || fail "invalid status '$status' in $file"
  is_valid_priority "$priority" || fail "invalid priority '$priority' in $file"
  is_valid_founder_escalation "$founder_escalation" || fail "invalid founder escalation '$founder_escalation' in $file"
  is_valid_interrupt_marker "$interrupt_marker" || fail "invalid interrupt marker '$interrupt_marker' in $file"
  is_valid_resume_target "$resume_target" || fail "invalid resume target '$resume_target' in $file"

  if ! work_item_has_transition_events "$id"; then
    fail "missing transition events for $file"
  fi
  if [ ! -f "$last_transition_event" ]; then
    fail "missing last transition event file '$last_transition_event' for $file"
  else
    last_transition_to=$(field_value "$last_transition_event" "To")
    last_transition_item=$(field_value "$last_transition_event" "Work Item")
    latest_transition_event=$(latest_transition_event_path "$id")
    last_transition_hash=$(field_value "$last_transition_event" "Event hash")
    computed_last_transition_hash=$(transition_event_hash "$last_transition_event")
    last_transition_operation_id=$(field_value "$last_transition_event" "Operation ID")
    last_transition_version_after=$(field_value "$last_transition_event" "Version after")
    last_transition_interrupt_marker=$(field_value_or_none "$last_transition_event" "Interrupt marker")
    last_transition_resume_target=$(field_value_or_none "$last_transition_event" "Resume target")
    if [ "$last_transition_to" != "$status" ]; then
      fail "last transition event does not match current status in $file"
    fi
    if [ "$last_transition_item" != "$id" ]; then
      fail "last transition event points to wrong work item in $file"
    fi
    if [ "$latest_transition_event" != "$last_transition_event" ]; then
      fail "last transition event is not the latest event in $file"
    fi
    if [ "$computed_last_transition_hash" != "$last_transition_hash" ]; then
      fail "last transition event hash mismatch in $file"
    fi
    if ! value_is_missing "$last_transition_operation_id" && [ "$last_transition_operation_id" != "$last_operation_id" ]; then
      fail "last operation id does not match last transition event in $file"
    fi
    if ! value_is_missing "$last_transition_version_after" && [ "$last_transition_version_after" != "$state_version" ]; then
      fail "state version does not match last transition version in $file"
    fi
    if [ "$last_transition_interrupt_marker" != "$interrupt_marker" ]; then
      fail "interrupt marker does not match last transition event in $file"
    fi
    if [ "$last_transition_resume_target" != "$resume_target" ]; then
      fail "resume target does not match last transition event in $file"
    fi
  fi

  if [ "$required_departments" != "none" ]; then
    old_ifs=${IFS- }
    IFS=','
    set -- $required_departments
    IFS=$old_ifs
    for raw_department in "$@"; do
      department=$(printf '%s\n' "$raw_department" | sed 's/^ *//; s/ *$//')
      [ -n "$department" ] || continue
      if [ ! -d ".harness/workspace/departments/$department" ]; then
        fail "unknown required department '$department' in $file"
      fi
    done
  fi

  if [ "$participation_records" != "none" ]; then
    old_ifs=${IFS- }
    IFS=','
    set -- $participation_records
    IFS=$old_ifs
    for record in "$@"; do
      department=${record%%=*}
      participation=${record#*=}
      department=$(printf '%s\n' "$department" | sed 's/^ *//; s/ *$//')
      participation=$(printf '%s\n' "$participation" | sed 's/^ *//; s/ *$//')
      if [ ! -d ".harness/workspace/departments/$department" ]; then
        fail "unknown participation department '$department' in $file"
      fi
      if ! is_valid_participation "$participation"; then
        fail "invalid participation '$participation' in $file"
      fi
    done
  fi

  if [ "$linked_artifacts" != "none" ]; then
    old_ifs=${IFS- }
    IFS=';'
    set -- $linked_artifacts
    IFS=$old_ifs
    for artifact_entry in "$@"; do
      artifact_entry=$(trim "$artifact_entry")
      [ -n "$artifact_entry" ] || continue
      artifact_path=${artifact_entry%%|*}
      remainder=${artifact_entry#*|}
      artifact_type=${remainder%%|*}
      artifact_status=${artifact_entry##*|}
      artifact_type=$(trim "$artifact_type")
      artifact_status=$(trim "$artifact_status")

      if [ ! -f "$artifact_path" ]; then
        fail "missing linked artifact '$artifact_path' in $file"
      fi
      if [ -z "$artifact_type" ]; then
        fail "missing artifact type in $file"
      fi
      if ! is_valid_artifact_status "$artifact_status"; then
        fail "invalid artifact status '$artifact_status' in $file"
      fi
      if ! artifact_has_work_item_link "$artifact_path" "$id"; then
        fail "artifact '$artifact_path' does not include work item $id"
      fi
    done
  fi

  case "$status" in
    ready|in-progress|review|done)
      if value_is_missing "$objective"; then
        fail "missing Objective for active item $file"
      fi
      if value_is_missing "$ready_criteria"; then
        fail "missing Ready criteria for active item $file"
      fi
      if ! required_departments_satisfied "$file" "ready"; then
        fail "required departments not assigned for active item $file"
      fi
      ;;
  esac

  case "$status" in
    paused)
      if value_is_missing "$interrupt_marker"; then
        fail "paused item missing interrupt marker in $file"
      fi
      if value_is_missing "$resume_target"; then
        fail "paused item missing resume target in $file"
      fi
      ;;
    *)
      if ! value_is_missing "$interrupt_marker"; then
        fail "non-paused item still has interrupt marker in $file"
      fi
      if ! value_is_missing "$resume_target"; then
        fail "non-paused item still has resume target in $file"
      fi
      ;;
  esac

  if [ "$status" = "done" ]; then
    if value_is_missing "$done_criteria"; then
      fail "missing Done criteria for done item $file"
    fi
    if [ "$founder_escalation" = "pending-founder" ]; then
      fail "done item still pending founder escalation in $file"
    fi
    if ! value_is_missing "$required_artifacts" && ! required_artifacts_satisfied "$file"; then
      fail "required artifacts not satisfied for done item $file"
    fi
    if ! required_departments_satisfied "$file" "done"; then
      fail "required departments not done for done item $file"
    fi
    if ! value_is_missing "$current_blocker"; then
      fail "done item still has current blocker in $file"
    fi
  fi

  case "$status" in
    done|killed)
      if ! value_is_missing "$blocked_by"; then
        fail "terminal item still has blocked-by dependencies in $file"
      fi
      if ! value_is_missing "$blocks"; then
        fail "terminal item still blocks downstream items in $file"
      fi
      if ! value_is_missing "$next_handoff"; then
        fail "terminal item still has next handoff in $file"
      fi
      if ! value_is_missing "$interrupt_marker"; then
        fail "terminal item still has interrupt marker in $file"
      fi
      if ! value_is_missing "$resume_target"; then
        fail "terminal item still has resume target in $file"
      fi
      ;;
  esac
done

for event_file in $(find "$state_transitions_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort); do
  event_hash=$(field_value "$event_file" "Event hash")
  computed_event_hash=$(transition_event_hash "$event_file")
  prev_event=$(field_value "$event_file" "Prev event")
  prev_event_hash=$(field_value "$event_file" "Prev event hash")

  if [ "$computed_event_hash" != "$event_hash" ]; then
    fail "transition event hash mismatch in $event_file"
  fi

  if ! value_is_missing "$prev_event"; then
    if [ ! -f "$prev_event" ]; then
      fail "missing previous transition event '$prev_event' for $event_file"
    elif [ "$(field_value "$prev_event" "Event hash")" != "$prev_event_hash" ]; then
      fail "previous transition event hash mismatch in $event_file"
    fi
  fi
done

if ! "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
  if ! STATE_ACTOR="${STATE_ACTOR:-state-audit}" STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}" "$script_dir/refresh_boards.sh" >/dev/null 2>&1; then
    fail "boards refresh failed"
  elif ! "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
    fail "boards out of sync with work items"
  fi
fi

if [ "$ok" -eq 1 ]; then
  [ "$quiet" = "--quiet" ] || echo "state system audit: ok"
  exit 0
fi

exit 1
