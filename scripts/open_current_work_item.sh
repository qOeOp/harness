#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  cat <<'EOF' >&2
usage: ./.agents/skills/harness/scripts/open_current_work_item.sh [--json|--path-only] [company|founder|department <slug>]
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
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
        planning|framing|backlog)
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

progress_recommended_action() {
  status="$1"
  progress_sync_state="$2"

  case "$status:$progress_sync_state" in
    in-progress:missing)
      printf '%s\n' "create_progress_artifact_before_continuing"
      ;;
    in-progress:unlinked|in-progress:stale)
      printf '%s\n' "refresh_progress_artifact_before_continuing"
      ;;
    in-progress:current)
      printf '%s\n' "continue_work_item_with_progress_artifact"
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

output_mode="summary"

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
    --help|-h)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

scope="${1:-company}"
department=""
if [ $# -gt 0 ]; then
  shift
fi

case "$scope" in
  company|founder) ;;
  department)
    department="${1:-}"
    if [ -z "$department" ]; then
      usage
      exit 1
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac

require_command node

if selector_output=$("$script_dir/select_work_item.sh" --json "$scope" ${department:+"$department"} 2>/dev/null); then
  selector_status=0
else
  selector_status=$?
  if [ "$selector_status" -gt 2 ]; then
    exit "$selector_status"
  fi
fi

selector_line=$(printf '%s' "$selector_output" | node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(0, "utf8"));
const selected = data.selected_work_item || {};
const blocked = data.next_blocked_candidate || {};
const values = [
  data.scope || "",
  data.department || "",
  data.board || "",
  data.result || "",
  data.reason || "",
  selected.id || "",
  selected.path || "",
  selected.title || "",
  selected.status || "",
  selected.priority || "",
  selected.owner || "",
  blocked.id || "",
  blocked.path || "",
  blocked.title || "",
  blocked.status || "",
  blocked.priority || "",
  blocked.owner || "",
  blocked.blocked_because || ""
];
const sanitize = (value) => String(value)
  .replace(/\u001f/g, " ")
  .replace(/\t/g, " ")
  .replace(/\r?\n/g, " ");
process.stdout.write(values.map(sanitize).join("\u001f"));
')

sep=$(printf '\037')
IFS=$sep read -r selected_scope selected_department board_path result reason selected_id selected_path selected_title selected_status selected_priority selected_owner blocked_id blocked_path blocked_title blocked_status blocked_priority blocked_owner blocked_reason <<EOF
$selector_line
EOF
unset IFS

action=$(recommend_action "$result" "$selected_status" "${blocked_reason:-$reason}" "none")

objective=""
deadline=""
founder_escalation=""
current_blocker=""
next_handoff=""
linked_artifacts=""
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
progress_path=""
progress_sync_state="none"
progress_updated_at="none"
progress_current_focus="none"
progress_next_command="none"
progress_recovery_notes="none"
progress_exists=false
progress_command=""

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
  linked_artifacts=$(field_value "$selected_path" "Linked artifacts")
  state_version=$(field_value "$selected_path" "State version")
  last_operation_id=$(field_value "$selected_path" "Last operation ID")
  last_transition_event=$(field_value "$selected_path" "Last transition event")
  interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
  resume_target=$(field_value_or_none "$selected_path" "Resume target")
  progress_path=$(work_item_progress_path "$selected_id")
  progress_sync_state=$(work_item_progress_sync_state "$selected_id")
  if [ -f "$progress_path" ]; then
    progress_exists=true
    progress_updated_at=$(progress_field_value_or_none "$progress_path" "Updated at")
    progress_current_focus=$(progress_field_value_or_none "$progress_path" "Current focus")
    progress_next_command=$(progress_field_value_or_none "$progress_path" "Next command")
    progress_recovery_notes=$(progress_field_value_or_none "$progress_path" "Recovery notes")
  fi

  case "$progress_sync_state" in
    missing|unlinked)
      progress_command="./.agents/skills/harness/scripts/upsert_work_item_progress.sh --expected-version $state_version \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
    stale|current)
      progress_command="./.agents/skills/harness/scripts/upsert_work_item_progress.sh \"$selected_id\" \"<current-focus>\" \"<next-command>\" \"[recovery-notes]\""
      ;;
  esac

  if [ "$selected_status" = "paused" ] && ! value_is_missing "$interrupt_marker"; then
    resume_command="./.agents/skills/harness/scripts/resume_work_item.sh --expected-version $state_version \"$selected_id\" \"[next-handoff]\" \"[reason]\""
    interrupt_action=$(interrupt_recommended_action "$interrupt_marker")
    if [ -n "$interrupt_action" ]; then
      action="$interrupt_action"
    fi
  else
    progress_action=$(progress_recommended_action "$selected_status" "$progress_sync_state")
    if [ -n "$progress_action" ]; then
      action="$progress_action"
    fi
  fi
