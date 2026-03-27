#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  printf 'usage: %s [--json|--record|--id-only|--path-only] [--all] [--task-id <WI-xxxx>] [--status <status>] [--owner <owner>] [--assignee <assignee>] [--stage-owner <owner>] [--role <role>] [--next-gate <gate>] [--department <slug>] [--decision-status <status>] [--review-status <status>] [--qa-status <status>] [--uat-status <status>] [--acceptance-status <status>] [--founder-escalation <status>]\n' "$(default_harness_command "query_work_items.sh")" >&2
  exit "${1:-1}"
}

output_mode="summary"
include_archived=0
task_id_filter=""
status_filter=""
owner_filter=""
assignee_filter=""
role_filter=""
stage_owner_filter=""
next_gate_filter=""
department_filter=""
decision_status_filter=""
review_status_filter=""
qa_status_filter=""
uat_status_filter=""
acceptance_status_filter=""
founder_escalation_filter=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      output_mode="json"
      shift
      ;;
    --record)
      output_mode="record"
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
    --all)
      include_archived=1
      shift
      ;;
    --task-id|--work-item)
      [ "$#" -ge 2 ] || usage
      task_id_filter="$2"
      shift 2
      ;;
    --status)
      [ "$#" -ge 2 ] || usage
      status_filter="$2"
      shift 2
      ;;
    --owner)
      [ "$#" -ge 2 ] || usage
      owner_filter="$2"
      shift 2
      ;;
    --assignee)
      [ "$#" -ge 2 ] || usage
      assignee_filter="$2"
      shift 2
      ;;
    --role)
      [ "$#" -ge 2 ] || usage
      role_filter="$2"
      shift 2
      ;;
    --stage-owner)
      [ "$#" -ge 2 ] || usage
      stage_owner_filter="$2"
      shift 2
      ;;
    --next-gate)
      [ "$#" -ge 2 ] || usage
      next_gate_filter="$2"
      shift 2
      ;;
    --department)
      [ "$#" -ge 2 ] || usage
      department_filter="$2"
      shift 2
      ;;
    --decision-status)
      [ "$#" -ge 2 ] || usage
      decision_status_filter="$2"
      shift 2
      ;;
    --review-status)
      [ "$#" -ge 2 ] || usage
      review_status_filter="$2"
      shift 2
      ;;
    --qa-status)
      [ "$#" -ge 2 ] || usage
      qa_status_filter="$2"
      shift 2
      ;;
    --uat-status)
      [ "$#" -ge 2 ] || usage
      uat_status_filter="$2"
      shift 2
      ;;
    --acceptance-status)
      [ "$#" -ge 2 ] || usage
      acceptance_status_filter="$2"
      shift 2
      ;;
    --founder-escalation)
      [ "$#" -ge 2 ] || usage
      founder_escalation_filter="$2"
      shift 2
      ;;
    --help|-h)
      usage 0
      ;;
    *)
      usage
      ;;
  esac
done

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

matches_filter() {
  actual="$1"
  expected="$2"

  if [ -z "$expected" ]; then
    return 0
  fi

  [ "$actual" = "$expected" ]
}

