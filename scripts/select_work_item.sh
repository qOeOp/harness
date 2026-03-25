#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  cat <<'EOF' >&2
usage: ./.agents/skills/harness/scripts/select_work_item.sh [--json|--id-only|--path-only] [company|founder|department <slug>]
EOF
}

output_mode="summary"

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      output_mode="json"
      shift
      ;;
    --id-only)
      output_mode="id"
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
if [ $# -gt 0 ]; then
  shift
fi

department=""
board_path=""

case "$scope" in
  company)
    board_path="$state_boards_dir/company.md"
    ;;
  founder)
    board_path="$state_boards_dir/founder.md"
    ;;
  department)
    department="${1:-}"
    if [ -z "$department" ]; then
      usage
      exit 1
    fi
    if [ ! -d ".harness/workspace/departments/$department" ]; then
      echo "unknown department: $department" >&2
      exit 1
    fi
    board_path=".harness/workspace/departments/$department/workspace/board.md"
    ;;
  *)
    usage
    exit 1
    ;;
esac

ensure_boards_in_sync || {
  echo "failed to synchronize boards before selection" >&2
  exit 1
}

if [ ! -f "$board_path" ]; then
  echo "missing board: $board_path" >&2
  exit 1
fi

is_open_status() {
  case "$1" in
    backlog|framing|planning|ready|in-progress|review|paused) return 0 ;;
    *) return 1 ;;
  esac
}

status_rank() {
  case "$1" in
    review) printf '10\n' ;;
    paused) printf '15\n' ;;
    in-progress) printf '20\n' ;;
    ready) printf '30\n' ;;
    planning) printf '40\n' ;;
    framing) printf '50\n' ;;
    backlog) printf '60\n' ;;
    *) printf '99\n' ;;
  esac
}

priority_rank() {
  case "$1" in
    critical) printf '10\n' ;;
    high) printf '20\n' ;;
    medium) printf '30\n' ;;
    low) printf '40\n' ;;
    *) printf '99\n' ;;
  esac
}

participation_rank() {
  case "$1" in
    required) printf '10\n' ;;
    blocked) printf '20\n' ;;
    optional) printf '30\n' ;;
    *) printf '99\n' ;;
  esac
}

deadline_key() {
  deadline="$1"
  if value_is_missing "$deadline"; then
    printf '9999-99-99\n'
  else
    printf '%s\n' "$deadline"
  fi
}

append_reason() {
  existing="$1"
  addition="$2"

  if [ -z "$addition" ] || [ "$addition" = "none" ]; then
    printf '%s\n' "$existing"
    return 0
  fi

  if [ -z "$existing" ]; then
    printf '%s\n' "$addition"
  else
    printf '%s; %s\n' "$existing" "$addition"
  fi
}

unresolved_blockers=""
blocked_by_resolved() {
  blockers="$1"
  unresolved_blockers=""

  if value_is_missing "$blockers"; then
    return 0
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $blockers
  IFS=$old_ifs

  for raw_blocker in "$@"; do
    blocker_id=$(trim "$raw_blocker")
    [ -n "$blocker_id" ] || continue
    blocker_file=$(work_item_path "$blocker_id")

    if [ ! -f "$blocker_file" ]; then
      unresolved_blockers=$(append_reason "$unresolved_blockers" "$blocker_id")
      continue
    fi

    blocker_status=$(field_value "$blocker_file" "Status")
    if [ "$blocker_status" != "done" ]; then
      unresolved_blockers=$(append_reason "$unresolved_blockers" "$blocker_id")
    fi
  done

  [ -z "$unresolved_blockers" ]
}

candidate_tmp=$(mktemp)
blocked_tmp=$(mktemp)
trap 'rm -f "$candidate_tmp" "$blocked_tmp"' EXIT HUP INT TERM

for file in $(list_work_items); do
  id=$(field_value "$file" "ID")
  title=$(field_value "$file" "Title")
  status=$(field_value "$file" "Status")
  priority=$(field_value "$file" "Priority")
  owner=$(field_value "$file" "Owner")
  deadline=$(field_value "$file" "Deadline")
  founder_escalation=$(field_value "$file" "Founder escalation")
  blocked_by=$(field_value "$file" "Blocked by")
  current_blocker=$(field_value "$file" "Current blocker")
  interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")

  if ! is_open_status "$status"; then
    continue
  fi

  scope_rank="00"
  reason=""
  selected=0

  case "$scope" in
    company)
      selected=1
      if [ "$founder_escalation" = "pending-founder" ]; then
        reason=$(append_reason "$reason" "awaiting founder decision")
      fi
      ;;
    founder)
      if [ "$founder_escalation" = "pending-founder" ] || [ "$interrupt_marker" = "founder-review-required" ]; then
        selected=1
      fi
      ;;
    department)
      participation=$(department_participation "$file" "$department" 2>/dev/null || true)
      case "$participation" in
        required|optional|blocked)
          selected=1
          scope_rank=$(participation_rank "$participation")
          ;;
      esac
      if [ "$participation" = "blocked" ]; then
        reason=$(append_reason "$reason" "department marked blocked")
      fi
      if [ "$selected" -eq 1 ] && [ "$founder_escalation" = "pending-founder" ]; then
        reason=$(append_reason "$reason" "awaiting founder decision")
      fi
      ;;
  esac

  if [ "$selected" -ne 1 ]; then
    continue
  fi

  if ! blocked_by_resolved "$blocked_by"; then
    reason=$(append_reason "$reason" "blocked by $unresolved_blockers")
  fi

  if ! value_is_missing "$current_blocker"; then
    reason=$(append_reason "$reason" "$current_blocker")
  fi

  if [ "$status" = "paused" ] && ! value_is_missing "$interrupt_marker" && [ "$interrupt_marker" != "none" ]; then
    reason=$(append_reason "$reason" "interrupt marker $interrupt_marker")
  fi

  line=$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$scope_rank" \
    "$(status_rank "$status")" \
    "$(priority_rank "$priority")" \
    "$(deadline_key "$deadline")" \
    "$id" \
    "$file" \
    "$title" \
    "$status" \
    "$priority" \
    "$owner" \
    "$reason")

  if [ -z "$reason" ]; then
    printf '%s\n' "$line" >>"$candidate_tmp"
  else
    printf '%s\n' "$line" >>"$blocked_tmp"
  fi
