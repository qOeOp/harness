#!/bin/sh
set -eu

state_root=".harness/workspace/state"
state_items_dir="$state_root/items"
state_boards_dir="$state_root/boards"
state_progress_dir="$state_root/progress"
state_transitions_dir="$state_root/transitions"
state_board_refreshes_dir="$state_root/board-refreshes"
work_item_schema_version="1"
work_item_state_authority="script-only"

ensure_state_dirs() {
  mkdir -p "$state_items_dir" "$state_boards_dir" "$state_progress_dir" "$state_transitions_dir" "$state_board_refreshes_dir"
}

ensure_boards_in_sync() {
  if [ "${STATE_SKIP_BOARD_SYNC:-0}" = "1" ]; then
    return 0
  fi

  if "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
    return 0
  fi

  "$script_dir/refresh_boards.sh" >/dev/null
  "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1
}

sync_progress_snapshot_if_present() {
  work_item_file="$1"
  work_item_id=$(field_value "$work_item_file" "ID")
  progress_path=$(work_item_progress_path "$work_item_id")

  if [ ! -f "$progress_path" ]; then
    return 0
  fi

  replace_field "$progress_path" "Updated at" "$(date +%F)"
  replace_field "$progress_path" "Status snapshot" "$(field_value "$work_item_file" "Status")"
  replace_field "$progress_path" "State version snapshot" "$(field_value "$work_item_file" "State version")"
  replace_field "$progress_path" "Last operation ID snapshot" "$(field_value "$work_item_file" "Last operation ID")"
}

trim() {
  printf '%s\n' "$1" | sed 's/^ *//; s/ *$//'
}

value_is_missing() {
  case "$1" in
    ""|none) return 0 ;;
    *) return 1 ;;
  esac
}

is_nonnegative_integer() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

sanitize_operation_fragment() {
  printf '%s\n' "$1" | tr ' /:' '-' | sed 's/[^A-Za-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

default_operation_id() {
  subject=$(sanitize_operation_fragment "$1")
  action=$(sanitize_operation_fragment "$2")
  printf 'OP-%s-%s-%s-%s\n' "$(date +%Y%m%dT%H%M%S)" "$$" "$subject" "$action"
}

default_state_invoker() {
  script_path="${1:-}"
  script_name=$(basename "${script_path:-unknown}")
  printf './.agents/skills/harness/scripts/%s\n' "$script_name"
}

require_explicit_state_actor() {
  actor="${1:-}"
  script_path="${2:-unknown}"

  if value_is_missing "$actor" || [ "$actor" = "system" ]; then
    echo "STATE_ACTOR must be set to a non-system actor for state mutation via $script_path" >&2
    return 1
  fi

  return 0
}

work_item_header_labels() {
  cat <<'EOF'
Schema version
State authority
State version
Last operation ID
ID
Title
Type
Status
Priority
Owner
Sponsor
Objective
Ready criteria
Done criteria
Required artifacts
Why it matters
Decision needed
Deadline
Created at
Updated at
Due review at
Founder escalation
Required departments
Participation records
Linked artifacts
Last transition event
Interrupt marker
Resume target
Blocked by
Blocks
Current blocker
Next handoff
EOF
}

work_item_header_schema_matches() {
  file="$1"
  expected=$(mktemp)
  actual=$(mktemp)
  work_item_header_labels >"$expected"
  awk '
    /^## Summary$/ { exit }
    /^- / {
      label = $0
      sub(/^- /, "", label)
      sub(/: .*/, "", label)
      print label
    }
  ' "$file" >"$actual"

  if cmp -s "$expected" "$actual"; then
    rm -f "$expected" "$actual"
    return 0
  fi

  rm -f "$expected" "$actual"
  return 1
}

field_value() {
  file="$1"
  label="$2"
  awk -v label="$label" '
    index($0, "- " label ": ") == 1 {
      print substr($0, length("- " label ": ") + 1)
      exit
    }
  ' "$file"
}

field_value_or_none() {
  file="$1"
  label="$2"
  value=$(field_value "$file" "$label")

  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "none"
  fi
}

replace_field() {
  file="$1"
  label="$2"
  value="$3"
  tmp=$(mktemp)
  awk -v label="$label" -v value="$value" '
    index($0, "- " label ": ") == 1 && !done {
      print "- " label ": " value
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        exit 2
      }
    }
  ' "$file" >"$tmp" || {
    rc=$?
    rm -f "$tmp"
    return "$rc"
  }
  mv "$tmp" "$file"
}

next_work_item_id() {
  ensure_state_dirs
  max=0
  for file in "$state_items_dir"/WI-*.md; do
    [ -f "$file" ] || continue
    base=$(basename "$file" .md)
    num=$(printf '%s' "$base" | sed 's/^WI-0*//')
    [ -n "$num" ] || num=0
    if [ "$num" -gt "$max" ]; then
      max=$num
    fi
  done
  next=$((max + 1))
  printf 'WI-%04d\n' "$next"
}

