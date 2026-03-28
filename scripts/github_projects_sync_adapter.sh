#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

usage() {
  echo "usage: $0 <shared|founder>" >&2
  exit 1
}

csv_escape() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/"/""/g')"
}

view="${1:-}"

if [ -z "$view" ]; then
  usage
fi

view=$(normalize_work_item_scope "$view") || usage

case "$view" in
  shared)
    printf '%s\n' 'Work Item,Type,Status,Priority,Owner,Current Blocker,Founder Escalation,Last Updated'
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
  *)
    usage
    ;;
esac