matches_department_filter() {
  file="$1"
  department="$2"

  if [ -z "$department" ]; then
    return 0
  fi

  if department_participation "$file" "$department" >/dev/null 2>&1; then
    return 0
  fi

  required_departments=$(field_value_or_none "$file" "Required departments")
  csv_contains_value "$required_departments" "$department"
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT HUP INT TERM

for file in $(list_work_items); do
  [ -f "$file" ] || continue
  id=$(field_value "$file" "ID")
  title=$(field_value "$file" "Title")
  status=$(field_value "$file" "Status")
  priority=$(field_value "$file" "Priority")
  owner=$(field_value "$file" "Owner")
  assignee=$(field_value_or_none "$file" "Assignee")
  stage_owner=$(field_value_or_none "$file" "Current stage owner")
  stage_role=$(field_value_or_none "$file" "Current stage role")
  next_gate=$(field_value_or_none "$file" "Next gate")
  decision_status=$(field_value_or_none "$file" "Decision status")
  review_status=$(field_value_or_none "$file" "Review status")
  qa_status=$(field_value_or_none "$file" "QA status")
  uat_status=$(field_value_or_none "$file" "UAT status")
  acceptance_status=$(field_value_or_none "$file" "Acceptance status")
  founder_escalation=$(field_value_or_none "$file" "Founder escalation")
  updated_at=$(field_value_or_none "$file" "Updated at")

  if [ "$include_archived" -ne 1 ] && [ "$status" = "archived" ]; then
    continue
  fi

  matches_filter "$id" "$task_id_filter" || continue
  matches_filter "$status" "$status_filter" || continue
  matches_filter "$owner" "$owner_filter" || continue
  matches_filter "$assignee" "$assignee_filter" || continue
  matches_filter "$stage_owner" "$stage_owner_filter" || continue
  matches_filter "$stage_role" "$role_filter" || continue
  matches_filter "$next_gate" "$next_gate_filter" || continue
  matches_filter "$decision_status" "$decision_status_filter" || continue
  matches_filter "$review_status" "$review_status_filter" || continue
  matches_filter "$qa_status" "$qa_status_filter" || continue
  matches_filter "$uat_status" "$uat_status_filter" || continue
  matches_filter "$acceptance_status" "$acceptance_status_filter" || continue
  matches_filter "$founder_escalation" "$founder_escalation_filter" || continue
  matches_department_filter "$file" "$department_filter" || continue

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" \
    "$file" \
    "$title" \
    "$status" \
    "$priority" \
    "$owner" \
    "$assignee" \
    "$stage_owner" \
    "$stage_role" \
    "$next_gate" \
    "$decision_status" \
    "$review_status" \
    "$qa_status" \
    "$uat_status" \
    "$acceptance_status" \
    "$founder_escalation" \
    "$updated_at" >>"$tmp"
done

case "$output_mode" in
  id)
    cut -f1 "$tmp"
    exit 0
    ;;
  path)
    cut -f2 "$tmp"
    exit 0
    ;;
  record)
    while IFS=$(printf '\t') read -r id path title status priority owner assignee stage_owner stage_role next_gate decision_status review_status qa_status uat_status acceptance_status founder_escalation updated_at; do
      emit_record "$id" "$path" "$title" "$status" "$priority" "$owner" "$assignee" "$stage_owner" "$stage_role" "$next_gate" "$decision_status" "$review_status" "$qa_status" "$uat_status" "$acceptance_status" "$founder_escalation" "$updated_at"
    done <"$tmp"
    exit 0
    ;;
  json)
    printf '[\n'
    first=1
    while IFS=$(printf '\t') read -r id path title status priority owner assignee stage_owner stage_role next_gate decision_status review_status qa_status uat_status acceptance_status founder_escalation updated_at; do
      [ -n "$id" ] || continue
      if [ "$first" -eq 0 ]; then
        printf ',\n'
      fi
      first=0
      cat <<EOF
{
  "id": $(json_escape "$id"),
  "path": $(json_escape "$path"),
  "title": $(json_escape "$title"),
  "status": $(json_escape "$status"),
  "priority": $(json_escape "$priority"),
  "owner": $(json_escape "$owner"),
  "assignee": $(json_escape "$assignee"),
  "stage_owner": $(json_escape "$stage_owner"),
  "role": $(json_escape "$stage_role"),
  "next_gate": $(json_escape "$next_gate"),
  "decision_status": $(json_escape "$decision_status"),
  "review_status": $(json_escape "$review_status"),
  "qa_status": $(json_escape "$qa_status"),
  "uat_status": $(json_escape "$uat_status"),
  "acceptance_status": $(json_escape "$acceptance_status"),
  "founder_escalation": $(json_escape "$founder_escalation"),
  "updated_at": $(json_escape "$updated_at")
}
EOF
    done <"$tmp"
    printf '\n]\n'
    exit 0
    ;;
esac

if [ ! -s "$tmp" ]; then
  printf 'No matching work items.\n'
  exit 0
fi

printf 'Work Items\n'
while IFS=$(printf '\t') read -r id path title status priority owner assignee stage_owner stage_role next_gate decision_status review_status qa_status uat_status acceptance_status founder_escalation updated_at; do
  printf '%s | %s | %s | owner=%s | assignee=%s | stage-owner=%s | role=%s | next-gate=%s | decision=%s | review=%s | qa=%s | uat=%s | acceptance=%s | founder=%s | %s\n' \
    "$id" \
    "$status" \
    "$priority" \
    "$owner" \
    "$assignee" \
    "$stage_owner" \
    "$stage_role" \
    "$next_gate" \
    "$decision_status" \
    "$review_status" \
    "$qa_status" \
    "$uat_status" \
    "$acceptance_status" \
    "$founder_escalation" \
    "$title"
done <"$tmp"
