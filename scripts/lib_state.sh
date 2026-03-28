#!/bin/sh
set -eu

if [ -n "${script_dir:-}" ] && [ -f "$script_dir/lib_harness_paths.sh" ]; then
  . "$script_dir/lib_harness_paths.sh"
  init_harness_paths "$script_dir"
fi

state_root=".harness/workspace/state"
state_boards_dir="$state_root/boards"
state_transitions_dir="$state_root/transitions"
state_board_refreshes_dir="$state_root/board-refreshes"
state_locks_dir=".harness/locks"
task_runtime_dir=".harness/tasks"
runtime_manifest_path=".harness/manifest.toml"
work_item_schema_version="2"
work_item_state_authority="script-only"
runtime_manifest_schema_version="1"
default_runtime_mode="minimum-core"

ensure_runtime_manifest() {
  manifest_dir=$(dirname "$runtime_manifest_path")
  mkdir -p "$manifest_dir"

  if [ -f "$runtime_manifest_path" ]; then
    return 0
  fi

  today=$(date +%F)
  cat >"$runtime_manifest_path" <<EOF
schema_version = $runtime_manifest_schema_version
runtime_mode = "$default_runtime_mode"
advanced_governance_enabled = false
created_at = "$today"
updated_at = "$today"
EOF
}

runtime_manifest_value() {
  key="$1"

  if [ ! -f "$runtime_manifest_path" ]; then
    return 1
  fi

  awk -F'=' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value = $2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$runtime_manifest_path"
}

runtime_governance_enabled() {
  runtime_mode=$(runtime_manifest_value "runtime_mode" || printf '%s\n' "$default_runtime_mode")
  advanced_governance_enabled=$(runtime_manifest_value "advanced_governance_enabled" || printf '%s\n' "false")

  if [ "$runtime_mode" = "advanced-governance" ] || [ "$advanced_governance_enabled" = "true" ]; then
    return 0
  fi

  return 1
}

ensure_core_runtime_dirs() {
  mkdir -p "$state_locks_dir" "$task_runtime_dir"
  ensure_runtime_manifest
}

ensure_governance_runtime_dirs() {
  :
}

ensure_state_dirs() {
  ensure_core_runtime_dirs

  if runtime_governance_enabled; then
    ensure_governance_runtime_dirs
  fi
}

ensure_boards_in_sync() {
  :
}

refresh_boards_if_enabled() {
  :
}

sync_recovery_snapshot_if_present() {
  :
}

now_iso_timestamp() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

