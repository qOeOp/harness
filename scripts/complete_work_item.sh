#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  printf 'usage: %s [--json|--path-only] --target-status review|done|killed [--work-item WI-xxxx] [--reason <text>] [--operation-id <id>] [company|founder|department <slug>]\n' "$(default_harness_command "complete_work_item.sh")" >&2
}

resolve_board_path() {
  scope="$1"
  department="$2"

  if ! runtime_governance_enabled; then
    printf '%s\n' "none"
    return 0
  fi

  case "$scope" in
    company)
      printf '%s\n' "$state_boards_dir/company.md"
      ;;
    founder)
      printf '%s\n' "$state_boards_dir/founder.md"
      ;;
    department)
      printf '.harness/workspace/departments/%s/workspace/board.md\n' "$department"
      ;;
  esac
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
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

closer_recommendation() {
  result="$1"
  target_status="$2"
  current_status="$3"
  reason="$4"
  interrupt_marker="${5:-none}"

  case "$result" in
    reviewed)
      printf '%s\n' "review_work_item_outputs"
      ;;
    review)
      printf '%s\n' "continue_review_work_item"
      ;;
    completed)
      printf '%s\n' "verify_done_state_and_move_on"
      ;;
    killed)
      printf '%s\n' "verify_killed_state_and_clear_followups"
      ;;
    done)
      printf '%s\n' "work_item_already_done"
      ;;
    already-killed)
      printf '%s\n' "work_item_already_killed"
      ;;
    blocked)
      case "$target_status:$current_status" in
        review:paused|done:paused)
          interrupt_action=$(interrupt_recommended_action "$interrupt_marker")
          if [ -n "$interrupt_action" ]; then
            printf '%s\n' "$interrupt_action"
          else
            printf '%s\n' "resume_paused_work_item_before_completion"
          fi
          ;;
        review:ready)
          printf '%s\n' "start_work_item_before_review"
          ;;
        review:planning|review:framing|review:backlog)
          printf '%s\n' "advance_item_to_ready_then_start_before_review"
          ;;
        done:in-progress)
          printf '%s\n' "move_item_to_review_before_done"
          ;;
        done:ready|done:planning|done:framing|done:backlog)
          printf '%s\n' "advance_item_before_done"
          ;;
        killed:done)
          printf '%s\n' "work_item_already_terminal"
          ;;
        *)
          case "$reason" in
            *"dependents still reference"*)
              printf '%s\n' "clear_downstream_dependencies_before_kill"
              ;;
            *"blocked by "*)
              printf '%s\n' "resolve_blocking_work_items"
              ;;
            *"awaiting founder decision"*)
              printf '%s\n' "collect_founder_decision_before_completion"
              ;;
            *)
              printf '%s\n' "inspect_open_current_work_item_output"
              ;;
          esac
          ;;
      esac
      ;;
    empty)
      printf '%s\n' "no_open_work_item_for_scope"
      ;;
    *)
      printf '%s\n' "inspect_open_current_work_item_output"
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
  "linked_artifacts": $(json_escape "$selected_linked_artifacts"),
  "state_version": $(json_escape "$selected_state_version"),
  "last_operation_id": $(json_escape "$selected_last_operation_id"),
  "last_transition_event": $(json_escape "$selected_last_transition_event"),
  "interrupt_marker": $(json_escape "$selected_interrupt_marker"),
  "resume_target": $(json_escape "$selected_resume_target"),
  "resume_command": $(json_escape "$resume_command")
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
  "target_status": $(json_escape "$target_status"),
  "result": $(json_escape "$result"),
  "recommended_action": $(json_escape "$recommended_action"),
  "closer_reason": $(json_escape "$closer_reason"),
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
target_status=""
complete_reason=""
operation_id=""
explicit_work_item_id=""

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
    --target-status)
      [ $# -ge 2 ] || usage
      target_status="$2"
      shift 2
      ;;
    --reason)
      [ $# -ge 2 ] || usage
      complete_reason="$2"
      shift 2
      ;;
    --operation-id)
      [ $# -ge 2 ] || usage
      operation_id="$2"
      shift 2
      ;;
    --work-item)
      [ $# -ge 2 ] || usage
      explicit_work_item_id="$2"
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

if [ -z "$target_status" ]; then
  usage
fi

case "$target_status" in
  review|done|killed) ;;
  *)
    echo "invalid target status: $target_status" >&2
    exit 1
    ;;
