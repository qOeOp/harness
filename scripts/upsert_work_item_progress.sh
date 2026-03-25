#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

expected_version=""
operation_id=""

usage() {
  echo "usage: $0 [--expected-version <version>] [--operation-id <id>] <work-item-id> <current-focus> <next-command> [recovery-notes]" >&2
  exit 1
}

ensure_progress_field() {
  file="$1"
  label="$2"
  value="$3"

  if grep -Fq -- "- $label: " "$file"; then
    replace_field "$file" "$label" "$value"
    return 0
  fi

  tmp=$(mktemp)
  awk -v label="$label" -v value="$value" '
    BEGIN { inserted = 0 }
    /^- Recovery notes: / && !inserted {
      print "- " label ": " value
      inserted = 1
    }
    { print }
    END {
      if (!inserted) {
        print "- " label ": " value
      }
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-version)
      [ "$#" -ge 2 ] || usage
      expected_version="$2"
      shift 2
      ;;
    --operation-id)
      [ "$#" -ge 2 ] || usage
      operation_id="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage
      ;;
    *)
      break
      ;;
  esac
done

work_item_id="${1:-}"
current_focus="${2:-}"
next_command="${3:-}"
recovery_notes="${4:-none}"

if [ -z "$work_item_id" ] || [ -z "$current_focus" ] || [ -z "$next_command" ]; then
  usage
fi

ensure_state_dirs
work_item_file=$(require_work_item "$work_item_id")
progress_path=$(work_item_progress_path "$work_item_id")
today=$(date +%F)
created_at=""

current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
current_operation_id=$(field_value "$work_item_file" "Last operation ID")

if [ ! -f "$progress_path" ]; then
  cat >"$progress_path" <<EOF
# Work Item Progress

- Linked work items: $work_item_id
- Work Item: $work_item_id
- Created at: $today
- Updated at: $today
- Status snapshot: $current_status
- State version snapshot: $current_version
- Last operation ID snapshot: $current_operation_id
- Current focus: $current_focus
- Next command: $next_command
- Recovery notes: $recovery_notes
EOF
fi

if ! grep -Fq -- "- Linked work items: " "$progress_path"; then
  tmp=$(mktemp)
  {
    printf '# Work Item Progress\n\n'
    printf -- '- Linked work items: %s\n' "$work_item_id"
    tail -n +2 "$progress_path" 2>/dev/null || true
  } >"$tmp"
  mv "$tmp" "$progress_path"
fi

if ! grep -Fq -- "- Work Item: " "$progress_path"; then
  tmp=$(mktemp)
  awk -v id="$work_item_id" '
    BEGIN { inserted = 0 }
    /^- Linked work items: / && !inserted {
      print
      print "- Work Item: " id
      inserted = 1
      next
    }
    { print }
    END {
      if (!inserted) {
        print "- Work Item: " id
      }
    }
  ' "$progress_path" >"$tmp"
  mv "$tmp" "$progress_path"
fi

created_at=$(field_value "$progress_path" "Created at")
if [ -z "$created_at" ]; then
  created_at="$today"
fi

ensure_progress_field "$progress_path" "Created at" "$created_at"
ensure_progress_field "$progress_path" "Updated at" "$today"
ensure_progress_field "$progress_path" "Status snapshot" "$current_status"
ensure_progress_field "$progress_path" "State version snapshot" "$current_version"
ensure_progress_field "$progress_path" "Last operation ID snapshot" "$current_operation_id"
ensure_progress_field "$progress_path" "Current focus" "$current_focus"
ensure_progress_field "$progress_path" "Next command" "$next_command"
ensure_progress_field "$progress_path" "Recovery notes" "$recovery_notes"

existing_entry=$(linked_artifact_entry_for_path "$work_item_file" "$progress_path" || true)
desired_entry="$progress_path|progress-artifact|active"

if [ "$existing_entry" != "$desired_entry" ] || ! artifact_has_work_item_link "$progress_path" "$work_item_id"; then
  if [ -z "$expected_version" ]; then
    echo "expected-version is required when linking a new progress artifact" >&2
    exit 1
  fi

  if ! is_nonnegative_integer "$expected_version"; then
    echo "invalid expected-version: $expected_version" >&2
    exit 1
  fi

  if [ -z "$operation_id" ]; then
    operation_id=$(default_operation_id "$work_item_id" "link-progress")
  fi

  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    --operation-id "$operation_id" \
    "$work_item_id" \
    "$progress_path" \
    "progress-artifact" \
    "active" >/dev/null
fi

current_status=$(field_value "$work_item_file" "Status")
current_version=$(field_value "$work_item_file" "State version")
current_operation_id=$(field_value "$work_item_file" "Last operation ID")

ensure_progress_field "$progress_path" "Updated at" "$today"
ensure_progress_field "$progress_path" "Status snapshot" "$current_status"
ensure_progress_field "$progress_path" "State version snapshot" "$current_version"
ensure_progress_field "$progress_path" "Last operation ID snapshot" "$current_operation_id"

echo "$progress_path"
