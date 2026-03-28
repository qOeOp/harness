#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  printf 'usage: %s [--json|--record|--path-only] [shared|founder]\n' "$(default_harness_command "open_work_item.sh")" >&2
}

recommend_action() {
  result="$1"
  status="$2"
  reason="$3"
  interrupt_marker="${4:-none}"

  case "$result" in
    actionable)
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
          printf '%s\n' "complete_work_item_to_done"
          ;;
        ready)
          printf '%s\n' "start_selected_work_item"
          ;;
        in-progress)
          printf '%s\n' "complete_work_item_to_review"
          ;;
        planning|backlog)
          printf '%s\n' "advance_selected_work_item_before_execution"
          ;;
        *)
          printf '%s\n' "open_selected_work_item"
          ;;
      esac
      ;;
    blocked)
      case "$reason" in
        *"awaiting founder decision"*)
          printf '%s\n' "resolve_blockers_or_collect_founder_decision"
          ;;
        *"blocked by "*)
          printf '%s\n' "resolve_blocking_work_items"
          ;;
        *)
          printf '%s\n' "clear_current_blocker_before_opening"
          ;;
      esac
      ;;
    empty)
      printf '%s\n' "no_open_work_item_for_scope"
      ;;
    *)
      printf '%s\n' "inspect_selector_output"
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

record_sanitize() {
  value="${1:-}"
  printf '%s' "$value" | awk '
    BEGIN {
      ORS = ""
      first = 1
    }
    {
      if (!first) {
        printf " "
      }
      first = 0
      gsub(/\037/, " ")
      gsub(/\t/, " ")
      gsub(/\r/, " ")
      printf "%s", $0
    }
  '
}

emit_record() {
  sep=$(printf '\037')
  first=1

  for value in "$@"; do
    sanitized=$(record_sanitize "$value")
    if [ "$first" -eq 1 ]; then
      printf '%s' "$sanitized"
      first=0
    else
      printf '%s%s' "$sep" "$sanitized"
    fi
  done

  printf '\n'
}

output_mode="summary"

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      output_mode="json"
      shift
      ;;
    --record)
      output_mode="record"
      shift
      ;;
    --path-only)
      output_mode="path"
      shift
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

recovery_command_template=$(default_harness_command "upsert_work_item_recovery.sh")
resume_command_template=$(default_harness_command "resume_work_item.sh")

if selector_output=$("$script_dir/select_work_item.sh" --record "$scope" 2>/dev/null); then
  selector_status=0
else
  selector_status=$?
  if [ "$selector_status" -gt 2 ]; then
    exit "$selector_status"
  fi
fi

sep=$(printf '\037')
IFS=$sep read -r selected_scope selected_department board_path result reason selected_id selected_path selected_title selected_status selected_priority selected_owner blocked_id blocked_path blocked_title blocked_status blocked_priority blocked_owner blocked_reason <<EOF
$selector_output
EOF
unset IFS

action=$(recommend_action "$result" "$selected_status" "${blocked_reason:-$reason}" "none")

objective=""
deadline=""
founder_escalation=""
current_blocker=""
next_handoff=""
linked_attachments=""
state_version=""
last_operation_id=""
last_transition_event=""
interrupt_marker="none"
resume_target="none"
resume_command=""
blocked_state_version=""
blocked_interrupt_marker="none"
blocked_resume_target="none"
blocked_resume_command=""
recovery_path=""
recovery_sync_state="none"
recovery_updated_at="none"
recovery_current_focus="none"
recovery_next_command="none"
recovery_notes="none"
recovery_exists=false
recovery_command=""

if [ "$result" = "actionable" ]; then
  if [ ! -f "$selected_path" ]; then
    echo "missing selected work item file: $selected_path" >&2
    exit 1
  fi

  objective=$(field_value "$selected_path" "Objective")
  deadline=$(field_value "$selected_path" "Deadline")
  founder_escalation=$(field_value "$selected_path" "Founder escalation")
  current_blocker=$(field_value "$selected_path" "Current blocker")
  next_handoff=$(field_value "$selected_path" "Next handoff")
  linked_attachments=$(field_value "$selected_path" "Linked attachments")
  state_version=$(field_value "$selected_path" "State version")
  last_operation_id=$(field_value "$selected_path" "Last operation ID")
  last_transition_event=$(field_value "$selected_path" "Last transition event")
  interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
  resume_target=$(field_value_or_none "$selected_path" "Resume target")
  recovery_path=$(work_item_recovery_path "$selected_id")
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
      recovery_command="$recovery_command_template --expected-version $state_version \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
    stale|current)
      recovery_command="$recovery_command_template \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
  esac

  if [ "$selected_status" = "paused" ] && ! value_is_missing "$interrupt_marker"; then
    resume_command="$resume_command_template --expected-version $state_version \"$selected_id\" \"[next-handoff]\" \"[reason]\""
    interrupt_action=$(interrupt_recommended_action "$interrupt_marker")
    if [ -n "$interrupt_action" ]; then
      action="$interrupt_action"
    fi
  else
    recovery_action=$(recovery_recommended_action "$selected_status" "$recovery_sync_state")
    if [ -n "$recovery_action" ]; then
      action="$recovery_action"
    fi
  fi