done

pick_top_line() {
  source_file="$1"
  if [ ! -s "$source_file" ]; then
    return 1
  fi
  sort -t "$(printf '\t')" -k1,1n -k2,2n -k3,3n -k4,4 -k5,5 "$source_file" | head -n 1
}

tab=$(printf '\t')

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

emit_json_result() {
  result="$1"
  selected_id="$2"
  selected_path="$3"
  selected_title="$4"
  selected_status="$5"
  selected_priority="$6"
  selected_owner="$7"
  reason="$8"
  blocked_id="${9:-}"
  blocked_path="${10:-}"
  blocked_title="${11:-}"
  blocked_status="${12:-}"
  blocked_priority="${13:-}"
  blocked_owner="${14:-}"
  blocked_reason="${15:-}"

  if [ -n "$selected_id" ]; then
    selected_json=$(cat <<EOF
{
  "id": $(json_escape "$selected_id"),
  "path": $(json_escape "$selected_path"),
  "title": $(json_escape "$selected_title"),
  "status": $(json_escape "$selected_status"),
  "priority": $(json_escape "$selected_priority"),
  "owner": $(json_escape "$selected_owner")
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
  "blocked_because": $(json_escape "$blocked_reason")
}
EOF
)
  else
    blocked_json="null"
  fi

  cat <<EOF
{
  "scope": $(json_escape "$scope"),
  "department": $(json_string_or_null "$department"),
  "board": $(json_escape "$board_path"),
  "result": $(json_escape "$result"),
  "reason": $(json_escape "$reason"),
  "selected_work_item": $selected_json,
  "next_blocked_candidate": $blocked_json
}
EOF
}

emit_success() {
  line="$1"
  IFS=$tab read -r scope_key status_key priority_key deadline_sort selected_id selected_path selected_title selected_status selected_priority selected_owner selected_reason <<EOF
$line
EOF
  unset IFS

  case "$output_mode" in
    id)
      printf '%s\n' "$selected_id"
      ;;
    path)
      printf '%s\n' "$selected_path"
      ;;
    json)
      emit_json_result "actionable" \
        "$selected_id" \
        "$selected_path" \
        "$selected_title" \
        "$selected_status" \
        "$selected_priority" \
        "$selected_owner" \
        "actionable"
      ;;
    summary)
      printf 'Scope: %s\n' "$scope"
      printf 'Board: %s\n' "$board_path"
      printf 'Selected work item: %s\n' "$selected_id"
      printf 'Path: %s\n' "$selected_path"
      printf 'Title: %s\n' "$selected_title"
      printf 'Status: %s\n' "$selected_status"
      printf 'Priority: %s\n' "$selected_priority"
      printf 'Owner: %s\n' "$selected_owner"
      printf 'Reason: actionable\n'
      ;;
  esac
}

emit_blocked() {
  line="$1"
  IFS=$tab read -r scope_key status_key priority_key deadline_sort blocked_id blocked_path blocked_title blocked_status blocked_priority blocked_owner blocked_reason <<EOF
$line
EOF
  unset IFS

  case "$output_mode" in
    json)
      emit_json_result "blocked" \
        "" \
        "" \
        "" \
        "" \
        "" \
        "" \
        "no actionable work item" \
        "$blocked_id" \
        "$blocked_path" \
        "$blocked_title" \
        "$blocked_status" \
        "$blocked_priority" \
        "$blocked_owner" \
        "$blocked_reason"
      ;;
    *)
      printf 'Scope: %s\n' "$scope"
      printf 'Board: %s\n' "$board_path"
      printf 'Selected work item: none\n'
      printf 'Reason: no actionable work item\n'
      printf 'Next blocked candidate: %s\n' "$blocked_id"
      printf 'Path: %s\n' "$blocked_path"
      printf 'Title: %s\n' "$blocked_title"
      printf 'Blocked because: %s\n' "$blocked_reason"
      ;;
  esac
}

if top_line=$(pick_top_line "$candidate_tmp" 2>/dev/null); then
  emit_success "$top_line"
  exit 0
fi

if blocked_line=$(pick_top_line "$blocked_tmp" 2>/dev/null); then
  emit_blocked "$blocked_line"
  exit 2
fi

if [ "$output_mode" = "summary" ]; then
  printf 'Scope: %s\n' "$scope"
  printf 'Board: %s\n' "$board_path"
  printf 'Selected work item: none\n'
  printf 'Reason: no open work item matches this scope\n'
fi

if [ "$output_mode" = "json" ]; then
  emit_json_result "empty" \
    "" \
    "" \
    "" \
    "" \
    "" \
    "" \
    "no open work item matches this scope"
fi

exit 2
