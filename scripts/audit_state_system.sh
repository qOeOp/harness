#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

quiet=""
mode=""
ok=1

while [ $# -gt 0 ]; do
  case "$1" in
    --quiet)
      quiet="--quiet"
      ;;
    --mode)
      shift
      if [ $# -eq 0 ]; then
        echo "usage: $0 [--quiet] [--mode core|governance]" >&2
        exit 2
      fi
      case "$1" in
        core|governance)
          mode="$1"
          ;;
        *)
          echo "invalid mode: $1" >&2
          exit 2
          ;;
      esac
      ;;
    *)
      echo "usage: $0 [--quiet] [--mode core|governance]" >&2
      exit 2
      ;;
  esac
  shift
done

if [ -z "$mode" ]; then
  runtime_mode=$(runtime_manifest_value "runtime_mode" || printf '%s\n' "")
  advanced_governance_enabled=$(runtime_manifest_value "advanced_governance_enabled" || printf '%s\n' "")
  if [ "$runtime_mode" = "advanced-governance" ] || [ "$advanced_governance_enabled" = "true" ]; then
    mode="governance"
  else
    mode="core"
  fi
fi

if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
  echo "audit_state_system.sh checks a consumer runtime workspace, not the framework source repo." >&2
  exit 2
fi

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

require_dir "$task_runtime_dir"
require_file "$runtime_manifest_path"

manifest_schema_version=$(runtime_manifest_value "schema_version" || true)
manifest_runtime_mode=$(runtime_manifest_value "runtime_mode" || true)
manifest_governance=$(runtime_manifest_value "advanced_governance_enabled" || true)
manifest_created_at=$(runtime_manifest_value "created_at" || true)
manifest_updated_at=$(runtime_manifest_value "updated_at" || true)

for pair in \
  "schema_version:$manifest_schema_version" \
  "runtime_mode:$manifest_runtime_mode" \
  "advanced_governance_enabled:$manifest_governance" \
  "created_at:$manifest_created_at" \
  "updated_at:$manifest_updated_at"
do
  label=${pair%%:*}
  value=${pair#*:}
  if [ -z "$value" ]; then
    fail "missing manifest field '$label' in $runtime_manifest_path"
  fi
done

if [ "$manifest_schema_version" != "$runtime_manifest_schema_version" ]; then
  fail "invalid manifest schema version '$manifest_schema_version' in $runtime_manifest_path"
fi

case "$manifest_runtime_mode" in
  minimum-core|advanced-governance) ;;
  *)
    fail "invalid runtime mode '$manifest_runtime_mode' in $runtime_manifest_path"
    ;;
esac

case "$manifest_governance" in
  true|false) ;;
  *)
    fail "invalid advanced_governance_enabled value '$manifest_governance' in $runtime_manifest_path"
    ;;
esac

if [ "$mode" = "governance" ]; then
  require_dir "$state_root"
  require_dir "$state_boards_dir"
  require_dir "$state_board_refreshes_dir"
  require_file "$state_boards_dir/company.md"
  require_file "$state_boards_dir/founder.md"
  require_file "$state_board_refreshes_dir/README.md"

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
fi

for event_file in $(list_transition_events); do
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

