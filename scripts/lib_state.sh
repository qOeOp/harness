#!/bin/sh
set -eu

if [ -n "${script_dir:-}" ] && [ -f "$script_dir/lib_harness_paths.sh" ]; then
  . "$script_dir/lib_harness_paths.sh"
  init_harness_paths "$script_dir"
fi

state_root=".harness/workspace/state"
state_items_dir="$state_root/items"
state_boards_dir="$state_root/boards"
state_progress_dir="$state_root/progress"
state_transitions_dir="$state_root/transitions"
state_board_refreshes_dir="$state_root/board-refreshes"
state_locks_dir=".harness/locks"
task_runtime_dir=".harness/tasks"
current_task_pointer_path=".harness/current-task"
runtime_manifest_path=".harness/manifest.toml"
work_item_schema_version="1"
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

ensure_legacy_compat_readme_if_present() {
  legacy_compat_dir="$1"
  legacy_compat_title="$2"
  legacy_compat_canonical_path="$3"

  if [ ! -d "$legacy_compat_dir" ]; then
    return 0
  fi

  cat >"$legacy_compat_dir/README.md" <<EOF
# $legacy_compat_title

- Compatibility only: true
- Runtime writes allowed: false
- Canonical path: $legacy_compat_canonical_path
- Purpose: migration fallback for legacy readers during task state cutover
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
  mkdir -p "$state_locks_dir" "$task_runtime_dir" ".harness/archive/tasks"
  ensure_runtime_manifest
  ensure_legacy_compat_readme_if_present "$state_items_dir" "Legacy Work Item Compatibility Mirror" ".harness/tasks/<WI-ID>/task.md"
  ensure_legacy_compat_readme_if_present "$state_progress_dir" "Legacy Progress Compatibility Mirror" ".harness/tasks/<WI-ID>/progress.md"
}

ensure_governance_runtime_dirs() {
  mkdir -p "$state_boards_dir" "$state_board_refreshes_dir"
}

ensure_state_dirs() {
  ensure_core_runtime_dirs

  if runtime_governance_enabled; then
    ensure_governance_runtime_dirs
  fi
}

ensure_boards_in_sync() {
  if ! runtime_governance_enabled; then
    return 0
  fi

  if [ "${STATE_SKIP_BOARD_SYNC:-0}" = "1" ]; then
    return 0
  fi

  if "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1; then
    return 0
  fi

  "$script_dir/refresh_boards.sh" >/dev/null
  "$script_dir/refresh_boards.sh" --check >/dev/null 2>&1
}

refresh_boards_if_enabled() {
  if ! runtime_governance_enabled; then
    return 0
  fi

  "$script_dir/refresh_boards.sh" >/dev/null
}

