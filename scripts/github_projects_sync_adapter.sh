#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  echo "usage: $0 <company|founder|department> [department-slug]" >&2
  exit 1
}

csv_escape() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/"/""/g')"
}

view="${1:-}"
department="${2:-}"

if [ -z "$view" ]; then
  usage
fi

case "$view" in
  company)
    printf '%s\n' 'Work Item,Type,Status,Priority,Owner,Required Departments,Current Blocker,Founder Escalation,Last Updated'
    for file in $(list_work_items); do
      csv_escape "$(field_value "$file" "ID"): $(field_value "$file" "Title")"
      printf ','
      csv_escape "$(field_value "$file" "Type")"
      printf ','
      csv_escape "$(field_value "$file" "Status")"
      printf ','
      csv_escape "$(field_value "$file" "Priority")"
      printf ','
      csv_escape "$(field_value "$file" "Owner")"
      printf ','
      csv_escape "$(field_value "$file" "Required departments")"
      printf ','
      csv_escape "$(field_value "$file" "Current blocker")"
      printf ','
      csv_escape "$(field_value "$file" "Founder escalation")"
      printf ','
      csv_escape "$(field_value "$file" "Updated at")"
      printf '\n'
    done
    ;;
  founder)
    printf '%s\n' 'Work Item,Why It Matters,Decision Needed,Deadline,Supporting Pack'
    for file in $(list_work_items); do
      if [ "$(field_value "$file" "Founder escalation")" = "pending-founder" ]; then
        csv_escape "$(field_value "$file" "ID"): $(field_value "$file" "Title")"
        printf ','
        csv_escape "$(field_value "$file" "Why it matters")"
        printf ','
        csv_escape "$(field_value "$file" "Decision needed")"
        printf ','
        csv_escape "$(field_value "$file" "Deadline")"
        printf ','
        csv_escape "$(first_linked_artifact_path "$file")"
        printf '\n'
      fi
    done
    ;;
  department)
    if [ -z "$department" ]; then
      usage
    fi
    if [ ! -d ".harness/workspace/departments/$department" ]; then
      echo "unknown department: $department" >&2
      exit 1
    fi
    printf '%s\n' 'Work Item,Participation,Local Status,Upstream Dependency,Next Handoff,Artifact Due'
    for file in $(list_work_items); do
      if participation=$(department_participation "$file" "$department" 2>/dev/null); then
        csv_escape "$(field_value "$file" "ID"): $(field_value "$file" "Title")"
        printf ','
        csv_escape "$participation"
        printf ','
        csv_escape "$(field_value "$file" "Status")"
        printf ','
        csv_escape "$(field_value "$file" "Blocked by")"
        printf ','
        csv_escape "$(field_value "$file" "Next handoff")"
        printf ','
        csv_escape "$(field_value "$file" "Due review at")"
        printf '\n'
      fi
    done
    ;;
  *)
    usage
    ;;
esac