open_work_item_count=0
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
  assignee=$(field_value_or_none "$file" "Assignee")
  worktree=$(field_value_or_none "$file" "Worktree")
  claimed_at=$(field_value_or_none "$file" "Claimed at")
  claim_expires_at=$(field_value_or_none "$file" "Claim expires at")
  lease_version=$(field_value_or_none "$file" "Lease version")
  objective=$(field_value "$file" "Objective")
  ready_criteria=$(field_value "$file" "Ready criteria")
  done_criteria=$(field_value "$file" "Done criteria")
  required_artifacts=$(field_value "$file" "Required artifacts")
  current_stage_owner=$(field_value_or_none "$file" "Current stage owner")
  current_stage_role=$(field_value_or_none "$file" "Current stage role")
  next_gate=$(field_value_or_none "$file" "Next gate")
  decision_status=$(field_value_or_none "$file" "Decision status")
  review_status=$(field_value_or_none "$file" "Review status")
  qa_status=$(field_value_or_none "$file" "QA status")
  uat_status=$(field_value_or_none "$file" "UAT status")
  acceptance_status=$(field_value_or_none "$file" "Acceptance status")
  why_it_matters=$(field_value "$file" "Why it matters")
  decision_needed=$(field_value "$file" "Decision needed")
  deadline=$(field_value "$file" "Deadline")
  created_at=$(field_value "$file" "Created at")
  updated_at=$(field_value "$file" "Updated at")
  founder_escalation=$(field_value "$file" "Founder escalation")
  linked_artifacts=$(field_value "$file" "Linked attachments")
  last_transition_event=$(field_value "$file" "Last transition event")
  interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")
  resume_target=$(field_value_or_none "$file" "Resume target")
  blocked_by=$(field_value "$file" "Blocked by")
  blocks=$(field_value "$file" "Blocks")
  current_blocker=$(field_value "$file" "Current blocker")
  next_handoff=$(field_value "$file" "Next handoff")
  archived_at=$(field_value_or_none "$file" "Archived at")
  recovery_current_focus=$(recovery_field_value_or_none "$file" "Current focus")
  recovery_next_command=$(recovery_field_value_or_none "$file" "Next command")
  recovery_notes=$(recovery_field_value_or_none "$file" "Recovery notes")

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
    "Assignee:$assignee" \
    "Worktree:$worktree" \
    "Claimed at:$claimed_at" \
    "Claim expires at:$claim_expires_at" \
    "Lease version:$lease_version" \
    "Objective:$objective" \
    "Ready criteria:$ready_criteria" \
    "Done criteria:$done_criteria" \
    "Required artifacts:$required_artifacts" \
    "Current stage owner:$current_stage_owner" \
    "Current stage role:$current_stage_role" \
    "Next gate:$next_gate" \
    "Decision status:$decision_status" \
    "Review status:$review_status" \
    "QA status:$qa_status" \
    "UAT status:$uat_status" \
    "Acceptance status:$acceptance_status" \
    "Why it matters:$why_it_matters" \
    "Decision needed:$decision_needed" \
    "Deadline:$deadline" \
    "Created at:$created_at" \
    "Updated at:$updated_at" \
    "Founder escalation:$founder_escalation" \
    "Linked attachments:$linked_artifacts" \
    "Last transition event:$last_transition_event" \
    "Interrupt marker:$interrupt_marker" \
    "Resume target:$resume_target" \
    "Blocked by:$blocked_by" \
    "Blocks:$blocks" \
    "Current blocker:$current_blocker" \
    "Next handoff:$next_handoff" \
    "Archived at:$archived_at"
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
  file_basename=$(basename "$file" .md)
  if [ "$file_basename" = "task" ]; then
    if [ "$(basename "$(dirname "$file")")" != "$id" ]; then
      fail "id does not match canonical task directory in $file"
    fi
  elif [ "$file_basename" != "$id" ]; then
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
  is_valid_gate_status "$decision_status" || fail "invalid decision status '$decision_status' in $file"
  is_valid_gate_status "$review_status" || fail "invalid review status '$review_status' in $file"
  is_valid_gate_status "$qa_status" || fail "invalid QA status '$qa_status' in $file"
  is_valid_gate_status "$uat_status" || fail "invalid UAT status '$uat_status' in $file"
  is_valid_gate_status "$acceptance_status" || fail "invalid acceptance status '$acceptance_status' in $file"
  is_valid_interrupt_marker "$interrupt_marker" || fail "invalid interrupt marker '$interrupt_marker' in $file"
  is_valid_resume_target "$resume_target" || fail "invalid resume target '$resume_target' in $file"
  if ! is_nonnegative_integer "$lease_version"; then
    fail "invalid lease version '$lease_version' in $file"
  fi
  if ! is_iso_timestamp_or_none "$claimed_at"; then
    fail "invalid claimed-at timestamp '$claimed_at' in $file"
  fi
  if ! is_iso_timestamp_or_none "$claim_expires_at"; then
    fail "invalid claim-expiration timestamp '$claim_expires_at' in $file"
  fi
  if ! is_iso_timestamp_or_none "$archived_at"; then
    fail "invalid archived-at timestamp '$archived_at' in $file"
  fi
  if is_open_work_item_status "$status"; then
    open_work_item_count=$((open_work_item_count + 1))
  fi

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

  case "$status" in
    in-progress|paused)
      if value_is_missing "$assignee"; then
        fail "active item missing Assignee in $file"
      fi
      if value_is_missing "$worktree"; then
        fail "active item missing Worktree in $file"
      fi
      if value_is_missing "$claimed_at"; then
        fail "active item missing Claimed at in $file"
      fi
      if value_is_missing "$claim_expires_at"; then
        fail "active item missing Claim expires at in $file"
      fi
      if [ "$lease_version" -lt 1 ]; then
        fail "active item must have positive Lease version in $file"
      fi
      if value_is_missing "$recovery_current_focus"; then
        fail "active item missing Recovery current focus in $file"
      fi
      if value_is_missing "$recovery_next_command"; then
        fail "active item missing Recovery next command in $file"
      fi
      ;;
    *)
      if ! value_is_missing "$assignee"; then
        fail "non-active item still has Assignee in $file"
      fi
      if ! value_is_missing "$worktree"; then
        fail "non-active item still has Worktree in $file"
      fi
      if ! value_is_missing "$claimed_at"; then
        fail "non-active item still has Claimed at in $file"
      fi
      if ! value_is_missing "$claim_expires_at"; then
        fail "non-active item still has Claim expires at in $file"
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
    archived)
      if value_is_missing "$archived_at"; then
        fail "archived item missing Archived at timestamp in $file"
      fi
      ;;
  esac
done

if [ -f ".harness/current-task" ]; then
  fail "forbidden runtime surface still exists at .harness/current-task"
fi

for event_file in $(list_transition_events); do
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

if [ "$mode" = "governance" ]; then
  if ! "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
    if ! STATE_ACTOR="${STATE_ACTOR:-state-audit}" STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}" "$script_dir/refresh_boards.sh" >/dev/null 2>&1; then
      fail "boards refresh failed"
    elif ! "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
      fail "boards out of sync with work items"
    fi
  fi
fi

if [ "$ok" -eq 1 ]; then
  [ "$quiet" = "--quiet" ] || echo "state system audit: ok"
  exit 0
fi

exit 1