elif [ "$result" = "blocked" ] && [ -n "$blocked_path" ] && [ -f "$blocked_path" ]; then
  blocked_state_version=$(field_value "$blocked_path" "State version")
  blocked_interrupt_marker=$(field_value_or_none "$blocked_path" "Interrupt marker")
  blocked_resume_target=$(field_value_or_none "$blocked_path" "Resume target")

  if [ "$blocked_status" = "paused" ] && ! value_is_missing "$blocked_interrupt_marker"; then
    blocked_resume_command="$resume_command_template --expected-version $blocked_state_version \"$blocked_id\" \"[next-handoff]\" \"[reason]\""
    interrupt_action=$(interrupt_recommended_action "$blocked_interrupt_marker")
    if [ -n "$interrupt_action" ]; then
      action="$interrupt_action"
    else
      action="inspect_paused_work_item_and_resume"
    fi
  else
    action=$(recommend_action "$result" "$blocked_status" "$blocked_reason" "$blocked_interrupt_marker")
  fi
fi

emit_json() {
  if [ "$result" = "actionable" ]; then
    selected_json=$(cat <<EOF
{
  "id": $(json_escape "$selected_id"),
  "path": $(json_escape "$selected_path"),
  "title": $(json_escape "$selected_title"),
  "status": $(json_escape "$selected_status"),
  "priority": $(json_escape "$selected_priority"),
  "owner": $(json_escape "$selected_owner"),
  "objective": $(json_escape "$objective"),
  "deadline": $(json_escape "$deadline"),
  "founder_escalation": $(json_escape "$founder_escalation"),
  "current_blocker": $(json_escape "$current_blocker"),
  "next_handoff": $(json_escape "$next_handoff"),
  "linked_attachments": $(json_escape "$linked_attachments"),
  "state_version": $(json_escape "$state_version"),
  "last_operation_id": $(json_escape "$last_operation_id"),
  "last_transition_event": $(json_escape "$last_transition_event"),
  "interrupt_marker": $(json_escape "$interrupt_marker"),
  "resume_target": $(json_escape "$resume_target"),
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
  "recommended_action": $(json_escape "$action"),
  "selector_reason": $(json_escape "$reason"),
  "selected_work_item": $selected_json,
  "next_blocked_candidate": $blocked_json
}
EOF
}

emit_record_result() {
  emit_record \
    "$selected_scope" \
    "$selected_department" \
    "$board_path" \
    "$result" \
    "$action" \
    "$reason" \
    "$selected_id" \
    "$selected_path" \
    "$selected_title" \
    "$selected_status" \
    "$selected_priority" \
    "$selected_owner" \
    "$objective" \
    "$deadline" \
    "$founder_escalation" \
    "$current_blocker" \
    "$next_handoff" \
    "$linked_attachments" \
    "$interrupt_marker" \
    "$resume_target" \
    "$resume_command" \
    "$blocked_id" \
    "$blocked_path" \
    "$blocked_title" \
    "$blocked_status" \
    "$blocked_priority" \
    "$blocked_owner" \
    "$blocked_reason" \
    "$blocked_state_version" \
    "$blocked_interrupt_marker" \
    "$blocked_resume_target" \
    "$blocked_resume_command"
}

case "$output_mode" in
  path)
    if [ "$result" = "actionable" ]; then
      printf '%s\n' "$selected_path"
      exit 0
    fi
    exit 2
    ;;
  json)
    emit_json
    if [ "$result" = "actionable" ]; then
      exit 0
    fi
    exit 2
    ;;
  record)
    emit_record_result
    if [ "$result" = "actionable" ]; then
      exit 0
    fi
    exit 2
    ;;
esac

printf 'Scope: %s\n' "$selected_scope"
printf 'Board: %s\n' "$board_path"
printf 'Result: %s\n' "$result"
printf 'Recommended action: %s\n' "$action"

if [ "$result" = "actionable" ]; then
  printf 'Open file: %s\n' "$selected_path"
  printf 'Work item: %s: %s\n' "$selected_id" "$selected_title"
  printf 'Status: %s\n' "$selected_status"
  printf 'Priority: %s\n' "$selected_priority"
  printf 'Owner: %s\n' "$selected_owner"
  printf 'Objective: %s\n' "$objective"
  printf 'Deadline: %s\n' "$deadline"
  printf 'Founder escalation: %s\n' "$founder_escalation"
  printf 'Current blocker: %s\n' "$current_blocker"
  printf 'Next handoff: %s\n' "$next_handoff"
  printf 'Linked attachments: %s\n' "$linked_attachments"
  printf 'State version: %s\n' "$state_version"
  printf 'Last operation ID: %s\n' "$last_operation_id"
  printf 'Last transition event: %s\n' "$last_transition_event"
  printf 'Interrupt marker: %s\n' "$interrupt_marker"
  printf 'Resume target: %s\n' "$resume_target"
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
  exit 0
fi

if [ "$result" = "blocked" ]; then
  printf 'Selected work item: none\n'
  printf 'Selector reason: %s\n' "$reason"
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
  exit 2
fi

printf 'Selected work item: none\n'
printf 'Selector reason: %s\n' "$reason"
exit 2