linked_attachments_field_label() {
  printf '%s\n' "Linked attachments"
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

append_csv_value() {
  current="$1"
  value="$2"

  if value_is_missing "$current"; then
    printf '%s\n' "$value"
  else
    printf '%s,%s\n' "$current" "$value"
  fi
}

release_registered_locks() {
  acquired_locks="${STATE_ACQUIRED_LOCKS:-none}"

  if value_is_missing "$acquired_locks"; then
    return 0
  fi

  old_ifs=${IFS- }
  IFS=','
  set -- $acquired_locks
  IFS=$old_ifs

  for lock_name in "$@"; do
    lock_name=$(trim "$lock_name")
    [ -n "$lock_name" ] || continue
    lock_path="$state_locks_dir/$lock_name.lock"
    rm -f "$lock_path/pid" >/dev/null 2>&1 || true
    rmdir "$lock_path" >/dev/null 2>&1 || true
  done
}

register_lock_release_trap() {
  if [ "${STATE_LOCK_TRAP_REGISTERED:-0}" = "1" ]; then
    return 0
  fi

  trap '
    state_lock_release_rc=$?
    trap - EXIT HUP INT TERM
    release_registered_locks
    exit "$state_lock_release_rc"
  ' EXIT HUP INT TERM

  STATE_LOCK_TRAP_REGISTERED=1
  export STATE_LOCK_TRAP_REGISTERED
}

acquire_named_lock() {
  lock_name="$1"
  attempts="${2:-200}"
  wait_seconds="${3:-0.1}"
  held_locks="${STATE_HELD_LOCKS:-none}"

  ensure_state_dirs

  if ! value_is_missing "$held_locks" && csv_contains_value "$held_locks" "$lock_name"; then
    return 0
  fi

  lock_path="$state_locks_dir/$lock_name.lock"
  attempt=0

  while ! mkdir "$lock_path" 2>/dev/null; do
    stale_pid=""
    if [ -f "$lock_path/pid" ]; then
      stale_pid=$(cat "$lock_path/pid" 2>/dev/null || true)
    fi
    if is_nonnegative_integer "${stale_pid:-}" && ! kill -0 "$stale_pid" 2>/dev/null; then
      rm -f "$lock_path/pid" >/dev/null 2>&1 || true
      rmdir "$lock_path" >/dev/null 2>&1 || true
      continue
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$attempts" ]; then
      echo "timed out acquiring state lock: $lock_name" >&2
      return 1
    fi
    sleep "$wait_seconds"
  done

  printf '%s\n' "$$" >"$lock_path/pid"

  STATE_HELD_LOCKS=$(append_csv_value "${STATE_HELD_LOCKS:-none}" "$lock_name")
  STATE_ACQUIRED_LOCKS=$(append_csv_value "${STATE_ACQUIRED_LOCKS:-none}" "$lock_name")
  export STATE_HELD_LOCKS STATE_ACQUIRED_LOCKS
  register_lock_release_trap
}

acquire_work_item_lock() {
  work_item_id="$1"
  acquire_named_lock "work-item-$work_item_id"
}

acquire_runtime_lock() {
  acquire_named_lock "runtime-global"
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

default_harness_command() {
  script_name="$1"

  if command -v harness_command_path >/dev/null 2>&1 && [ "${HARNESS_PATHS_INITIALIZED:-0}" = "1" ]; then
    harness_command_path "$script_name"
    return 0
  fi

  printf './scripts/%s\n' "$script_name"
}

default_state_invoker() {
  script_path="${1:-}"
  script_name=$(basename "${script_path:-unknown}")
  default_harness_command "$script_name"
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
Last transition event
ID
Title
Type
Status
Priority
Owner
Sponsor
Assignee
Worktree
Claimed at
Claim expires at
Lease version
Objective
Ready criteria
Done criteria
Required artifacts
Current stage owner
Current stage role
Next gate
Founder escalation
Decision status
Review status
QA status
UAT status
Acceptance status
Why it matters
Decision needed
Deadline
Due review at
Blocked by
Blocks
Current blocker
Next handoff
Linked attachments
Interrupt marker
Resume target
Created at
Updated at
Archived at
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

default_work_item_tail() {
  cat <<'EOF'
## Summary

- fill-me

## Recovery

- Current focus: none
- Next command: none
- Recovery notes: none

## Workflow Notes

- none

## Signoff Notes

- none

## Attachment Notes

- none

## Transition Log

- none

## Notes

- none
EOF
}

work_item_tail_from_summary() {
  work_item_tail_source_file="$1"
  awk '
    BEGIN {
      found = 0
    }
    /^## Summary$/ {
      found = 1
    }
    found {
      print
    }
  ' "$work_item_tail_source_file"
}

work_item_snapshot_value_for_label() {
  work_item_snapshot_value_file="$1"
  work_item_snapshot_value_pair_file="$2"
  work_item_snapshot_value_label="$3"

  if [ -f "$work_item_snapshot_value_pair_file" ]; then
    while IFS=$(printf '\t') read -r snapshot_pair_label snapshot_pair_value; do
      if [ "$snapshot_pair_label" = "$work_item_snapshot_value_label" ]; then
        printf '%s\n' "$snapshot_pair_value"
        return 0
      fi
    done <"$work_item_snapshot_value_pair_file"
  fi

  field_value "$work_item_snapshot_value_file" "$work_item_snapshot_value_label"
}

rewrite_work_item_header_snapshot() {
  rewrite_work_item_snapshot_file="$1"
  shift

  if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    echo "rewrite_work_item_header_snapshot requires label/value pairs" >&2
    return 1
  fi

  if ! work_item_header_schema_matches "$rewrite_work_item_snapshot_file"; then
    echo "work item header schema mismatch: $rewrite_work_item_snapshot_file" >&2
    return 1
  fi

  rewrite_work_item_pair_file=$(mktemp)
  rewrite_work_item_labels_file=$(mktemp)
  rewrite_work_item_tail_file=$(mktemp)
  rewrite_work_item_tmp=$(mktemp)

  while [ "$#" -gt 0 ]; do
    printf '%s\t%s\n' "$1" "$2" >>"$rewrite_work_item_pair_file"
    shift 2
  done

  work_item_header_labels >"$rewrite_work_item_labels_file"
  work_item_tail_from_summary "$rewrite_work_item_snapshot_file" >"$rewrite_work_item_tail_file"

  if [ ! -s "$rewrite_work_item_tail_file" ]; then
    default_work_item_tail >"$rewrite_work_item_tail_file"
  fi

  {
    printf '# Work Item\n\n'
    while IFS= read -r rewrite_work_item_label; do
      rewrite_work_item_value=$(work_item_snapshot_value_for_label \
        "$rewrite_work_item_snapshot_file" \
        "$rewrite_work_item_pair_file" \
        "$rewrite_work_item_label")
      printf -- '- %s: %s\n' "$rewrite_work_item_label" "$rewrite_work_item_value"
    done <"$rewrite_work_item_labels_file"
    printf '\n'
    cat "$rewrite_work_item_tail_file"
  } >"$rewrite_work_item_tmp"

  rm -f "$rewrite_work_item_pair_file" "$rewrite_work_item_labels_file" "$rewrite_work_item_tail_file"
  mv "$rewrite_work_item_tmp" "$rewrite_work_item_snapshot_file"
}

field_value() {
  field_value_file="$1"
  field_value_label="$2"
  value=$(
    awk -v label="$field_value_label" '
    index($0, "- " label ": ") == 1 {
      print substr($0, length("- " label ": ") + 1)
      exit
    }
  ' "$field_value_file"
  )

  if [ -n "$value" ]; then
    printf '%s\n' "$value"
    return 0
  fi

  return 0
}

field_value_or_none() {
  field_value_or_none_file="$1"
  field_value_or_none_label="$2"
  field_value_or_none_value=$(field_value "$field_value_or_none_file" "$field_value_or_none_label")

  if [ -n "$field_value_or_none_value" ]; then
    printf '%s\n' "$field_value_or_none_value"
  else
    printf '%s\n' "none"
  fi
}

replace_field() {
  replace_field_file="$1"
  replace_field_label="$2"
  replace_field_value="$3"
  replace_field_tmp=$(mktemp)
  awk -v label="$replace_field_label" -v value="$replace_field_value" '
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
  ' "$replace_field_file" >"$replace_field_tmp" || {
    rc=$?
    rm -f "$replace_field_tmp"
    return "$rc"
  }
  mv "$replace_field_tmp" "$replace_field_file"
}

replace_fields_atomic() {
  replace_fields_atomic_file="$1"
  shift

  if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    echo "replace_fields_atomic requires label/value pairs" >&2
    return 1
  fi

  replace_fields_atomic_pair_file=$(mktemp)
  replace_fields_atomic_tmp=$(mktemp)

  while [ "$#" -gt 0 ]; do
    printf '%s\t%s\n' "$1" "$2" >>"$replace_fields_atomic_pair_file"
    shift 2
  done

  awk -v pair_file="$replace_fields_atomic_pair_file" '
    BEGIN {
      expected = 0
      while ((getline line < pair_file) > 0) {
        split(line, parts, "\t")
        label = parts[1]
        value = line
        sub(/^[^\t]*\t/, "", value)
        replacements[label] = value
        expected++
      }
      close(pair_file)
    }
    {
      for (label in replacements) {
        prefix = "- " label ": "
        if (index($0, prefix) == 1 && !(label in updated)) {
          print prefix replacements[label]
          updated[label] = 1
          next
        }
      }
      print
    }
    END {
      count = 0
      for (label in updated) {
        count++
      }
      if (count != expected) {
        exit 2
      }
    }
  ' "$replace_fields_atomic_file" >"$replace_fields_atomic_tmp" || {
    rc=$?
    rm -f "$replace_fields_atomic_pair_file" "$replace_fields_atomic_tmp"
    return "$rc"
  }

  rm -f "$replace_fields_atomic_pair_file"
  mv "$replace_fields_atomic_tmp" "$replace_fields_atomic_file"
}