esac

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

if [ "$target_status" = "done" ] || [ "$target_status" = "killed" ]; then
  if [ -z "$explicit_work_item_id" ]; then
    echo "terminal completion requires --work-item WI-xxxx; scope-based selection is not allowed for $target_status" >&2
    exit 1
  fi
fi

if [ -z "$complete_reason" ]; then
  case "$target_status" in
    review) complete_reason="work item moved to review via $(default_harness_command "complete_work_item.sh")" ;;
    done) complete_reason="work item completed via $(default_harness_command "complete_work_item.sh")" ;;
    killed) complete_reason="work item killed via $(default_harness_command "complete_work_item.sh")" ;;
  esac
fi

require_command node

if [ -n "$explicit_work_item_id" ]; then
  board_path=$(resolve_board_path "$scope" "$department")
  selected_scope="$scope"
  selected_department="$department"
  opener_result="actionable"
  opener_action="explicit-target"
  selector_reason="explicit work item target"
  selected_id="$explicit_work_item_id"
  selected_path=$(require_work_item "$selected_id")
  selected_title=$(field_value "$selected_path" "Title")
  selected_status=$(field_value "$selected_path" "Status")
  selected_priority=$(field_value "$selected_path" "Priority")
  selected_owner=$(field_value "$selected_path" "Owner")
  selected_objective=$(field_value "$selected_path" "Objective")
  selected_deadline=$(field_value "$selected_path" "Deadline")
  selected_founder_escalation=$(field_value "$selected_path" "Founder escalation")
  selected_current_blocker=$(field_value "$selected_path" "Current blocker")
  selected_next_handoff=$(field_value "$selected_path" "Next handoff")
  selected_linked_artifacts=$(field_value "$selected_path" "Linked artifacts")
  selected_interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
  selected_resume_target=$(field_value_or_none "$selected_path" "Resume target")
  resume_command=""
  blocked_id=""
  blocked_path=""
  blocked_title=""
  blocked_status=""
  blocked_priority=""
  blocked_owner=""
  blocked_reason=""
else
  if opener_output=$("$script_dir/open_current_work_item.sh" --json "$scope" ${department:+"$department"} 2>/dev/null); then
    opener_status=0
  else
    opener_status=$?
    if [ "$opener_status" -gt 2 ]; then
      exit "$opener_status"
    fi
  fi

  opener_line=$(printf '%s' "$opener_output" | node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(0, "utf8"));
const selected = data.selected_work_item || {};
const blocked = data.next_blocked_candidate || {};
const values = [
  data.scope || "",
  data.department || "",
  data.board || "",
  data.result || "",
  data.recommended_action || "",
  data.selector_reason || "",
  selected.id || "",
  selected.path || "",
  selected.title || "",
  selected.status || "",
  selected.priority || "",
  selected.owner || "",
  selected.objective || "",
  selected.deadline || "",
  selected.founder_escalation || "",
  selected.current_blocker || "",
  selected.next_handoff || "",
  selected.linked_artifacts || "",
  selected.interrupt_marker || "",
  selected.resume_target || "",
  selected.resume_command || "",
  blocked.id || "",
  blocked.path || "",
  blocked.title || "",
  blocked.status || "",
  blocked.priority || "",
  blocked.owner || "",
  blocked.blocked_because || "",
  blocked.state_version || "",
  blocked.interrupt_marker || "",
  blocked.resume_target || "",
  blocked.resume_command || ""
];
const sanitize = (value) => String(value)
  .replace(/\u001f/g, " ")
  .replace(/\t/g, " ")
  .replace(/\r?\n/g, " ");
process.stdout.write(values.map(sanitize).join("\u001f"));
')

  sep=$(printf '\037')
  IFS=$sep read -r selected_scope selected_department board_path opener_result opener_action selector_reason selected_id selected_path selected_title selected_status selected_priority selected_owner selected_objective selected_deadline selected_founder_escalation selected_current_blocker selected_next_handoff selected_linked_artifacts selected_interrupt_marker selected_resume_target resume_command blocked_id blocked_path blocked_title blocked_status blocked_priority blocked_owner blocked_reason blocked_state_version blocked_interrupt_marker blocked_resume_target blocked_resume_command <<EOF