work_item_path() {
  id="$1"
  printf '%s/%s.md\n' "$state_items_dir" "$id"
}

work_item_progress_path() {
  id="$1"
  printf '%s/%s.md\n' "$state_progress_dir" "$id"
}

progress_field_value_or_none() {
  progress_path="$1"
  label="$2"

  if [ ! -f "$progress_path" ]; then
    printf '%s\n' "none"
    return 0
  fi

  value=$(field_value "$progress_path" "$label")
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "none"
  fi
}

work_item_progress_sync_state() {
  id="$1"
  work_item_file=$(require_work_item "$id")
  progress_path=$(work_item_progress_path "$id")

  if [ ! -f "$progress_path" ]; then
    printf '%s\n' "missing"
    return 0
  fi

  expected_entry="$progress_path|progress-artifact|active"
  existing_entry=$(linked_artifact_entry_for_path "$work_item_file" "$progress_path" || true)
  if [ "$existing_entry" != "$expected_entry" ] || ! artifact_has_work_item_link "$progress_path" "$id"; then
    printf '%s\n' "unlinked"
    return 0
  fi

  current_status=$(field_value "$work_item_file" "Status")
  current_version=$(field_value "$work_item_file" "State version")
  current_operation_id=$(field_value "$work_item_file" "Last operation ID")
  progress_status=$(progress_field_value_or_none "$progress_path" "Status snapshot")
  progress_version=$(progress_field_value_or_none "$progress_path" "State version snapshot")
  progress_operation_id=$(progress_field_value_or_none "$progress_path" "Last operation ID snapshot")

  if [ "$progress_status" != "$current_status" ] || [ "$progress_version" != "$current_version" ] || [ "$progress_operation_id" != "$current_operation_id" ]; then
    printf '%s\n' "stale"
    return 0
  fi

  printf '%s\n' "current"
}

work_item_has_transition_events() {
  id="$1"
  find "$state_transitions_dir" -maxdepth 1 -type f -name "*-$id-*.md" | grep -q .
}

latest_transition_event_path() {
  id="$1"
  find "$state_transitions_dir" -maxdepth 1 -type f -name "*-$id-*.md" | sort | tail -n 1
}

list_board_refresh_events() {
  if [ ! -d "$state_board_refreshes_dir" ]; then
    return 0
  fi
  find "$state_board_refreshes_dir" -maxdepth 1 -type f -name 'BR-*.md' | sort
}

latest_board_refresh_event_path() {
  list_board_refresh_events | tail -n 1
}

require_work_item() {
  path=$(work_item_path "$1")
  if [ ! -f "$path" ]; then
    echo "missing work item: $1" >&2
    return 1
  fi
  printf '%s\n' "$path"
}