section_field_value() {
  section_field_value_file="$1"
  section_heading="$2"
  section_label="$3"

  awk -v heading="## $section_heading" -v label="$section_label" '
    BEGIN {
      in_section = 0
    }
    $0 == heading {
      in_section = 1
      next
    }
    in_section && /^## / {
      exit
    }
    in_section && index($0, "- " label ": ") == 1 {
      print substr($0, length("- " label ": ") + 1)
      exit
    }
  ' "$section_field_value_file"
}

rewrite_markdown_section() {
  rewrite_section_file="$1"
  rewrite_section_heading="$2"
  rewrite_section_body_file="$3"
  rewrite_section_tmp=$(mktemp)

  awk -v heading="## $rewrite_section_heading" -v body_file="$rewrite_section_body_file" '
    function emit_body(   i) {
      for (i = 1; i <= body_count; i++) {
        print body[i]
      }
    }
    BEGIN {
      body_count = 0
      while ((getline line < body_file) > 0) {
        body[++body_count] = line
      }
      close(body_file)
      in_section = 0
      replaced = 0
    }
    $0 == heading {
      print $0
      emit_body()
      in_section = 1
      replaced = 1
      next
    }
    in_section {
      if ($0 ~ /^## /) {
        in_section = 0
        print $0
      }
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        if (NR > 0) {
          print ""
        }
        print heading
        emit_body()
      }
    }
  ' "$rewrite_section_file" >"$rewrite_section_tmp"

  mv "$rewrite_section_tmp" "$rewrite_section_file"
}