$opener_line
EOF
  unset IFS
fi

selected_state_version=""
selected_last_operation_id=""
selected_last_transition_event=""
selected_interrupt_marker="${selected_interrupt_marker:-none}"
selected_resume_target="${selected_resume_target:-none}"
resume_command="${resume_command:-}"
transition_event=""
transition_performed=false
closer_reason=""
result=""
blocked_state_version="${blocked_state_version:-}"
blocked_interrupt_marker="${blocked_interrupt_marker:-none}"
blocked_resume_target="${blocked_resume_target:-none}"
blocked_resume_command="${blocked_resume_command:-}"

if [ "$opener_result" != "actionable" ]; then
  result="$opener_result"
  closer_reason="$selector_reason"
  recommended_action=$(closer_recommendation "$result" "$target_status" "$blocked_status" "$blocked_reason" "$blocked_interrupt_marker")
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
  printf 'Target status: %s\n' "$target_status"
  printf 'Result: %s\n' "$result"
  printf 'Recommended action: %s\n' "$recommended_action"
  printf 'Closer reason: %s\n' "$closer_reason"
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

selected_state_version=$(field_value "$selected_path" "State version")
selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
selected_last_transition_event=$(field_value "$selected_path" "Last transition event")

case "$target_status:$selected_status" in
  review:in-progress)
    if [ -z "$operation_id" ]; then
      operation_id=$(default_operation_id "$selected_id" "to-review")
    fi
    "$script_dir/transition_work_item.sh" \
      --expected-from-status in-progress \
      --expected-version "$selected_state_version" \
      --operation-id "$operation_id" \
      -- \
      "$selected_id" \
      review \
      "" \
      "" \
      "$complete_reason" >/dev/null

    selected_status=$(field_value "$selected_path" "Status")
    selected_state_version=$(field_value "$selected_path" "State version")
    selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
    selected_last_transition_event=$(field_value "$selected_path" "Last transition event")
    selected_objective=$(field_value "$selected_path" "Objective")
    selected_deadline=$(field_value "$selected_path" "Deadline")
    selected_founder_escalation=$(field_value "$selected_path" "Founder escalation")
    selected_current_blocker=$(field_value "$selected_path" "Current blocker")
    selected_next_handoff=$(field_value "$selected_path" "Next handoff")
    selected_linked_artifacts=$(field_value "$selected_path" "Linked artifacts")
    selected_interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
    selected_resume_target=$(field_value_or_none "$selected_path" "Resume target")
    resume_command=""
    transition_event="$selected_last_transition_event"
    transition_performed=true
    closer_reason="$complete_reason"
    result="reviewed"
    ;;
  review:review)
    transition_event="$selected_last_transition_event"
    closer_reason="selected work item is already in review"
    result="review"
    if [ -z "$operation_id" ]; then
      operation_id="$selected_last_operation_id"
    fi
    ;;
  done:review)
    if [ -z "$operation_id" ]; then
      operation_id=$(default_operation_id "$selected_id" "to-done")
    fi
    "$script_dir/finalize_work_item.sh" \
      --expected-from-status review \
      --expected-version "$selected_state_version" \
      --operation-id "$operation_id" \
      "$selected_id" \
      done \
      none \
      none \
      "$complete_reason" >/dev/null

    selected_status=$(field_value "$selected_path" "Status")
    selected_state_version=$(field_value "$selected_path" "State version")
    selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
    selected_last_transition_event=$(field_value "$selected_path" "Last transition event")
    selected_objective=$(field_value "$selected_path" "Objective")
    selected_deadline=$(field_value "$selected_path" "Deadline")
    selected_founder_escalation=$(field_value "$selected_path" "Founder escalation")
    selected_current_blocker=$(field_value "$selected_path" "Current blocker")
    selected_next_handoff=$(field_value "$selected_path" "Next handoff")
    selected_linked_artifacts=$(field_value "$selected_path" "Linked artifacts")
    selected_interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
    selected_resume_target=$(field_value_or_none "$selected_path" "Resume target")
    resume_command=""
    transition_event="$selected_last_transition_event"
    transition_performed=true
    closer_reason="$complete_reason"
    result="completed"
    ;;
  killed:backlog|killed:framing|killed:planning|killed:ready|killed:in-progress|killed:review|killed:paused)
    if [ -z "$operation_id" ]; then
      operation_id=$(default_operation_id "$selected_id" "to-killed")
    fi
    "$script_dir/finalize_work_item.sh" \
      --expected-from-status "$selected_status" \
      --expected-version "$selected_state_version" \
      --operation-id "$operation_id" \
      "$selected_id" \
      killed \
      none \
      none \
      "$complete_reason" >/dev/null

    selected_status=$(field_value "$selected_path" "Status")
    selected_state_version=$(field_value "$selected_path" "State version")
    selected_last_operation_id=$(field_value "$selected_path" "Last operation ID")
    selected_last_transition_event=$(field_value "$selected_path" "Last transition event")
    selected_objective=$(field_value "$selected_path" "Objective")
    selected_deadline=$(field_value "$selected_path" "Deadline")
    selected_founder_escalation=$(field_value "$selected_path" "Founder escalation")
    selected_current_blocker=$(field_value "$selected_path" "Current blocker")
    selected_next_handoff=$(field_value "$selected_path" "Next handoff")
    selected_linked_artifacts=$(field_value "$selected_path" "Linked artifacts")
    selected_interrupt_marker=$(field_value_or_none "$selected_path" "Interrupt marker")
    selected_resume_target=$(field_value_or_none "$selected_path" "Resume target")
    resume_command=""
    transition_event="$selected_last_transition_event"
    transition_performed=true
    closer_reason="$complete_reason"
    result="killed"
    ;;
  done:done)
    transition_event="$selected_last_transition_event"
    closer_reason="selected work item is already done"
    result="done"
    if [ -z "$operation_id" ]; then
      operation_id="$selected_last_operation_id"
    fi
    ;;
  killed:killed)
    transition_event="$selected_last_transition_event"
    closer_reason="selected work item is already killed"
    result="already-killed"
    if [ -z "$operation_id" ]; then
      operation_id="$selected_last_operation_id"
    fi
    ;;
  review:ready)
    result="blocked"
    closer_reason="selected work item must be started before review"
    ;;
  review:paused|done:paused)
    result="blocked"
    closer_reason="selected work item is paused with interrupt marker $selected_interrupt_marker"
    ;;
  review:planning|review:framing|review:backlog)
    result="blocked"
    closer_reason="selected work item is not in progress yet"
    ;;
  done:in-progress)
    result="blocked"
    closer_reason="selected work item must move to review before done"
    ;;
  done:ready|done:planning|done:framing|done:backlog)
    result="blocked"
    closer_reason="selected work item is not ready for done"
    ;;
  killed:done)
    result="blocked"
    closer_reason="selected work item is already terminal"
    ;;
  *)
    result="blocked"
    closer_reason="selected work item cannot move to $target_status from status $selected_status"
    ;;
