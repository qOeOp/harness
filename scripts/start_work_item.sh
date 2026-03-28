#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  printf 'usage: %s [--json|--path-only] [--reason <text>] [--operation-id <id>] [shared|founder]\n' "$(default_harness_command "start_work_item.sh")" >&2
}

json_escape() {
  value="${1:-}"
  escaped=$(printf '%s' "$value" | awk '
    BEGIN {
      ORS = ""
      first = 1
    }
    {
      if (!first) {
        printf "\\n"
      }
      first = 0
      gsub(/\\/,"\\\\")
      gsub(/"/,"\\\"")
      gsub(/\t/,"\\t")
      gsub(/\r/,"\\r")
      printf "%s", $0
    }
  ')
  printf '"%s"' "$escaped"
}

json_string_or_null() {
  value="${1:-}"
  if [ -n "$value" ]; then
    json_escape "$value"
  else
    printf 'null'
  fi
}

starter_recommendation() {
  result="$1"
  status="$2"
  reason="$3"
  interrupt_marker="${4:-none}"

  case "$result" in
    started)
      printf '%s\n' "open_started_work_item"
      ;;
    active)
      printf '%s\n' "continue_in_progress_work_item"
      ;;
    blocked)
      case "$status" in
        paused)
          interrupt_action=$(interrupt_recommended_action "$interrupt_marker")
          if [ -n "$interrupt_action" ]; then
            printf '%s\n' "$interrupt_action"
          else
            printf '%s\n' "inspect_paused_work_item_and_resume"
          fi
          ;;
        review)
          printf '%s\n' "finish_review_before_starting_new_work_item"
          ;;
        planning|backlog)
          printf '%s\n' "advance_item_to_ready_before_start"
          ;;
        *)
          case "$reason" in
            *"blocked by "*)
              printf '%s\n' "resolve_blocking_work_items"
              ;;
            *"awaiting founder decision"*)
              printf '%s\n' "collect_founder_decision_before_start"
              ;;
            *)
              printf '%s\n' "inspect_open_work_item_output"
              ;;
          esac
          ;;
      esac
      ;;
    empty)
      printf '%s\n' "no_open_work_item_for_scope"
      ;;
    *)
      printf '%s\n' "inspect_open_work_item_output"
      ;;
  esac
}

recovery_recommended_action() {
  status="$1"
  recovery_sync_state="$2"

  case "$status:$recovery_sync_state" in
    in-progress:missing)
      printf '%s\n' "create_recovery_snapshot_before_continuing"
      ;;
    in-progress:unlinked|in-progress:stale)
      printf '%s\n' "refresh_recovery_snapshot_before_continuing"
      ;;
    in-progress:current)
      printf '%s\n' "continue_work_item_with_recovery_snapshot"
      ;;
    *)
      printf '%s\n' ""
      ;;
  esac
}