recovery_field_value_or_none() {
  recovery_file="$1"
  recovery_label="$2"
  recovery_value=$(section_field_value "$recovery_file" "Recovery" "$recovery_label")

  if [ -n "$recovery_value" ]; then
    printf '%s\n' "$recovery_value"
  else
    printf '%s\n' "none"
  fi
}

rewrite_work_item_recovery_section() {
  recovery_file="$1"
  current_focus="$2"
  next_command="$3"
  recovery_notes="$4"
  recovery_body=$(mktemp)

  cat >"$recovery_body" <<EOF
- Current focus: $current_focus
- Next command: $next_command
- Recovery notes: $recovery_notes
EOF

  rewrite_markdown_section "$recovery_file" "Recovery" "$recovery_body"
  rm -f "$recovery_body"
}

next_work_item_id() {
  ensure_state_dirs
  max=0
  for file in $(list_work_items); do
    [ -f "$file" ] || continue
    base=$(basename "$(dirname "$file")")
    case "$base" in
      WI-*) ;;
      *)
        base=$(basename "$file" .md)
        ;;
    esac
    num=$(printf '%s' "$base" | sed 's/^WI-0*//')
    [ -n "$num" ] || num=0
    if [ "$num" -gt "$max" ]; then
      max=$num
    fi
  done
  next=$((max + 1))
  printf 'WI-%04d\n' "$next"
}

canonical_work_item_dir() {
  id="$1"
  printf '%s/%s\n' "$task_runtime_dir" "$id"
}

canonical_work_item_path() {
  id="$1"
  printf '%s/task.md\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_refs_dir() {
  id="$1"
  printf '%s/refs\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_attachments_dir() {
  id="$1"
  printf '%s/attachments\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_attachment_sources_dir() {
  id="$1"
  printf '%s/sources\n' "$(canonical_work_item_attachments_dir "$id")"
}

canonical_work_item_working_dir() {
  id="$1"
  printf '%s/working\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_outputs_dir() {
  id="$1"
  printf '%s/outputs\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_closure_dir() {
  id="$1"
  printf '%s/closure\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_history_dir() {
  id="$1"
  printf '%s/history\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_transition_dir() {
  id="$1"
  printf '%s/transitions\n' "$(canonical_work_item_history_dir "$id")"
}

work_item_path() {
  id="$1"
  printf '%s\n' "$(canonical_work_item_path "$id")"
}