is_valid_work_item_status() {
  case "$1" in
    backlog|framing|planning|ready|in-progress|review|done|paused|killed) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_artifact_status() {
  case "$1" in
    draft|under-review|approved|active|superseded|archived) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_founder_escalation() {
  case "$1" in
    not-needed|pending-founder|approved|rejected|superseded) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_interrupt_marker() {
  case "$1" in
    none|manual-review-required|founder-review-required|risk-review-required) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_resume_target() {
  case "$1" in
    none|backlog|framing|planning|ready|in-progress|review) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_trace_event_type() {
  case "$1" in
    state-transition|artifact-link|approval-pause|resume|field-update|terminal-cleanup|schema-migration|blocker-release|board-refresh) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_participation() {
  case "$1" in
    required|optional|blocked|done|not-involved) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_type() {
  case "$1" in
    vision|governance|company-init|research|department-task|demo) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_priority() {
  case "$1" in
    low|medium|high|critical) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_board_refresh_target() {
  target="$1"

  case "$target" in
    .harness/workspace/state/boards/company.md|.harness/workspace/state/boards/founder.md)
      return 0
      ;;
    .harness/workspace/departments/*/workspace/board.md)
      department=$(printf '%s\n' "$target" | sed 's#^.harness/workspace/departments/##; s#/workspace/board.md$##')
      [ -n "$department" ] && [ -d ".harness/workspace/departments/$department" ]
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

transition_allowed() {
  current="$1"
  next="$2"
  case "$current:$next" in
    backlog:framing|backlog:paused|backlog:killed) return 0 ;;
    framing:planning|framing:paused|framing:killed) return 0 ;;
    planning:ready|planning:framing|planning:paused|planning:killed) return 0 ;;
    ready:in-progress|ready:planning|ready:paused|ready:killed) return 0 ;;
    in-progress:review|in-progress:planning|in-progress:paused|in-progress:killed) return 0 ;;
    review:done|review:planning|review:paused|review:killed) return 0 ;;
    paused:framing|paused:planning|paused:ready|paused:in-progress|paused:killed) return 0 ;;
    *) return 1 ;;
  esac
}

interrupt_default_blocker() {
  case "$1" in
    manual-review-required) printf '%s\n' "waiting for manual review" ;;
    founder-review-required) printf '%s\n' "waiting for founder review" ;;
    risk-review-required) printf '%s\n' "waiting for risk review" ;;
    *) printf '%s\n' "none" ;;
  esac
}

interrupt_recommended_action() {
  marker="$1"

  case "$marker" in
    manual-review-required)
      printf '%s\n' "complete_manual_review_then_resume"
      ;;
    founder-review-required)
      printf '%s\n' "collect_founder_decision_then_resume"
      ;;
    risk-review-required)
      printf '%s\n' "complete_risk_review_then_resume"
      ;;
    *)
      printf '%s\n' ""
      ;;
  esac
}

transition_event_type_for_status_change() {
  from_status="$1"
  to_status="$2"

  case "$from_status:$to_status" in
    *:paused)
      printf '%s\n' "approval-pause"
      ;;
    paused:backlog|paused:framing|paused:planning|paused:ready|paused:in-progress|paused:review)
      printf '%s\n' "resume"
      ;;
    *)
      printf '%s\n' "state-transition"
      ;;
  esac
}

list_work_items() {
  if [ ! -d "$state_items_dir" ]; then
    return 0
  fi
  find "$state_items_dir" -maxdepth 1 -type f -name 'WI-*.md' | sort
}

list_departments() {
  find .harness/workspace/departments -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

slug_to_title() {
  printf '%s\n' "$1" | awk -F- '
    {
      for (i = 1; i <= NF; i++) {
        printf toupper(substr($i, 1, 1)) substr($i, 2)
        if (i < NF) {
          printf " "
        }
      }
      printf "\n"
    }
  '
}

pretty_csv() {
  value="$1"
  case "$value" in
    ""|none) printf '%s\n' "-" ;;
    *)
      printf '%s\n' "$value" | awk -F, '
        {
          out = ""
          for (i = 1; i <= NF; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
            out = out (i == 1 ? "" : ", ") $i
          }
          print out
        }
      '
      ;;
  esac
}

csv_contains_value() {
  csv="$1"
  needle="$2"

  if value_is_missing "$csv"; then
    return 1
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $csv
  IFS=$old_ifs

  for raw_value in "$@"; do
    value=$(trim "$raw_value")
    [ -n "$value" ] || continue
    if [ "$value" = "$needle" ]; then
      return 0
    fi
  done

  return 1
}

csv_remove_value() {
  csv="$1"
  needle="$2"
  updated=""

  if value_is_missing "$csv"; then
    printf '%s\n' "none"
    return 0
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $csv
  IFS=$old_ifs

  for raw_value in "$@"; do
    value=$(trim "$raw_value")
    [ -n "$value" ] || continue
    if [ "$value" = "$needle" ]; then
      continue
    fi
    if [ -z "$updated" ]; then
      updated="$value"
    else
      updated="${updated},$value"
    fi
  done

  if [ -z "$updated" ]; then
    printf '%s\n' "none"
  else
    printf '%s\n' "$updated"
  fi
}

sanitize_board_cell() {
  value="$1"
  case "$value" in
    ""|none) printf '%s\n' "-" ;;
    *)
      printf '%s\n' "$value" | tr '\n' ' ' | sed 's/|/\\|/g; s/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
      ;;
  esac
}

department_participation() {
  file="$1"
  department="$2"
  records=$(field_value "$file" "Participation records")
  if [ -z "$records" ] || [ "$records" = "none" ]; then
    return 1
  fi
  printf '%s\n' "$records" | tr ',' '\n' | awk -F= -v department="$department" '
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      if ($1 == department) {
        print $2
        found = 1
        exit
      }
    }
    END {
      if (!found) {
        exit 1
      }
    }
  '
}

first_linked_artifact_path() {
  file="$1"
  links=$(field_value "$file" "Linked artifacts")
  case "$links" in
    ""|none) printf '%s\n' "-" ;;
    *)
      first=${links%%;*}
      printf '%s\n' "${first%%|*}"
      ;;
  esac
}

linked_artifact_entry_for_path() {
  work_item_file="$1"
  artifact_path="$2"
  links=$(field_value "$work_item_file" "Linked artifacts")

  if value_is_missing "$links"; then
    return 1
  fi

  old_ifs=${IFS- }
  IFS=';'
  set -- $links
  IFS=$old_ifs

  for existing_entry in "$@"; do
    existing_entry=$(trim "$existing_entry")
    [ -n "$existing_entry" ] || continue
    existing_path=${existing_entry%%|*}
    if [ "$existing_path" = "$artifact_path" ]; then
      printf '%s\n' "$existing_entry"
      return 0
    fi
  done

  return 1
}

sha256_value() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "missing sha256 tool" >&2
    return 1
  fi
}

transition_event_hash_from_values_legacy() {
  work_item="$1"
  at="$2"
  from_status="$3"
  to_status="$4"
  actor="$5"
  reason="$6"
  current_blocker="$7"
  next_handoff="$8"
  prev_event="$9"
  prev_event_hash="${10}"

  {
    printf 'Work Item:%s\n' "$work_item"
    printf 'At:%s\n' "$at"
    printf 'From:%s\n' "$from_status"
    printf 'To:%s\n' "$to_status"
    printf 'Actor:%s\n' "$actor"
    printf 'Reason:%s\n' "$reason"
    printf 'Current blocker:%s\n' "$current_blocker"
    printf 'Next handoff:%s\n' "$next_handoff"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
  } | sha256_value
}

transition_event_hash_from_values_v1() {
  work_item="$1"
  at="$2"
  from_status="$3"
  to_status="$4"
  actor="$5"
  reason="$6"
  current_blocker="$7"
  next_handoff="$8"
  prev_event="$9"
  prev_event_hash="${10}"
  operation_id="${11}"
  expected_from_status="${12}"
  expected_version="${13}"
  version_before="${14}"
  version_after="${15}"

  {
    printf 'Work Item:%s\n' "$work_item"
    printf 'At:%s\n' "$at"
    printf 'From:%s\n' "$from_status"
    printf 'To:%s\n' "$to_status"
    printf 'Actor:%s\n' "$actor"
    printf 'Reason:%s\n' "$reason"
    printf 'Current blocker:%s\n' "$current_blocker"
    printf 'Next handoff:%s\n' "$next_handoff"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
    printf 'Operation ID:%s\n' "$operation_id"
    printf 'Expected from:%s\n' "$expected_from_status"
    printf 'Expected version:%s\n' "$expected_version"
    printf 'Version before:%s\n' "$version_before"
    printf 'Version after:%s\n' "$version_after"
  } | sha256_value
}

transition_event_hash_from_values_v2() {
  work_item="$1"
  at="$2"
  from_status="$3"
  to_status="$4"
  actor="$5"
  reason="$6"
  current_blocker="$7"
  next_handoff="$8"
  prev_event="$9"
  prev_event_hash="${10}"
  operation_id="${11}"
  expected_from_status="${12}"
  expected_version="${13}"
  version_before="${14}"
  version_after="${15}"
  interrupt_marker="${16}"
  resume_target="${17}"

  {
    printf 'Work Item:%s\n' "$work_item"
    printf 'At:%s\n' "$at"
    printf 'From:%s\n' "$from_status"
    printf 'To:%s\n' "$to_status"
    printf 'Actor:%s\n' "$actor"
    printf 'Reason:%s\n' "$reason"
    printf 'Current blocker:%s\n' "$current_blocker"
    printf 'Next handoff:%s\n' "$next_handoff"
    printf 'Operation ID:%s\n' "$operation_id"
    printf 'Expected from:%s\n' "$expected_from_status"
    printf 'Expected version:%s\n' "$expected_version"
    printf 'Version before:%s\n' "$version_before"
    printf 'Version after:%s\n' "$version_after"
    printf 'Interrupt marker:%s\n' "$interrupt_marker"
    printf 'Resume target:%s\n' "$resume_target"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
  } | sha256_value
}

transition_event_hash_from_values_v3() {
  work_item="$1"
  at="$2"
  from_status="$3"
  to_status="$4"
  actor="$5"
  reason="$6"
  current_blocker="$7"
  next_handoff="$8"
  prev_event="$9"
  prev_event_hash="${10}"
  operation_id="${11}"
  expected_from_status="${12}"
  expected_version="${13}"
  version_before="${14}"
  version_after="${15}"
  interrupt_marker="${16}"
  resume_target="${17}"
  invoker="${18}"

  {
    printf 'Work Item:%s\n' "$work_item"
    printf 'At:%s\n' "$at"
    printf 'From:%s\n' "$from_status"
    printf 'To:%s\n' "$to_status"
    printf 'Actor:%s\n' "$actor"
    printf 'Reason:%s\n' "$reason"
    printf 'Current blocker:%s\n' "$current_blocker"
    printf 'Next handoff:%s\n' "$next_handoff"
    printf 'Operation ID:%s\n' "$operation_id"
    printf 'Expected from:%s\n' "$expected_from_status"
    printf 'Expected version:%s\n' "$expected_version"
    printf 'Version before:%s\n' "$version_before"
    printf 'Version after:%s\n' "$version_after"
    printf 'Interrupt marker:%s\n' "$interrupt_marker"
    printf 'Resume target:%s\n' "$resume_target"
    printf 'Invoker:%s\n' "$invoker"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
  } | sha256_value
}

transition_event_hash_from_values_v4() {
  work_item="$1"
  at="$2"
  from_status="$3"
  to_status="$4"
  actor="$5"
  reason="$6"
  event_type="$7"
  current_blocker="$8"
  next_handoff="$9"
  prev_event="${10}"
  prev_event_hash="${11}"
  operation_id="${12}"
  expected_from_status="${13}"
  expected_version="${14}"
  version_before="${15}"
  version_after="${16}"
  interrupt_marker="${17}"
  resume_target="${18}"
  invoker="${19}"

  {
    printf 'Work Item:%s\n' "$work_item"
    printf 'At:%s\n' "$at"
    printf 'From:%s\n' "$from_status"
    printf 'To:%s\n' "$to_status"
    printf 'Actor:%s\n' "$actor"
    printf 'Reason:%s\n' "$reason"
    printf 'Event type:%s\n' "$event_type"
    printf 'Current blocker:%s\n' "$current_blocker"
    printf 'Next handoff:%s\n' "$next_handoff"
    printf 'Operation ID:%s\n' "$operation_id"
    printf 'Expected from:%s\n' "$expected_from_status"
    printf 'Expected version:%s\n' "$expected_version"
    printf 'Version before:%s\n' "$version_before"
    printf 'Version after:%s\n' "$version_after"
    printf 'Interrupt marker:%s\n' "$interrupt_marker"
    printf 'Resume target:%s\n' "$resume_target"
    printf 'Invoker:%s\n' "$invoker"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
  } | sha256_value
}

transition_event_hash() {
  file="$1"
  operation_id=$(field_value "$file" "Operation ID")
  event_type=$(field_value_or_none "$file" "Event type")
  interrupt_marker=$(field_value "$file" "Interrupt marker")
  resume_target=$(field_value "$file" "Resume target")
  invoker=$(field_value "$file" "Invoker")

  if ! value_is_missing "$event_type"; then
    transition_event_hash_from_values_v4 \
      "$(field_value "$file" "Work Item")" \
      "$(field_value "$file" "At")" \
      "$(field_value "$file" "From")" \
      "$(field_value "$file" "To")" \
      "$(field_value "$file" "Actor")" \
      "$(field_value "$file" "Reason")" \
      "$(field_value_or_none "$file" "Event type")" \
      "$(field_value "$file" "Current blocker")" \
      "$(field_value "$file" "Next handoff")" \
      "$(field_value "$file" "Prev event")" \
      "$(field_value "$file" "Prev event hash")" \
      "$(field_value_or_none "$file" "Operation ID")" \
      "$(field_value_or_none "$file" "Expected from")" \
      "$(field_value_or_none "$file" "Expected version")" \
      "$(field_value_or_none "$file" "Version before")" \
      "$(field_value_or_none "$file" "Version after")" \
      "$(field_value_or_none "$file" "Interrupt marker")" \
      "$(field_value_or_none "$file" "Resume target")" \
      "$(field_value_or_none "$file" "Invoker")"
  elif [ -n "$invoker" ]; then
    transition_event_hash_from_values_v3 \
      "$(field_value "$file" "Work Item")" \
      "$(field_value "$file" "At")" \
      "$(field_value "$file" "From")" \
      "$(field_value "$file" "To")" \
      "$(field_value "$file" "Actor")" \
      "$(field_value "$file" "Reason")" \
      "$(field_value "$file" "Current blocker")" \
      "$(field_value "$file" "Next handoff")" \
      "$(field_value "$file" "Prev event")" \
      "$(field_value "$file" "Prev event hash")" \
      "$(field_value_or_none "$file" "Operation ID")" \
      "$(field_value_or_none "$file" "Expected from")" \
      "$(field_value_or_none "$file" "Expected version")" \
      "$(field_value_or_none "$file" "Version before")" \
      "$(field_value_or_none "$file" "Version after")" \
      "$(field_value_or_none "$file" "Interrupt marker")" \
      "$(field_value_or_none "$file" "Resume target")" \
      "$(field_value_or_none "$file" "Invoker")"
  elif [ -n "$interrupt_marker" ] || [ -n "$resume_target" ]; then
    transition_event_hash_from_values_v2 \
      "$(field_value "$file" "Work Item")" \
      "$(field_value "$file" "At")" \
      "$(field_value "$file" "From")" \
      "$(field_value "$file" "To")" \
      "$(field_value "$file" "Actor")" \
      "$(field_value "$file" "Reason")" \
      "$(field_value "$file" "Current blocker")" \
      "$(field_value "$file" "Next handoff")" \
      "$(field_value "$file" "Prev event")" \
      "$(field_value "$file" "Prev event hash")" \
      "$(field_value_or_none "$file" "Operation ID")" \
      "$(field_value_or_none "$file" "Expected from")" \
      "$(field_value_or_none "$file" "Expected version")" \
      "$(field_value_or_none "$file" "Version before")" \
      "$(field_value_or_none "$file" "Version after")" \
      "$(field_value_or_none "$file" "Interrupt marker")" \
      "$(field_value_or_none "$file" "Resume target")"
  elif ! value_is_missing "$operation_id"; then
    transition_event_hash_from_values_v1 \
      "$(field_value "$file" "Work Item")" \
      "$(field_value "$file" "At")" \
      "$(field_value "$file" "From")" \
      "$(field_value "$file" "To")" \
      "$(field_value "$file" "Actor")" \
      "$(field_value "$file" "Reason")" \
      "$(field_value "$file" "Current blocker")" \
      "$(field_value "$file" "Next handoff")" \
      "$(field_value "$file" "Prev event")" \
      "$(field_value "$file" "Prev event hash")" \
      "$operation_id" \
      "$(field_value "$file" "Expected from")" \
      "$(field_value "$file" "Expected version")" \
      "$(field_value "$file" "Version before")" \
      "$(field_value "$file" "Version after")"
  else
    transition_event_hash_from_values_legacy \
      "$(field_value "$file" "Work Item")" \
      "$(field_value "$file" "At")" \
      "$(field_value "$file" "From")" \
      "$(field_value "$file" "To")" \
      "$(field_value "$file" "Actor")" \
      "$(field_value "$file" "Reason")" \
      "$(field_value "$file" "Current blocker")" \
      "$(field_value "$file" "Next handoff")" \
      "$(field_value "$file" "Prev event")" \
      "$(field_value "$file" "Prev event hash")"
  fi
}

board_refresh_event_hash_from_values_v1() {
  at="$1"
  actor="$2"
  invoker="$3"
  targets="$4"
  prev_event="$5"
  prev_event_hash="$6"

  {
    printf 'At:%s\n' "$at"
    printf 'Actor:%s\n' "$actor"
    printf 'Invoker:%s\n' "$invoker"
    printf 'Targets:%s\n' "$targets"
    printf 'Prev event:%s\n' "$prev_event"
    printf 'Prev event hash:%s\n' "$prev_event_hash"
  } | sha256_value
}

board_refresh_event_hash() {
  file="$1"

  board_refresh_event_hash_from_values_v1 \
    "$(field_value "$file" "At")" \
    "$(field_value "$file" "Actor")" \
    "$(field_value "$file" "Invoker")" \
    "$(field_value "$file" "Targets")" \
    "$(field_value "$file" "Prev event")" \
    "$(field_value "$file" "Prev event hash")"
}

write_board_refresh_event() {
  targets="$1"
  actor="${2:-system}"
  invoker="${STATE_INVOKER:-none}"
  timestamp=$(date +%Y%m%dT%H%M%S)
  target="$state_board_refreshes_dir/BR-$timestamp.md"
  suffix=1
  at=$(date '+%F %T')
  prev_event=$(latest_board_refresh_event_path || true)

  ensure_state_dirs

  if [ -n "${prev_event:-}" ]; then
    prev_event_hash=$(field_value "$prev_event" "Event hash")
  else
    prev_event="none"
    prev_event_hash="none"
  fi

  while [ -e "$target" ]; do
    target="$state_board_refreshes_dir/BR-$timestamp-$suffix.md"
    suffix=$((suffix + 1))
  done

  event_hash=$(board_refresh_event_hash_from_values_v1 \
    "$at" \
    "$actor" \
    "$invoker" \
    "$targets" \
    "$prev_event" \
    "$prev_event_hash")

  cat >"$target" <<EOF
# Board Refresh Event

- At: $at
- Actor: $actor
- Invoker: $invoker
- Targets: $targets
- Prev event: $prev_event
- Prev event hash: $prev_event_hash
- Event hash: $event_hash
EOF

  printf '%s\n' "$target"
}

artifact_work_item_links() {
  artifact_path="$1"
  awk '
    index($0, "- Linked work items: ") == 1 {
      print substr($0, length("- Linked work items: ") + 1)
      exit
    }
    index($0, "- Linked work item: ") == 1 {
      print substr($0, length("- Linked work item: ") + 1)
      exit
    }
    index($0, "<!-- Linked work items: ") == 1 {
      value = substr($0, length("<!-- Linked work items: ") + 1)
      sub(/ -->$/, "", value)
      print value
      exit
    }
    index($0, "<!-- Linked work item: ") == 1 {
      value = substr($0, length("<!-- Linked work item: ") + 1)
      sub(/ -->$/, "", value)
      print value
      exit
    }
  ' "$artifact_path"
}

artifact_has_work_item_link() {
  artifact_path="$1"
  work_item_id="$2"
  links=$(artifact_work_item_links "$artifact_path")

  if value_is_missing "$links"; then
    return 1
  fi

  csv_contains_value "$links" "$work_item_id"
}

upsert_artifact_work_item_links() {
  artifact_path="$1"
  work_item_id="$2"
  current_links=$(artifact_work_item_links "$artifact_path")
  updated_links=""
  found=0

  if ! value_is_missing "$current_links"; then
    old_ifs=${IFS- }
    IFS=','
    set -- $current_links
    IFS=$old_ifs

    for raw_id in "$@"; do
      linked_id=$(trim "$raw_id")
      [ -n "$linked_id" ] || continue
      if [ "$linked_id" = "$work_item_id" ]; then
        found=1
      fi
      if [ -z "$updated_links" ]; then
        updated_links="$linked_id"
      else
        updated_links="${updated_links},$linked_id"
      fi
    done
  fi

  if [ "$found" -eq 0 ]; then
    if [ -z "$updated_links" ]; then
      updated_links="$work_item_id"
    else
      updated_links="${updated_links},$work_item_id"
    fi
  fi

  case "$artifact_path" in
    *.html)
      artifact_tmp=$(mktemp)
      awk -v links="$updated_links" '
        BEGIN {
          inserted = 0
        }
        index($0, "<!-- Linked work items: ") == 1 || index($0, "<!-- Linked work item: ") == 1 {
          if (!inserted) {
            print "<!-- Linked work items: " links " -->"
            inserted = 1
          }
          next
        }
        NR == 1 && $0 ~ /^<!DOCTYPE html>/ {
          print
          if (!inserted) {
            print "<!-- Linked work items: " links " -->"
            inserted = 1
          }
          next
        }
        {
          if (!inserted && NR == 1) {
            print "<!-- Linked work items: " links " -->"
            inserted = 1
          }
          print
        }
      ' "$artifact_path" >"$artifact_tmp"
      mv "$artifact_tmp" "$artifact_path"
      return 0
      ;;
  esac

  artifact_tmp=$(mktemp)
  awk -v links="$updated_links" '
    BEGIN {
      inserted = 0
    }
    index($0, "- Linked work items: ") == 1 || index($0, "- Linked work item: ") == 1 {
      if (!inserted) {
        print "- Linked work items: " links
        inserted = 1
      }
      next
    }
    NR == 1 {
      print
      next
    }
    !inserted {
      print ""
      print "- Linked work items: " links
      inserted = 1
    }
    { print }
  ' "$artifact_path" >"$artifact_tmp"
  mv "$artifact_tmp" "$artifact_path"
}

upsert_linked_artifact_entry() {
  work_item_file="$1"
  artifact_path="$2"
  artifact_type="$3"
  artifact_status="$4"
  entry="$artifact_path|$artifact_type|$artifact_status"
  existing_links=$(field_value "$work_item_file" "Linked artifacts")
  updated_links=""
  found=0

  if ! value_is_missing "$existing_links"; then
    old_ifs=${IFS- }
    IFS=';'
    set -- $existing_links
    IFS=$old_ifs

    for existing_entry in "$@"; do
      existing_entry=$(trim "$existing_entry")
      [ -n "$existing_entry" ] || continue
      existing_path=${existing_entry%%|*}
      if [ "$existing_path" = "$artifact_path" ]; then
        existing_entry="$entry"
        found=1
      fi
      if [ -z "$updated_links" ]; then
        updated_links="$existing_entry"
      else
        updated_links="${updated_links};$existing_entry"
      fi
    done
  fi

  if [ "$found" -eq 0 ]; then
    if [ -z "$updated_links" ]; then
      updated_links="$entry"
    else
      updated_links="${updated_links};$entry"
    fi
  fi

  replace_field "$work_item_file" "Linked artifacts" "$updated_links"
}

required_departments_satisfied() {
  file="$1"
  mode="$2"
  required_departments=$(field_value "$file" "Required departments")

  if value_is_missing "$required_departments"; then
    return 0
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $required_departments
  IFS=$old_ifs

  for raw_department in "$@"; do
    department=$(trim "$raw_department")
    [ -n "$department" ] || continue
    participation=$(department_participation "$file" "$department" 2>/dev/null || true)

    if [ -z "$participation" ]; then
      return 1
    fi

    case "$mode:$participation" in
      ready:required|ready:done) ;;
      done:done) ;;
      *) return 1 ;;
    esac
  done

  return 0
}

required_artifacts_satisfied() {
  file="$1"
  required_artifacts=$(field_value "$file" "Required artifacts")
  linked_artifacts=$(field_value "$file" "Linked artifacts")

  if value_is_missing "$required_artifacts"; then
    return 0
  fi

  if value_is_missing "$linked_artifacts"; then
    return 1
  fi

  required_ifs=$IFS
  IFS=','
  set -- $required_artifacts
  IFS=$required_ifs

  for raw_required_type in "$@"; do
    required_type=$(trim "$raw_required_type")
    [ -n "$required_type" ] || continue

    found=0
    artifact_ifs=$IFS
    IFS=';'
    set -- $linked_artifacts
    IFS=$artifact_ifs

    for raw_link in "$@"; do
      artifact_type=$(printf '%s\n' "$raw_link" | awk -F'\\|' '{print $2}')
      artifact_status=$(printf '%s\n' "$raw_link" | awk -F'\\|' '{print $3}')
      artifact_type=$(trim "$artifact_type")
      artifact_status=$(trim "$artifact_status")

      if [ "$artifact_type" = "$required_type" ]; then
        case "$artifact_status" in
          approved|active|superseded|archived)
            found=1
            break
            ;;
        esac
      fi
    done

    if [ "$found" -ne 1 ]; then
      return 1
    fi
  done

  return 0
}

write_transition_event() {
  id="$1"
  from_status="$2"
  to_status="$3"
  actor="${4:-system}"
  reason="${5:-none}"
  current_blocker="${6:-none}"
  next_handoff="${7:-none}"
  operation_id="${8:-none}"
  expected_from_status="${9:-none}"
  expected_version="${10:-none}"
  version_before="${11:-none}"
  version_after="${12:-none}"
  interrupt_marker="${13:-none}"
  resume_target="${14:-none}"
  event_type="${15:-none}"
  invoker="${STATE_INVOKER:-none}"
  timestamp=$(date +%Y%m%dT%H%M%S)
  slug="TX-$timestamp-$id-$from_status-to-$to_status"
  target="$state_transitions_dir/$slug.md"
  suffix=1
  at=$(date '+%F %T')
  prev_event=$(latest_transition_event_path "$id" || true)

  if [ -n "${prev_event:-}" ]; then
    prev_event_hash=$(field_value "$prev_event" "Event hash")
  else
    prev_event="none"
    prev_event_hash="none"
  fi

  while [ -e "$target" ]; do
    target="$state_transitions_dir/$slug-$suffix.md"
    suffix=$((suffix + 1))
  done

  if value_is_missing "$operation_id"; then
    event_hash=$(transition_event_hash_from_values_legacy \
      "$id" \
      "$at" \
      "$from_status" \
      "$to_status" \
      "$actor" \
      "$reason" \
      "$current_blocker" \
      "$next_handoff" \
      "$prev_event" \
      "$prev_event_hash")

    cat >"$target" <<EOF
# Transition Event

- Work Item: $id
- At: $at
- From: $from_status
- To: $to_status
- Actor: $actor
- Reason: $reason
- Current blocker: $current_blocker
- Next handoff: $next_handoff
- Prev event: $prev_event
- Prev event hash: $prev_event_hash
- Event hash: $event_hash
EOF
  elif ! value_is_missing "$event_type"; then
    event_hash=$(transition_event_hash_from_values_v4 \
      "$id" \
      "$at" \
      "$from_status" \
      "$to_status" \
      "$actor" \
      "$reason" \
      "$event_type" \
      "$current_blocker" \
      "$next_handoff" \
      "$prev_event" \
      "$prev_event_hash" \
      "$operation_id" \
      "$expected_from_status" \
      "$expected_version" \
      "$version_before" \
      "$version_after" \
      "$interrupt_marker" \
      "$resume_target" \
      "$invoker")

    cat >"$target" <<EOF
# Transition Event

- Work Item: $id
- At: $at
- From: $from_status
- To: $to_status
- Actor: $actor
- Reason: $reason
- Event type: $event_type
- Current blocker: $current_blocker
- Next handoff: $next_handoff
- Operation ID: $operation_id
- Expected from: $expected_from_status
- Expected version: $expected_version
- Version before: $version_before
- Version after: $version_after
- Interrupt marker: $interrupt_marker
- Resume target: $resume_target
- Invoker: $invoker
- Prev event: $prev_event
- Prev event hash: $prev_event_hash
- Event hash: $event_hash
EOF
  elif value_is_missing "$invoker"; then
    event_hash=$(transition_event_hash_from_values_v2 \
      "$id" \
      "$at" \
      "$from_status" \
      "$to_status" \
      "$actor" \
      "$reason" \
      "$current_blocker" \
      "$next_handoff" \
      "$prev_event" \
      "$prev_event_hash" \
      "$operation_id" \
      "$expected_from_status" \
      "$expected_version" \
      "$version_before" \
      "$version_after" \
      "$interrupt_marker" \
      "$resume_target")

    cat >"$target" <<EOF
# Transition Event

- Work Item: $id
- At: $at
- From: $from_status
- To: $to_status
- Actor: $actor
- Reason: $reason
- Current blocker: $current_blocker
- Next handoff: $next_handoff
- Operation ID: $operation_id
- Expected from: $expected_from_status
- Expected version: $expected_version
- Version before: $version_before
- Version after: $version_after
- Interrupt marker: $interrupt_marker
- Resume target: $resume_target
- Prev event: $prev_event
- Prev event hash: $prev_event_hash
- Event hash: $event_hash
EOF
  else
    event_hash=$(transition_event_hash_from_values_v3 \
      "$id" \
      "$at" \
      "$from_status" \
      "$to_status" \
      "$actor" \
      "$reason" \
      "$current_blocker" \
      "$next_handoff" \
      "$prev_event" \
      "$prev_event_hash" \
      "$operation_id" \
      "$expected_from_status" \
      "$expected_version" \
      "$version_before" \
      "$version_after" \
      "$interrupt_marker" \
      "$resume_target" \
      "$invoker")

    cat >"$target" <<EOF
# Transition Event

- Work Item: $id
- At: $at
- From: $from_status
- To: $to_status
- Actor: $actor
- Reason: $reason
- Current blocker: $current_blocker
- Next handoff: $next_handoff
- Operation ID: $operation_id
- Expected from: $expected_from_status
- Expected version: $expected_version
- Version before: $version_before
- Version after: $version_after
- Interrupt marker: $interrupt_marker
- Resume target: $resume_target
- Invoker: $invoker
- Prev event: $prev_event
- Prev event hash: $prev_event_hash
- Event hash: $event_hash
EOF
  fi

  printf '%s\n' "$target"
}