emit_json() {
  if [ -n "$selected_id" ]; then
    selected_json=$(cat <<EOF
{
  "id": $(json_escape "$selected_id"),
  "path": $(json_escape "$selected_path"),
  "title": $(json_escape "$selected_title"),
  "status": $(json_escape "$selected_status"),
  "priority": $(json_escape "$selected_priority"),
  "owner": $(json_escape "$selected_owner"),
  "objective": $(json_escape "$selected_objective"),
  "deadline": $(json_escape "$selected_deadline"),
  "founder_escalation": $(json_escape "$selected_founder_escalation"),
  "current_blocker": $(json_escape "$selected_current_blocker"),
  "next_handoff": $(json_escape "$selected_next_handoff"),
  "linked_attachments": $(json_escape "$selected_linked_attachments"),
  "state_version": $(json_escape "$selected_state_version"),
  "last_operation_id": $(json_escape "$selected_last_operation_id"),
  "last_transition_event": $(json_escape "$selected_last_transition_event"),
  "interrupt_marker": $(json_escape "$selected_interrupt_marker"),
  "resume_target": $(json_escape "$selected_resume_target"),
  "resume_command": $(json_escape "$resume_command"),
  "recovery_path": $(json_escape "$recovery_path"),
  "recovery_exists": $recovery_exists,
  "recovery_sync_state": $(json_escape "$recovery_sync_state"),
  "recovery_updated_at": $(json_escape "$recovery_updated_at"),
  "recovery_current_focus": $(json_escape "$recovery_current_focus"),
  "recovery_next_command": $(json_escape "$recovery_next_command"),
  "recovery_notes": $(json_escape "$recovery_notes"),
  "recovery_command": $(json_escape "$recovery_command")
}
EOF
)
  else
    selected_json="null"
  fi

  if [ -n "$blocked_id" ]; then
    blocked_json=$(cat <<EOF
{
  "id": $(json_escape "$blocked_id"),
  "path": $(json_escape "$blocked_path"),
  "title": $(json_escape "$blocked_title"),
  "status": $(json_escape "$blocked_status"),
  "priority": $(json_escape "$blocked_priority"),
  "owner": $(json_escape "$blocked_owner"),
  "blocked_because": $(json_escape "$blocked_reason"),
  "state_version": $(json_string_or_null "$blocked_state_version"),
  "interrupt_marker": $(json_escape "$blocked_interrupt_marker"),
  "resume_target": $(json_escape "$blocked_resume_target"),
  "resume_command": $(json_string_or_null "$blocked_resume_command")
}
EOF
)
  else
    blocked_json="null"
  fi

  cat <<EOF
{
  "scope": $(json_escape "$selected_scope"),
  "group": $(json_string_or_null "$selected_department"),
  "workstream": $(json_string_or_null "$selected_department"),
  "board": $(json_escape "$board_path"),
  "result": $(json_escape "$result"),
  "recommended_action": $(json_escape "$recommended_action"),
  "starter_reason": $(json_escape "$starter_reason"),
  "selector_reason": $(json_escape "$selector_reason"),
  "transition_performed": $transition_performed,
  "operation_id": $(json_string_or_null "$operation_id"),
  "transition_event": $(json_string_or_null "$transition_event"),
  "selected_work_item": $selected_json,
  "next_blocked_candidate": $blocked_json
}
EOF
}

output_mode="summary"
start_reason=""
operation_id=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      output_mode="json"
      shift
      ;;
    --path-only)
      output_mode="path"
      shift
      ;;
    --reason)
      [ $# -ge 2 ] || usage
      start_reason="$2"
      shift 2
      ;;
    --operation-id)
      [ $# -ge 2 ] || usage
      operation_id="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

scope=$(normalize_work_item_scope "${1:-shared}") || { usage; exit 1; }
if [ $# -gt 0 ]; then
  shift
fi

if [ -z "$start_reason" ]; then
  start_reason="execution started via $(default_harness_command "start_work_item.sh")"
fi

recovery_command_template=$(default_harness_command "upsert_work_item_recovery.sh")

if opener_output=$("$script_dir/open_work_item.sh" --record "$scope" 2>/dev/null); then
  opener_status=0
else
  opener_status=$?
  if [ "$opener_status" -gt 2 ]; then
    exit "$opener_status"
  fi
fi

sep=$(printf '\037')
IFS=$sep read -r selected_scope selected_department board_path opener_result opener_action selector_reason selected_id selected_path selected_title selected_status selected_priority selected_owner selected_objective selected_deadline selected_founder_escalation selected_current_blocker selected_next_handoff selected_linked_attachments selected_interrupt_marker selected_resume_target resume_command blocked_id blocked_path blocked_title blocked_status blocked_priority blocked_owner blocked_reason blocked_state_version blocked_interrupt_marker blocked_resume_target blocked_resume_command <<EOF
$opener_output
EOF
unset IFS

selected_state_version=""
selected_last_operation_id=""
selected_last_transition_event=""
selected_interrupt_marker="${selected_interrupt_marker:-none}"
selected_resume_target="${selected_resume_target:-none}"
blocked_state_version="${blocked_state_version:-}"
blocked_interrupt_marker="${blocked_interrupt_marker:-none}"
blocked_resume_target="${blocked_resume_target:-none}"
blocked_resume_command="${blocked_resume_command:-}"
recovery_path=""
recovery_exists=false
recovery_sync_state="none"
recovery_updated_at="none"
recovery_current_focus="none"
recovery_next_command="none"
recovery_notes="none"
recovery_command=""
transition_event=""
transition_performed=false
starter_reason=""
result=""

if [ "$opener_result" != "actionable" ]; then
  result="$opener_result"
  starter_reason="$selector_reason"
  recommended_action=$(starter_recommendation "$result" "$blocked_status" "$blocked_reason" "$blocked_interrupt_marker")
  case "$output_mode" in
    path)
      exit 2
      ;;
    json)
      emit_json
      exit 2
      ;;
  esac

  printf 'Scope: %s\n' "$selected_scope"
  printf 'Board: %s\n' "$board_path"
  printf 'Result: %s\n' "$result"
  printf 'Recommended action: %s\n' "$recommended_action"
  printf 'Starter reason: %s\n' "$starter_reason"
  if [ "$result" = "blocked" ]; then
    printf 'Next blocked candidate: %s\n' "$blocked_id"
    printf 'Path: %s\n' "$blocked_path"
    printf 'Title: %s\n' "$blocked_title"
    printf 'Status: %s\n' "$blocked_status"
    printf 'Blocked because: %s\n' "$blocked_reason"
    if [ "$blocked_status" = "paused" ]; then
      printf 'Interrupt marker: %s\n' "$blocked_interrupt_marker"
      printf 'Resume target: %s\n' "$blocked_resume_target"
      if [ -n "$blocked_resume_command" ]; then
        printf 'Resume command: %s\n' "$blocked_resume_command"
      fi
    fi
  else
    printf 'Selected work item: none\n'
  fi
  exit 2