require_work_item_for_write() {
  id="$1"
  canonical_path=$(canonical_work_item_path "$id")

  if [ -f "$canonical_path" ]; then
    ensure_core_runtime_dirs
    ensure_task_directory_skeleton "$id"
    printf '%s\n' "$canonical_path"
    return 0
  fi

  echo "missing work item: $id" >&2
  return 1
}

work_item_recovery_path() {
  id="$1"
  printf '%s\n' "$(canonical_work_item_path "$id")"
}

work_item_recovery_path_for_write() {
  id="$1"
  require_work_item_for_write "$id" >/dev/null
  printf '%s\n' "$(canonical_work_item_path "$id")"
}

ensure_task_directory_skeleton() {
  id="$1"
  task_dir=$(canonical_work_item_dir "$id")
  mkdir -p \
    "$task_dir/attachments" \
    "$task_dir/attachments/sources" \
    "$task_dir/outputs" \
    "$task_dir/closure" \
    "$task_dir/history/transitions"
}

list_work_item_transition_events() {
  id="$1"
  canonical_transition_dir=$(canonical_work_item_transition_dir "$id")

  if [ -d "$canonical_transition_dir" ]; then
    find "$canonical_transition_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort
  fi
}

list_transition_events() {
  if [ -d "$task_runtime_dir" ]; then
    find "$task_runtime_dir" -mindepth 4 -maxdepth 4 -type f -path '*/history/transitions/TX-*.md' | sort
  fi
}

first_open_work_item_id() {
  for file in $(list_work_items); do
    [ -f "$file" ] || continue
    status=$(field_value "$file" "Status")
    if is_open_work_item_status "$status"; then
      field_value "$file" "ID"
      return 0
    fi
  done

  return 1
}

resolve_task_artifact_work_item_id() {
  requested_id="${1:-}"

  if [ -n "$requested_id" ]; then
    require_work_item "$requested_id" >/dev/null
    printf '%s\n' "$requested_id"
    return 0
  fi

  return 1
}

require_governance_mode_for_workspace_artifact() {
  artifact_kind="$1"

  if runtime_governance_enabled; then
    return 0
  fi

  cat >&2 <<EOF
$artifact_kind requires a work-item context in minimum-core runtime.
Pass --work-item <WI-xxxx> explicitly.
Workspace-scoped shared artifacts are only allowed when shared writeback is enabled.
EOF
  return 1
}

require_advanced_governance_runtime_artifact() {
  artifact_kind="$1"

  if runtime_governance_enabled; then
    return 0
  fi

cat >&2 <<EOF
$artifact_kind belongs to shared writeback mode.
Enable shared writeback mode before writing workspace-scoped cadence artifacts.
EOF
  return 1
}

require_explicit_promotion_for_workspace_artifact() {
  artifact_kind="$1"

cat >&2 <<EOF
$artifact_kind defaults to task-local routing.
Pass --work-item <WI-xxxx> explicitly.
Use --promote-governance only when this artifact truly needs cross-task visibility in shared writeback mode.
EOF
  return 1
}

work_item_matches_scope() {
  file="$1"
  scope="$2"
  founder_escalation=$(field_value "$file" "Founder escalation")
  interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")

  case "$scope" in
    company)
      return 0
      ;;
    founder)
      [ "$founder_escalation" = "pending-founder" ] || [ "$interrupt_marker" = "founder-review-required" ]
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

work_item_recovery_sync_state() {
  id="$1"
  work_item_file=$(require_work_item "$id")
  current_focus=$(recovery_field_value_or_none "$work_item_file" "Current focus")
  next_command=$(recovery_field_value_or_none "$work_item_file" "Next command")
  recovery_notes=$(recovery_field_value_or_none "$work_item_file" "Recovery notes")

  if value_is_missing "$current_focus" && value_is_missing "$next_command" && value_is_missing "$recovery_notes"; then
    printf '%s\n' "missing"
    return 0
  fi

  printf '%s\n' "current"
}

work_item_has_transition_events() {
  id="$1"
  list_work_item_transition_events "$id" | grep -q .
}

latest_transition_event_path() {
  id="$1"
  list_work_item_transition_events "$id" | tail -n 1
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
    backlog|planning|ready|in-progress|review|done|paused|killed|archived) return 0 ;;
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