sync_progress_snapshot_if_present() {
  work_item_file="$1"
  work_item_id=$(field_value "$work_item_file" "ID")
  progress_path=$(work_item_progress_path "$work_item_id")

  if [ ! -f "$progress_path" ]; then
    return 0
  fi

  rewrite_progress_snapshot_file "$progress_path" \
    "Updated at" "$(date +%F)" \
    "Status snapshot" "$(field_value "$work_item_file" "Status")" \
    "State version snapshot" "$(field_value "$work_item_file" "State version")" \
    "Last operation ID snapshot" "$(field_value "$work_item_file" "Last operation ID")"
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

progress_header_labels() {
  cat <<'EOF'
Linked work items
Work Item
Created at
Updated at
Status snapshot
State version snapshot
Last operation ID snapshot
Current focus
Next command
Recovery notes
EOF
}

default_work_item_tail() {
  cat <<'EOF'
## Summary

- fill-me

## Notes
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

progress_tail_after_recovery_notes() {
  progress_tail_source_file="$1"
  awk '
    BEGIN {
      found = 0
    }
    /^- Recovery notes: / {
      found = 1
      next
    }
    found {
      print
    }
  ' "$progress_tail_source_file"
}

progress_snapshot_value_for_label() {
  progress_snapshot_value_file="$1"
  progress_snapshot_value_pair_file="$2"
  progress_snapshot_value_label="$3"

  if [ -f "$progress_snapshot_value_pair_file" ]; then
    while IFS=$(printf '\t') read -r progress_pair_label progress_pair_value; do
      if [ "$progress_pair_label" = "$progress_snapshot_value_label" ]; then
        printf '%s\n' "$progress_pair_value"
        return 0
      fi
    done <"$progress_snapshot_value_pair_file"
  fi

  if [ -f "$progress_snapshot_value_file" ]; then
    field_value "$progress_snapshot_value_file" "$progress_snapshot_value_label"
    return 0
  fi

  printf '\n'
}

rewrite_progress_snapshot_file() {
  rewrite_progress_snapshot_target_file="$1"
  shift

  if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    echo "rewrite_progress_snapshot_file requires label/value pairs" >&2
    return 1
  fi

  rewrite_progress_pair_file=$(mktemp)
  rewrite_progress_labels_file=$(mktemp)
  rewrite_progress_tail_file=$(mktemp)
  rewrite_progress_tmp=$(mktemp)

  while [ "$#" -gt 0 ]; do
    printf '%s\t%s\n' "$1" "$2" >>"$rewrite_progress_pair_file"
    shift 2
  done

  progress_header_labels >"$rewrite_progress_labels_file"

  if [ -f "$rewrite_progress_snapshot_target_file" ]; then
    progress_tail_after_recovery_notes "$rewrite_progress_snapshot_target_file" >"$rewrite_progress_tail_file"
  else
    : >"$rewrite_progress_tail_file"
  fi

  {
    printf '# Work Item Progress\n\n'
    while IFS= read -r rewrite_progress_label; do
      rewrite_progress_value=$(progress_snapshot_value_for_label \
        "$rewrite_progress_snapshot_target_file" \
        "$rewrite_progress_pair_file" \
        "$rewrite_progress_label")
      printf -- '- %s: %s\n' "$rewrite_progress_label" "$rewrite_progress_value"
    done <"$rewrite_progress_labels_file"
    if [ -s "$rewrite_progress_tail_file" ]; then
      printf '\n'
      cat "$rewrite_progress_tail_file"
    fi
  } >"$rewrite_progress_tmp"

  rm -f "$rewrite_progress_pair_file" "$rewrite_progress_labels_file" "$rewrite_progress_tail_file"
  mv "$rewrite_progress_tmp" "$rewrite_progress_snapshot_target_file"
}

field_value() {
  field_value_file="$1"
  field_value_label="$2"
  awk -v label="$field_value_label" '
    index($0, "- " label ": ") == 1 {
      print substr($0, length("- " label ": ") + 1)
      exit
    }
  ' "$field_value_file"
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

canonical_work_item_working_dir() {
  id="$1"
  printf '%s/working\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_outputs_dir() {
  id="$1"
  printf '%s/outputs\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_history_dir() {
  id="$1"
  printf '%s/history\n' "$(canonical_work_item_dir "$id")"
}

canonical_work_item_transition_dir() {
  id="$1"
  printf '%s/transitions\n' "$(canonical_work_item_history_dir "$id")"
}

legacy_work_item_path() {
  id="$1"
  printf '%s/%s.md\n' "$state_items_dir" "$id"
}

work_item_path() {
  id="$1"
  canonical_path=$(canonical_work_item_path "$id")
  if [ -f "$canonical_path" ]; then
    printf '%s\n' "$canonical_path"
    return 0
  fi
  legacy_work_item_path "$id"
}

canonical_work_item_progress_path() {
  id="$1"
  printf '%s/progress.md\n' "$(canonical_work_item_dir "$id")"
}

legacy_work_item_progress_path() {
  id="$1"
  printf '%s/%s.md\n' "$state_progress_dir" "$id"
}

work_item_progress_path() {
  id="$1"
  canonical_dir=$(canonical_work_item_dir "$id")
  canonical_progress=$(canonical_work_item_progress_path "$id")
  legacy_progress=$(legacy_work_item_progress_path "$id")

  if [ -f "$canonical_progress" ]; then
    printf '%s\n' "$canonical_progress"
    return 0
  fi

  if [ -f "$legacy_progress" ]; then
    printf '%s\n' "$legacy_progress"
    return 0
  fi

  if [ -d "$canonical_dir" ]; then
    printf '%s\n' "$canonical_progress"
    return 0
  fi

  printf '%s\n' "$legacy_progress"
}

materialize_canonical_progress_if_present() {
  id="$1"
  canonical_progress=$(canonical_work_item_progress_path "$id")
  legacy_progress=$(legacy_work_item_progress_path "$id")

  if [ -f "$canonical_progress" ] || [ ! -f "$legacy_progress" ]; then
    return 0
  fi

  ensure_core_runtime_dirs
  ensure_task_directory_skeleton "$id"
  cp "$legacy_progress" "$canonical_progress"
}

require_work_item_for_write() {
  id="$1"
  canonical_path=$(canonical_work_item_path "$id")
  legacy_path=$(legacy_work_item_path "$id")

  if [ -f "$canonical_path" ]; then
    ensure_core_runtime_dirs
    ensure_task_directory_skeleton "$id"
    materialize_canonical_progress_if_present "$id"
    printf '%s\n' "$canonical_path"
    return 0
  fi

  if [ ! -f "$legacy_path" ]; then
    echo "missing work item: $id" >&2
    return 1
  fi

  ensure_core_runtime_dirs
  ensure_task_directory_skeleton "$id"
  cp "$legacy_path" "$canonical_path"
  materialize_canonical_progress_if_present "$id"
  printf '%s\n' "$canonical_path"
}

work_item_progress_path_for_write() {
  id="$1"
  require_work_item_for_write "$id" >/dev/null
  ensure_task_directory_skeleton "$id"
  materialize_canonical_progress_if_present "$id"
  printf '%s\n' "$(canonical_work_item_progress_path "$id")"
}

ensure_task_directory_skeleton() {
  id="$1"
  task_dir=$(canonical_work_item_dir "$id")
  mkdir -p \
    "$task_dir/refs" \
    "$task_dir/refs/sources" \
    "$task_dir/working/discussions" \
    "$task_dir/working/agent-passes" \
    "$task_dir/working/scratch" \
    "$task_dir/outputs" \
    "$task_dir/closure" \
    "$task_dir/history/transitions"

  refs_index="$task_dir/refs/index.toml"
  if [ ! -f "$refs_index" ]; then
    cat >"$refs_index" <<EOF
schema_version = 1
task_id = "$id"
EOF
  fi
}

list_work_item_transition_events() {
  id="$1"
  canonical_transition_dir=$(canonical_work_item_transition_dir "$id")
  legacy_pattern="*-$id-*.md"
  canonical_found=0

  if [ -d "$canonical_transition_dir" ]; then
    find "$canonical_transition_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort
    canonical_found=1
  fi

  if [ "$canonical_found" -eq 1 ]; then
    return 0
  fi

  if [ -d "$state_transitions_dir" ]; then
    find "$state_transitions_dir" -maxdepth 1 -type f -name "$legacy_pattern" | sort
  fi
}

list_transition_events() {
  canonical_tmp=$(mktemp)
  legacy_tmp=$(mktemp)

  if [ -d "$task_runtime_dir" ]; then
    find "$task_runtime_dir" -mindepth 4 -maxdepth 4 -type f -path '*/history/transitions/TX-*.md' | sort >"$canonical_tmp"
  else
    : >"$canonical_tmp"
  fi

  if [ -d "$state_transitions_dir" ]; then
    find "$state_transitions_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort >"$legacy_tmp"
  else
    : >"$legacy_tmp"
  fi

  cat "$canonical_tmp"

  while IFS= read -r legacy_file; do
    [ -n "$legacy_file" ] || continue
    legacy_work_item=$(field_value "$legacy_file" "Work Item")
    canonical_transition_dir=$(canonical_work_item_transition_dir "$legacy_work_item")

    if [ -d "$canonical_transition_dir" ] && find "$canonical_transition_dir" -maxdepth 1 -type f -name 'TX-*.md' | grep -q .; then
      continue
    fi

    printf '%s\n' "$legacy_file"
  done <"$legacy_tmp"

  rm -f "$canonical_tmp" "$legacy_tmp"
}

read_current_task_id() {
  if [ ! -f "$current_task_pointer_path" ]; then
    return 1
  fi

  awk 'NF { print $0; exit }' "$current_task_pointer_path"
}

set_current_task_id() {
  id="$1"
  ensure_core_runtime_dirs
  printf '%s\n' "$id" >"$current_task_pointer_path"
}

claim_current_task_id_if_missing() {
  id="$1"
  ensure_current_task_pointer

  if read_current_task_id >/dev/null 2>&1; then
    return 0
  fi

  set_current_task_id "$id"
}

claim_current_task_id_for_execution() {
  id="$1"
  status="$2"

  case "$status" in
    in-progress|paused)
      set_current_task_id "$id"
      ;;
    *)
      ensure_current_task_pointer
      ;;
  esac
}

clear_current_task_id_if_matches() {
  id="$1"
  if [ ! -f "$current_task_pointer_path" ]; then
    return 0
  fi

  current_id=$(read_current_task_id 2>/dev/null || true)
  if [ "$current_id" = "$id" ]; then
    rm -f "$current_task_pointer_path"
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

ensure_current_task_pointer() {
  if [ -f "$current_task_pointer_path" ]; then
    current_id=$(read_current_task_id 2>/dev/null || true)
    if [ -n "$current_id" ]; then
      current_path=$(work_item_path "$current_id")
      if [ -f "$current_path" ]; then
        current_status=$(field_value "$current_path" "Status")
        if is_open_work_item_status "$current_status"; then
          return 0
        fi
      fi
    fi

    rm -f "$current_task_pointer_path"
  fi

  next_open_id=$(first_open_work_item_id || true)
  if [ -n "$next_open_id" ]; then
    set_current_task_id "$next_open_id"
  fi
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

is_open_work_item_status() {
  case "$1" in
    backlog|framing|planning|ready|in-progress|review|paused) return 0 ;;
    *) return 1 ;;
  esac
}

work_item_matches_scope() {
  file="$1"
  scope="$2"
  department="${3:-}"
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
    department)
      [ -n "$department" ] || return 1
      department_participation "$file" "$department" >/dev/null 2>&1
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_current_work_item_path_for_scope() {
  scope="${1:-company}"
  department="${2:-}"
  current_id=$(read_current_task_id 2>/dev/null || true)

  if [ -z "$current_id" ]; then
    return 1
  fi

  current_path=$(work_item_path "$current_id")
  if [ ! -f "$current_path" ]; then
    return 1
  fi

  current_status=$(field_value "$current_path" "Status")
  is_open_work_item_status "$current_status" || return 1
  work_item_matches_scope "$current_path" "$scope" "$department" || return 1

  printf '%s\n' "$current_path"
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
  canonical_tmp=$(mktemp)
  legacy_tmp=$(mktemp)

  if [ -d "$task_runtime_dir" ]; then
    find "$task_runtime_dir" -mindepth 2 -maxdepth 2 -type f -name 'task.md' | sort >"$canonical_tmp"
  else
    : >"$canonical_tmp"
  fi

  if [ -d "$state_items_dir" ]; then
    find "$state_items_dir" -maxdepth 1 -type f -name 'WI-*.md' | sort >"$legacy_tmp"
  else
    : >"$legacy_tmp"
  fi

  cat "$canonical_tmp"

  while IFS= read -r legacy_file; do
    [ -n "$legacy_file" ] || continue
    legacy_id=$(basename "$legacy_file" .md)
    if [ -f "$(canonical_work_item_path "$legacy_id")" ]; then
      continue
    fi
    printf '%s\n' "$legacy_file"
  done <"$legacy_tmp"

  rm -f "$canonical_tmp" "$legacy_tmp"
}

list_departments() {
  if [ ! -d ".harness/workspace/departments" ]; then
    return 0
  fi
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
  first_linked_artifact_path_file="$1"
  first_linked_artifact_path_links=$(field_value "$first_linked_artifact_path_file" "Linked artifacts")
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
  linked_artifact_entry_links=$(field_value "$linked_artifact_entry_work_item_file" "Linked artifacts")

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
  existing_links=$(field_value "$work_item_file" "Linked artifacts")
  updated_links=$(updated_linked_artifacts_value "$existing_links" "$artifact_path" "$artifact_type" "$artifact_status")
  rewrite_work_item_header_snapshot "$work_item_file" "Linked artifacts" "$updated_links"
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