esac

recommended_action=$(closer_recommendation "$result" "$target_status" "$selected_status" "$closer_reason" "$selected_interrupt_marker")

case "$output_mode" in
  path)
    case "$result" in
      reviewed|review|completed|done|killed|already-killed)
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
      reviewed|review|completed|done|killed|already-killed) exit 0 ;;
      *) exit 2 ;;
    esac
    ;;
esac

printf 'Scope: %s\n' "$selected_scope"
printf 'Board: %s\n' "$board_path"
printf 'Target status: %s\n' "$target_status"
printf 'Result: %s\n' "$result"
printf 'Recommended action: %s\n' "$recommended_action"
printf 'Closer reason: %s\n' "$closer_reason"

case "$result" in
  reviewed|review|completed|done|killed|already-killed)
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
    printf 'Linked artifacts: %s\n' "$selected_linked_artifacts"
    printf 'State version: %s\n' "$selected_state_version"
    printf 'Last operation ID: %s\n' "$selected_last_operation_id"
    printf 'Last transition event: %s\n' "$selected_last_transition_event"
    printf 'Interrupt marker: %s\n' "$selected_interrupt_marker"
    printf 'Resume target: %s\n' "$selected_resume_target"
    if [ -n "$resume_command" ]; then
      printf 'Resume command: %s\n' "$resume_command"
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