is_valid_gate_status() {
  case "$1" in
    none|pending|approved|rejected|not-needed) return 0 ;;
    *) return 1 ;;
  esac
}

is_iso_timestamp_or_none() {
  value="$1"
  case "$value" in
    none|????-??-??T??:??:??* ) return 0 ;;
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
    none|backlog|planning|ready|in-progress|review) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_trace_event_type() {
  case "$1" in
    state-transition|artifact-link|approval-pause|resume|field-update|terminal-cleanup|schema-migration|blocker-release|board-refresh) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_type() {
  case "$1" in
    vision|governance|company-init|research|demo) return 0 ;;
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
    *)
      return 1
      ;;
  esac
}

transition_allowed() {
  current="$1"
  next="$2"
  case "$current:$next" in
    backlog:planning|backlog:paused|backlog:killed) return 0 ;;
    planning:ready|planning:backlog|planning:paused|planning:killed) return 0 ;;
    ready:in-progress|ready:planning|ready:paused|ready:killed) return 0 ;;
    in-progress:review|in-progress:planning|in-progress:paused|in-progress:killed) return 0 ;;
    review:done|review:planning|review:paused|review:killed) return 0 ;;
    paused:backlog|paused:planning|paused:ready|paused:in-progress|paused:review|paused:killed) return 0 ;;
    done:archived|killed:archived) return 0 ;;
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
    paused:backlog|paused:planning|paused:ready|paused:in-progress|paused:review)
      printf '%s\n' "resume"
      ;;
    *)
      printf '%s\n' "state-transition"
      ;;
  esac
}

is_open_work_item_status() {
  case "$1" in
    backlog|planning|ready|in-progress|review|paused) return 0 ;;
    *) return 1 ;;
  esac
}

default_stage_role_for_status() {
  case "$1" in
    backlog) printf '%s\n' "triage" ;;
    planning) printf '%s\n' "planner" ;;
    ready) printf '%s\n' "dispatcher" ;;
    in-progress) printf '%s\n' "executor" ;;
    review) printf '%s\n' "reviewer" ;;
    paused) printf '%s\n' "paused" ;;
    done|killed) printf '%s\n' "closer" ;;
    archived) printf '%s\n' "archive" ;;
    *) printf '%s\n' "none" ;;
  esac
}

default_next_gate_for_status() {
  case "$1" in
    backlog) printf '%s\n' "planning" ;;
    planning) printf '%s\n' "ready" ;;
    ready) printf '%s\n' "in-progress" ;;
    in-progress) printf '%s\n' "review" ;;
    review) printf '%s\n' "acceptance" ;;
    paused) printf '%s\n' "resume" ;;
    done|killed) printf '%s\n' "archive" ;;
    archived) printf '%s\n' "none" ;;
    *) printf '%s\n' "none" ;;
  esac
}

default_stage_owner_for_status() {
  stage_owner_file="$1"
  stage_owner_status="$2"
  stage_owner_actor="${3:-none}"
  owner=$(field_value_or_none "$stage_owner_file" "Owner")
  assignee=$(field_value_or_none "$stage_owner_file" "Assignee")

  case "$stage_owner_status" in
    in-progress|paused)
      if ! value_is_missing "$assignee"; then
        printf '%s\n' "$assignee"
      elif ! value_is_missing "$stage_owner_actor"; then
        printf '%s\n' "$stage_owner_actor"
      else
        printf '%s\n' "$owner"
      fi
      ;;
    *)
      if ! value_is_missing "$owner"; then
        printf '%s\n' "$owner"
      elif ! value_is_missing "$stage_owner_actor"; then
        printf '%s\n' "$stage_owner_actor"
      else
        printf '%s\n' "none"
      fi
      ;;
  esac
}

list_work_items() {
  if [ -d "$task_runtime_dir" ]; then
    find "$task_runtime_dir" -mindepth 2 -maxdepth 2 -type f -name 'task.md' | sort
  fi
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

first_linked_artifact_path() {
  first_linked_artifact_path_file="$1"
  first_linked_artifact_path_links=$(field_value "$first_linked_artifact_path_file" "Linked attachments")
  case "$first_linked_artifact_path_links" in
    ""|none) printf '%s\n' "-" ;;
    *)
      first_linked_artifact_path_first=${first_linked_artifact_path_links%%;*}
      printf '%s\n' "${first_linked_artifact_path_first%%|*}"
      ;;
  esac
}