elif [ "$result" = "blocked" ] && [ -n "$blocked_path" ] && [ -f "$blocked_path" ]; then
  blocked_state_version=$(field_value "$blocked_path" "State version")
  blocked_interrupt_marker=$(field_value_or_none "$blocked_path" "Interrupt marker")
  blocked_resume_target=$(field_value_or_none "$blocked_path" "Resume target")

  if [ "$blocked_status" = "paused" ] && ! value_is_missing "$blocked_interrupt_marker"; then
    blocked_resume_command="./.agents/skills/harness/scripts/resume_work_item.sh --expected-version $blocked_state_version \"$blocked_id\" \"[next-handoff]\" \"[reason]\""
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
  "linked_artifacts": $(json_escape "$linked_artifacts"),
  "state_version": $(json_escape "$state_version"),
  "last_operation_id": $(json_escape "$last_operation_id"),
  "last_transition_event": $(json_escape "$last_transition_event"),
  "interrupt_marker": $(json_escape "$interrupt_marker"),
  "resume_target": $(json_escape "$resume_target"),
  "resume_command": $(json_escape "$resume_command"),
  "progress_path": $(json_escape "$progress_path"),
  "progress_exists": $progress_exists,
  "progress_sync_state": $(json_escape "$progress_sync_state"),
  "progress_updated_at": $(json_escape "$progress_updated_at"),
  "progress_current_focus": $(json_escape "$progress_current_focus"),
  "progress_next_command": $(json_escape "$progress_next_command"),
  "progress_recovery_notes": $(json_escape "$progress_recovery_notes"),
  "progress_command": $(json_escape "$progress_command")
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
  "department": $(json_string_or_null "$selected_department"),
  "board": $(json_escape "$board_path"),
  "result": $(json_escape "$result"),
  "recommended_action": $(json_escape "$action"),
  "selector_reason": $(json_escape "$reason"),
  "selected_work_item": $selected_json,
  "next_blocked_candidate": $blocked_json
}
EOF
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
  printf 'Linked artifacts: %s\n' "$linked_artifacts"
  printf 'State version: %s\n' "$state_version"
  printf 'Last operation ID: %s\n' "$last_operation_id"
  printf 'Last transition event: %s\n' "$last_transition_event"
  printf 'Interrupt marker: %s\n' "$interrupt_marker"
  printf 'Resume target: %s\n' "$resume_target"
  printf 'Progress path: %s\n' "$progress_path"
  printf 'Progress sync state: %s\n' "$progress_sync_state"
  printf 'Progress updated at: %s\n' "$progress_updated_at"
  printf 'Progress current focus: %s\n' "$progress_current_focus"
  printf 'Progress next command: %s\n' "$progress_next_command"
  if [ -n "$resume_command" ]; then
    printf 'Resume command: %s\n' "$resume_command"
  fi
  if [ -n "$progress_command" ]; then
    printf 'Progress command: %s\n' "$progress_command"
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