fi

if [ ! -f "$selected_path" ]; then
  echo "missing selected work item file: $selected_path" >&2
  exit 1
fi

refresh_recovery_context() {
  recovery_path=$(work_item_recovery_path "$selected_id")
  recovery_exists=false
  recovery_sync_state="none"
  recovery_updated_at="none"
  recovery_current_focus="none"
  recovery_next_command="none"
  recovery_notes="none"
  recovery_command=""

  recovery_sync_state=$(work_item_recovery_sync_state "$selected_id")
  if [ -f "$recovery_path" ]; then
    recovery_exists=true
    recovery_updated_at=$(field_value_or_none "$recovery_path" "Updated at")
    recovery_current_focus=$(recovery_field_value_or_none "$recovery_path" "Current focus")
    recovery_next_command=$(recovery_field_value_or_none "$recovery_path" "Next command")
    recovery_notes=$(recovery_field_value_or_none "$recovery_path" "Recovery notes")
  fi

  case "$recovery_sync_state" in
    missing|unlinked)
      recovery_command="$recovery_command_template --expected-version $selected_state_version \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
    stale|current)
      recovery_command="$recovery_command_template \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
  esac
}

selected_state_version=$(field_value "$selected_path" "State version")
selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
selected_last_transition_event=$(field_value "$selected_path" "Last transition event")

case "$selected_status" in
  ready)
    if [ -z "$operation_id" ]; then
      operation_id=$(default_operation_id "$selected_id" "start")
    fi
    "$script_dir/transition_work_item.sh" \
      --expected-from-status ready \
      --expected-version "$selected_state_version" \
      --operation-id "$operation_id" \
      -- \
      "$selected_id" \
      in-progress \
      "" \
      "" \
      "$start_reason" >/dev/null

    selected_status=$(field_value "$selected_path" "Status")
    selected_state_version=$(field_value "$selected_path" "State version")
    selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
    selected_last_transition_event=$(field_value "$selected_path" "Last transition event")
    selected_objective=$(field_value "$selected_path" "Objective")
    selected_deadline=$(field_value "$selected_path" "Deadline")
    selected_founder_escalation=$(field_value "$selected_path" "Founder escalation")
    selected_current_blocker=$(field_value "$selected_path" "Current blocker")
    selected_next_handoff=$(field_value "$selected_path" "Next handoff")
    selected_linked_attachments=$(field_value "$selected_path" "Linked attachments")
    refresh_recovery_context
    transition_event="$selected_last_transition_event"
    transition_performed=true
    starter_reason="$start_reason"
    result="started"
    ;;
  in-progress)
    refresh_recovery_context
    transition_event="$selected_last_transition_event"
    starter_reason="selected work item is already in-progress"
    result="active"
    if [ -z "$operation_id" ]; then
      operation_id="$selected_last_operation_id"
    fi
    ;;
  paused)
    refresh_recovery_context
    transition_event="$selected_last_transition_event"
    starter_reason="selected work item is paused with interrupt marker $selected_interrupt_marker"
    result="blocked"
    recommended_action=$(starter_recommendation "$result" "$selected_status" "$starter_reason" "$selected_interrupt_marker")
    if [ -z "$operation_id" ]; then
      operation_id="$selected_last_operation_id"
    fi
    ;;
  review)
    result="blocked"
    starter_reason="selected work item is already in review"
    recommended_action=$(starter_recommendation "$result" "$selected_status" "$starter_reason" "$selected_interrupt_marker")
    ;;
  planning|backlog)
    result="blocked"
    starter_reason="selected work item is not ready to start from status $selected_status"
    recommended_action=$(starter_recommendation "$result" "$selected_status" "$starter_reason" "$selected_interrupt_marker")
    ;;
  *)
    result="blocked"
    starter_reason="selected work item cannot be started from status $selected_status"
    recommended_action=$(starter_recommendation "$result" "$selected_status" "$starter_reason" "$selected_interrupt_marker")
    ;;