linked_artifact_entry_for_path() {
  linked_artifact_entry_work_item_file="$1"
  linked_artifact_entry_artifact_path="$2"
  linked_artifact_entry_links=$(field_value "$linked_artifact_entry_work_item_file" "Linked attachments")

  if value_is_missing "$linked_artifact_entry_links"; then
    return 1
  fi

  old_ifs=${IFS- }
  IFS=';'
  set -- $linked_artifact_entry_links
  IFS=$old_ifs

  for linked_artifact_entry_existing_entry in "$@"; do
    linked_artifact_entry_existing_entry=$(trim "$linked_artifact_entry_existing_entry")
    [ -n "$linked_artifact_entry_existing_entry" ] || continue
    linked_artifact_entry_existing_path=${linked_artifact_entry_existing_entry%%|*}
    if [ "$linked_artifact_entry_existing_path" = "$linked_artifact_entry_artifact_path" ]; then
      printf '%s\n' "$linked_artifact_entry_existing_entry"
      return 0
    fi
  done

  return 1
}

linked_artifact_type_for_path() {
  linked_artifact_type_work_item_file="$1"
  linked_artifact_type_artifact_path="$2"
  linked_artifact_type_entry=$(linked_artifact_entry_for_path "$linked_artifact_type_work_item_file" "$linked_artifact_type_artifact_path" || true)

  if [ -z "$linked_artifact_type_entry" ]; then
    return 1
  fi

  linked_artifact_type_remainder=${linked_artifact_type_entry#*|}
  printf '%s\n' "${linked_artifact_type_remainder%%|*}"
}

linked_artifact_status_for_path() {
  linked_artifact_status_work_item_file="$1"
  linked_artifact_status_artifact_path="$2"
  linked_artifact_status_entry=$(linked_artifact_entry_for_path "$linked_artifact_status_work_item_file" "$linked_artifact_status_artifact_path" || true)

  if [ -z "$linked_artifact_status_entry" ]; then
    return 1
  fi

  linked_artifact_status_remainder=${linked_artifact_status_entry#*|}
  linked_artifact_status_remainder=${linked_artifact_status_remainder#*|}
  printf '%s\n' "$linked_artifact_status_remainder"
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

toml_escape() {
  printf '%s\n' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
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
  artifact_work_item_links_artifact_path="$1"
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
  ' "$artifact_work_item_links_artifact_path"
}

artifact_has_work_item_link() {
  artifact_has_work_item_link_artifact_path="$1"
  artifact_has_work_item_link_work_item_id="$2"
  artifact_has_work_item_link_links=$(artifact_work_item_links "$artifact_has_work_item_link_artifact_path")

  if value_is_missing "$artifact_has_work_item_link_links"; then
    return 1
  fi

  csv_contains_value "$artifact_has_work_item_link_links" "$artifact_has_work_item_link_work_item_id"
}

upsert_artifact_work_item_links() {
  artifact_path="$1"
  work_item_id="$2"
  current_links=$(artifact_work_item_links "$artifact_path")
  updated_work_item_links=""
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
      if [ -z "$updated_work_item_links" ]; then
        updated_work_item_links="$linked_id"
      else
        updated_work_item_links="${updated_work_item_links},$linked_id"
      fi
    done
  fi

  if [ "$found" -eq 0 ]; then
    if [ -z "$updated_work_item_links" ]; then
      updated_work_item_links="$work_item_id"
    else
      updated_work_item_links="${updated_work_item_links},$work_item_id"
    fi
  fi

  case "$artifact_path" in
    *.html)
      artifact_tmp=$(mktemp)
      awk -v links="$updated_work_item_links" '
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
  awk -v links="$updated_work_item_links" '
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

updated_linked_artifacts_value() {
  linked_artifacts_existing_links="$1"
  linked_artifacts_artifact_path="$2"
  linked_artifacts_artifact_type="$3"
  linked_artifacts_artifact_status="$4"
  linked_artifacts_entry="$linked_artifacts_artifact_path|$linked_artifacts_artifact_type|$linked_artifacts_artifact_status"
  linked_artifacts_updated_links=""
  linked_artifacts_found=0

  if ! value_is_missing "$linked_artifacts_existing_links"; then
    old_ifs=${IFS- }
    IFS=';'
    set -- $linked_artifacts_existing_links
    IFS=$old_ifs

    for linked_artifacts_existing_entry in "$@"; do
      linked_artifacts_existing_entry=$(trim "$linked_artifacts_existing_entry")
      [ -n "$linked_artifacts_existing_entry" ] || continue
      linked_artifacts_existing_path=${linked_artifacts_existing_entry%%|*}
      if [ "$linked_artifacts_existing_path" = "$linked_artifacts_artifact_path" ]; then
        linked_artifacts_existing_entry="$linked_artifacts_entry"
        linked_artifacts_found=1
      fi
      if [ -z "$linked_artifacts_updated_links" ]; then
        linked_artifacts_updated_links="$linked_artifacts_existing_entry"
      else
        linked_artifacts_updated_links="${linked_artifacts_updated_links};$linked_artifacts_existing_entry"
      fi
    done
  fi

  if [ "$linked_artifacts_found" -eq 0 ]; then
    if [ -z "$linked_artifacts_updated_links" ]; then
      linked_artifacts_updated_links="$linked_artifacts_entry"
    else
      linked_artifacts_updated_links="${linked_artifacts_updated_links};$linked_artifacts_entry"
    fi
  fi

  printf '%s\n' "$linked_artifacts_updated_links"
}

upsert_linked_artifact_entry() {
  work_item_file="$1"
  artifact_path="$2"
  artifact_type="$3"
  artifact_status="$4"
  existing_links=$(field_value "$work_item_file" "Linked attachments")
  updated_links=$(updated_linked_artifacts_value "$existing_links" "$artifact_path" "$artifact_type" "$artifact_status")
  rewrite_work_item_header_snapshot "$work_item_file" "Linked attachments" "$updated_links"
}

upsert_task_ref_index_entry() {
  work_item_id="$1"
  artifact_path="$2"
  artifact_type="$3"
  artifact_status="$4"
  refs_dir=$(canonical_work_item_refs_dir "$work_item_id")

  case "$artifact_path" in
    "$refs_dir"/*) ;;
    *)
      return 0
      ;;
  esac

  ensure_task_directory_skeleton "$work_item_id"
  refs_index="$refs_dir/index.toml"
  tmp=$(mktemp)
  escaped_path=$(toml_escape "$artifact_path")
  escaped_type=$(toml_escape "$artifact_type")
  escaped_status=$(toml_escape "$artifact_status")
  updated_at=$(date +%F)

  awk -v path="$artifact_path" '
    BEGIN {
      RS = ""
      ORS = "\n\n"
    }
    NR == 1 {
      print
      next
    }
    {
      if (index($0, "path = \"" path "\"") > 0) {
        next
      }
      print
    }
  ' "$refs_index" >"$tmp"

  {
    cat "$tmp"
    printf '[[refs]]\n'
    printf 'path = "%s"\n' "$escaped_path"
    printf 'type = "%s"\n' "$escaped_type"
    printf 'status = "%s"\n' "$escaped_status"
    printf 'updated_at = "%s"\n' "$updated_at"
  } >"$refs_index"

  rm -f "$tmp"
}

required_artifacts_satisfied() {
  file="$1"
  required_artifacts=$(field_value "$file" "Required artifacts")
  linked_artifacts=$(field_value "$file" "Linked attachments")

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
  transition_dir=$(canonical_work_item_transition_dir "$id")
  target="$transition_dir/$slug.md"
  suffix=1
  at=$(date '+%F %T')
  ensure_core_runtime_dirs
  ensure_task_directory_skeleton "$id"
  mkdir -p "$transition_dir"
  prev_event=$(latest_transition_event_path "$id" || true)

  if [ -n "${prev_event:-}" ]; then
    prev_event_hash=$(field_value "$prev_event" "Event hash")
  else
    prev_event="none"
    prev_event_hash="none"
  fi

  while [ -e "$target" ]; do
    target="$transition_dir/$slug-$suffix.md"
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