esac

if [ -z "${recommended_action:-}" ]; then
  recommended_action=$(starter_recommendation "$result" "$selected_status" "$starter_reason" "$selected_interrupt_marker")
fi

recovery_action=$(recovery_recommended_action "$selected_status" "$recovery_sync_state")
if [ "$result" = "started" ] || [ "$result" = "active" ]; then
  if [ -n "$recovery_action" ]; then
    recommended_action="$recovery_action"
  fi
fi

case "$output_mode" in
  path)
    case "$result" in
      started|active)
        printf '%s\n' "$selected_path"
        exit 0
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  json)
    emit_json
    case "$result" in
      started|active) exit 0 ;;
      *) exit 2 ;;
    esac
    ;;
esac

printf 'Scope: %s\n' "$selected_scope"
printf 'Board: %s\n' "$board_path"
printf 'Result: %s\n' "$result"
printf 'Recommended action: %s\n' "$recommended_action"
printf 'Starter reason: %s\n' "$starter_reason"

case "$result" in
  started|active)
    printf 'Open file: %s\n' "$selected_path"
    printf 'Work item: %s: %s\n' "$selected_id" "$selected_title"
    printf 'Status: %s\n' "$selected_status"
    printf 'Priority: %s\n' "$selected_priority"
    printf 'Owner: %s\n' "$selected_owner"
    printf 'Objective: %s\n' "$selected_objective"
    printf 'Deadline: %s\n' "$selected_deadline"
    printf 'Founder escalation: %s\n' "$selected_founder_escalation"
    printf 'Current blocker: %s\n' "$selected_current_blocker"
    printf 'Next handoff: %s\n' "$selected_next_handoff"
    printf 'Linked attachments: %s\n' "$selected_linked_attachments"
    printf 'State version: %s\n' "$selected_state_version"
    printf 'Last operation ID: %s\n' "$selected_last_operation_id"
    printf 'Last transition event: %s\n' "$selected_last_transition_event"
    printf 'Interrupt marker: %s\n' "$selected_interrupt_marker"
    printf 'Resume target: %s\n' "$selected_resume_target"
    printf 'Recovery source: %s\n' "$recovery_path"
    printf 'Recovery sync state: %s\n' "$recovery_sync_state"
    printf 'Recovery updated at: %s\n' "$recovery_updated_at"
    printf 'Recovery current focus: %s\n' "$recovery_current_focus"
    printf 'Recovery next command: %s\n' "$recovery_next_command"
    if [ -n "$resume_command" ]; then
      printf 'Resume command: %s\n' "$resume_command"
    fi
    if [ -n "$recovery_command" ]; then
      printf 'Recovery command: %s\n' "$recovery_command"
    fi
    printf 'Transition performed: %s\n' "$transition_performed"
    exit 0
    ;;
  *)
    printf 'Open file: %s\n' "$selected_path"
    printf 'Work item: %s: %s\n' "$selected_id" "$selected_title"
    printf 'Status: %s\n' "$selected_status"
    printf 'Interrupt marker: %s\n' "$selected_interrupt_marker"
    printf 'Resume target: %s\n' "$selected_resume_target"
    if [ -n "$resume_command" ]; then
      printf 'Resume command: %s\n' "$resume_command"
    fi
    printf 'Path: %s\n' "$selected_path"
    exit 2
    ;;
esac
