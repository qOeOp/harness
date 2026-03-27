#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

keep_tmp=0

usage() {
  echo "usage: $0 [--keep-temp]" >&2
  exit 1
}

find_transition_event_by_operation_id() {
  sandbox_root="$1"
  work_item_id="$2"
  operation_id="$3"

  canonical_transition_dir="$sandbox_root/.harness/tasks/$work_item_id/history/transitions"
  if [ -d "$canonical_transition_dir" ]; then
    event_candidates=$(find "$canonical_transition_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort)
  else
    event_candidates=$(find "$sandbox_root/.harness/workspace/state/transitions" -maxdepth 1 -type f -name "TX-*-$work_item_id-*.md" | sort)
  fi

  for event_file in $event_candidates; do
    if [ "$(awk -v label="Operation ID" 'index($0, "- " label ": ") == 1 { print substr($0, length("- " label ": ") + 1); exit }' "$event_file")" = "$operation_id" ]; then
      printf '%s\n' "$event_file"
      return 0
    fi
  done

  return 1
}

assert_transition_event_type() {
  sandbox_root="$1"
  work_item_id="$2"
  operation_id="$3"
  expected_type="$4"

  event_file=$(find_transition_event_by_operation_id "$sandbox_root" "$work_item_id" "$operation_id") || {
    echo "validation slice failed: missing transition event for operation id $operation_id" >&2
    exit 1
  }

  actual_type=$(awk -v label="Event type" 'index($0, "- " label ": ") == 1 { print substr($0, length("- " label ": ") + 1); exit }' "$event_file")
  if [ "$actual_type" != "$expected_type" ]; then
    echo "validation slice failed: expected $expected_type for $operation_id but found ${actual_type:-missing}" >&2
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --keep-temp)
      keep_tmp=1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/state-validation.XXXXXX")
sandbox="$tmp_root/repo"

cleanup() {
  if [ "$keep_tmp" -ne 1 ]; then
    rm -rf "$tmp_root"
  fi
}

run_current_task_pointer_regression() {
  pointer_sandbox="$tmp_root/current-task-pointer"

  "$script_dir/materialize_runtime_fixture.sh" \
    --target "$pointer_sandbox" \
    --source-repo "$repo_root" >/dev/null

  (
    cd "$pointer_sandbox"
    if [ -d "$PWD/.agents/skills/harness" ]; then
      HARNESS_ROOT_OVERRIDE="$PWD/.agents/skills/harness"
    fi
    . "$script_dir/lib_state.sh"
    export STATE_ACTOR="validation-slice"
    export STATE_INVOKER="${STATE_INVOKER:-$(default_harness_command "run_state_validation_slice.sh")}"
    start_command=$(default_harness_command "start_work_item.sh")

    task_version() {
      task_id="$1"
      field_value "$(canonical_work_item_path "$task_id")" "State version"
    }

    seed_ready_item() {
      seed_title="$1"
      seed_item=$("$script_dir/new_work_item.sh" governance "$seed_title")
      seed_id=$(field_value "$seed_item" "ID")

      "$script_dir/update_work_item_fields.sh" \
        --expected-version "$(task_version "$seed_id")" \
        --operation-id "${seed_id}-seed-fields" \
        "$seed_id" \
        "Objective" "Verify current-task focus integrity during intake, progress writeback, and resume flows." \
        "Ready criteria" "The task may enter ready for routing checks." \
        "Done criteria" "The task may be resumed without stealing focus unexpectedly." >/dev/null

      "$script_dir/transition_work_item.sh" \
        --expected-from-status backlog \
        --expected-version "$(task_version "$seed_id")" \
        --operation-id "${seed_id}-to-framing" \
        "$seed_id" \
        framing \
        none \
        none \
        "pointer regression framing" >/dev/null

      "$script_dir/transition_work_item.sh" \
        --expected-from-status framing \
        --expected-version "$(task_version "$seed_id")" \
        --operation-id "${seed_id}-to-planning" \
        "$seed_id" \
        planning \
        none \
        none \
        "pointer regression planning" >/dev/null

      "$script_dir/transition_work_item.sh" \
        --expected-from-status planning \
        --expected-version "$(task_version "$seed_id")" \
        --operation-id "${seed_id}-to-ready" \
        "$seed_id" \
        ready \
        none \
        none \
        "pointer regression ready" >/dev/null

      printf '%s\n' "$seed_id"
    }

    primary_id=$(seed_ready_item "Current Task Pointer Primary")

    "$script_dir/start_work_item.sh" \
      --reason "pointer regression primary start" \
      --operation-id "${primary_id}-start" \
      company >/dev/null

    if [ "$(read_current_task_id)" != "$primary_id" ]; then
      echo "validation slice failed: primary started task did not become current-task" >&2
      exit 1
    fi

    secondary_item=$("$script_dir/new_work_item.sh" governance "Current Task Pointer Secondary")
    secondary_id=$(field_value "$secondary_item" "ID")

    if [ "$(read_current_task_id)" != "$primary_id" ]; then
      echo "validation slice failed: backlog intake stole current-task focus from the active task" >&2
      exit 1
    fi

    if [ "$("$script_dir/select_work_item.sh" --id-only company)" != "$primary_id" ]; then
      echo "validation slice failed: selector stopped preferring the active current task after intake" >&2
      exit 1
    fi

    "$script_dir/update_work_item_fields.sh" \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-seed-fields" \
      "$secondary_id" \
      "Objective" "Secondary task used to verify current-task focus does not drift." \
      "Ready criteria" "Secondary task may enter ready for progress writeback checks." \
      "Done criteria" "Secondary task may be paused and resumed without breaking routing." >/dev/null

    "$script_dir/transition_work_item.sh" \
      --expected-from-status backlog \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-to-framing" \
      "$secondary_id" \
      framing \
      none \
      none \
      "secondary framing" >/dev/null

    "$script_dir/transition_work_item.sh" \
      --expected-from-status framing \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-to-planning" \
      "$secondary_id" \
      planning \
      none \
      none \
      "secondary planning" >/dev/null

    "$script_dir/transition_work_item.sh" \
      --expected-from-status planning \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-to-ready" \
      "$secondary_id" \
      ready \
      none \
      none \
      "secondary ready" >/dev/null

    "$script_dir/upsert_work_item_progress.sh" \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-progress-ready" \
      "$secondary_id" \
      "Secondary task is staged for a future handoff." \
      "$start_command company" >/dev/null

    if [ "$(read_current_task_id)" != "$primary_id" ]; then
      echo "validation slice failed: ready-task progress writeback stole current-task focus" >&2
      exit 1
    fi

    "$script_dir/transition_work_item.sh" \
      --expected-from-status ready \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-to-in-progress" \
      "$secondary_id" \
      in-progress \
      none \
      none \
      "secondary execution start" >/dev/null

    "$script_dir/pause_work_item.sh" \
      --expected-from-status in-progress \
      --expected-version "$(task_version "$secondary_id")" \
      --interrupt-marker risk-review-required \
      --operation-id "${secondary_id}-pause" \
      "$secondary_id" \
      "waiting for regression risk review" \
      "pointer-regression -> secondary" \
      "secondary pause" >/dev/null

    set_current_task_id "$primary_id"

    "$script_dir/resume_work_item.sh" \
      --expected-version "$(task_version "$secondary_id")" \
      --operation-id "${secondary_id}-resume" \
      "$secondary_id" \
      "secondary -> pointer-regression" \
      "secondary resume" >/dev/null

    if [ "$(read_current_task_id)" != "$secondary_id" ]; then
      echo "validation slice failed: explicit resume did not reclaim current-task focus" >&2
      exit 1
    fi

    if [ "$("$script_dir/select_work_item.sh" --id-only company)" != "$secondary_id" ]; then
      echo "validation slice failed: selector did not follow the resumed current task" >&2
      exit 1
    fi
  )
}

trap cleanup EXIT HUP INT TERM

[ -f "$repo_root/SKILL.md" ] || {
  echo "validation slice failed: repo root is not the harness source repo ($repo_root)" >&2
  exit 1
}

[ -d "$repo_root/scripts" ] || {
  echo "validation slice failed: repo root is missing scripts/ ($repo_root)" >&2
  exit 1
}

"$script_dir/materialize_runtime_fixture.sh" \
  --target "$sandbox" \
  --source-repo "$repo_root" >/dev/null

(
  cd "$sandbox"
  if [ -d "$PWD/.agents/skills/harness" ]; then
    HARNESS_ROOT_OVERRIDE="$PWD/.agents/skills/harness"
  fi
  . "$script_dir/lib_state.sh"
  export STATE_ACTOR="validation-slice"
  export STATE_INVOKER="${STATE_INVOKER:-$(default_harness_command "run_state_validation_slice.sh")}"
  transition_command=$(default_harness_command "transition_work_item.sh")
  new_decision_command=$(default_harness_command "new_decision.sh")
  finalize_command=$(default_harness_command "finalize_work_item.sh")

  task_version() {
    task_id="$1"
    field_value "$(canonical_work_item_path "$task_id")" "State version"
  }

  "$script_dir/validate_workspace.sh" --mode core >/dev/null

  validation_item=$("$script_dir/new_work_item.sh" governance "Harness Runtime Smoke Chain" "Workflow & Automation Lead" high chief-of-staff)
  validation_id=$(field_value "$validation_item" "ID")

  if [ "$validation_item" != "$(canonical_work_item_path "$validation_id")" ]; then
    echo "validation slice failed: new work item did not resolve to canonical task path" >&2
    exit 1
  fi

  if [ ! -f "$runtime_manifest_path" ]; then
    echo "validation slice failed: runtime manifest was not created" >&2
    exit 1
  fi

  if [ "$(read_current_task_id)" != "$validation_id" ]; then
    echo "validation slice failed: current-task pointer mismatch after work item creation" >&2
    exit 1
  fi

  if [ -d "$state_items_dir" ] || [ -d "$state_progress_dir" ]; then
    echo "validation slice failed: legacy runtime paths should not be auto-created" >&2
    exit 1
  fi

  "$script_dir/update_work_item_fields.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-seed-fields" \
    "$validation_id" \
    "Objective" "Prove the generated minimum-core runtime can create a task, recover progress, generate task-local artifacts, and finalize cleanly inside a consumer sandbox." \
    "Ready criteria" "Progress artifact exists and the work item reaches ready without creating legacy workspace state." \
    "Done criteria" "Research dispatch, source note, research memo, and decision pack are all linked as approved and the item finalizes without audit drift." \
    "Required artifacts" "research-dispatch,source-note,research-memo,decision-pack" \
    "Why it matters" "A pure source repo should prove runtime generation and one end-to-end control loop without keeping live runtime state at the root." \
    "Due review at" "$(date +%F)" >/dev/null

  "$script_dir/upsert_work_item_progress.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-progress-init" \
    "$validation_id" \
    "Frame the smoke chain and create the recovery artifact inside the generated consumer sandbox." \
    "$transition_command --expected-from-status backlog --expected-version $(task_version "$validation_id") $validation_id framing" \
    "This task exists only in the generated consumer fixture." >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status backlog \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-to-framing" \
    "$validation_id" \
    framing \
    none \
    "workflow-automation -> runtime-smoke" \
    "runtime smoke framing" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status framing \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-to-planning" \
    "$validation_id" \
    planning \
    none \
    "workflow-automation -> runtime-smoke" \
    "runtime smoke planning" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status planning \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-to-ready" \
    "$validation_id" \
    ready \
    none \
    "workflow-automation -> runtime-smoke" \
    "runtime smoke ready" >/dev/null

  "$script_dir/start_work_item.sh" \
    --path-only \
    --reason "runtime smoke execution" \
    --operation-id "${validation_id}-start" \
    company >/dev/null

  if [ "$(field_value "$validation_item" "Status")" != "in-progress" ]; then
    echo "validation slice failed: start_work_item did not move item to in-progress" >&2
    exit 1
  fi

  "$script_dir/pause_work_item.sh" \
    --expected-from-status in-progress \
    --expected-version "$(task_version "$validation_id")" \
    --interrupt-marker risk-review-required \
    --operation-id "${validation_id}-pause-risk" \
    "$validation_id" \
    "waiting for risk review" \
    "workflow-automation -> runtime-smoke" \
    "runtime smoke pause for risk review" >/dev/null

  if "$script_dir/transition_work_item.sh" \
    --expected-from-status paused \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-illegal-review" \
    "$validation_id" \
    review \
    none \
    "runtime-smoke -> workflow-automation" \
    "illegal direct review from paused" >/dev/null 2>&1
  then
    echo "validation slice failed: paused item transitioned without resume protocol" >&2
    exit 1
  fi

  "$script_dir/resume_work_item.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-resume-risk" \
    "$validation_id" \
    "runtime-smoke -> workflow-automation" \
    "runtime smoke resume after risk review" >/dev/null

  "$script_dir/upsert_work_item_progress.sh" \
    "$validation_id" \
    "Generate task-local artifacts with the canonical creation scripts." \
    "$new_decision_command --work-item $validation_id \"Runtime Smoke Decision\"" >/dev/null

  validation_dispatch=$("$script_dir/new_research_dispatch.sh" --work-item "$validation_id" "Runtime Smoke Dispatch")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-approve-dispatch" \
    "$validation_id" \
    "$validation_dispatch" \
    "research-dispatch" \
    "approved" >/dev/null

  validation_source=$("$script_dir/new_source_note.sh" --work-item "$validation_id" "Runtime Smoke Source")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-approve-source" \
    "$validation_id" \
    "$validation_source" \
    "source-note" \
    "approved" >/dev/null

  validation_research=$("$script_dir/new_research.sh" --work-item "$validation_id" company "Runtime Smoke Research Memo")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-approve-research" \
    "$validation_id" \
    "$validation_research" \
    "research-memo" \
    "approved" >/dev/null

  validation_decision=$("$script_dir/new_decision.sh" --work-item "$validation_id" company "Runtime Smoke Decision")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-link-decision" \
    "$validation_id" \
    "$validation_decision" \
    "decision-pack" \
    "approved" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status in-progress \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-to-review" \
    "$validation_id" \
    review \
    none \
    "runtime-smoke -> workflow-automation" \
    "runtime smoke review" >/dev/null

  "$script_dir/upsert_work_item_progress.sh" \
    "$validation_id" \
    "Review passed; finalize the work item and verify the audit." \
    "$finalize_command --expected-from-status review --expected-version $(task_version "$validation_id") $validation_id done" >/dev/null

  "$script_dir/finalize_work_item.sh" \
    --expected-from-status review \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-finalize" \
    "$validation_id" \
    done \
    none \
    none \
    "validation slice complete" >/dev/null

  assert_transition_event_type "$PWD" "$validation_id" "${validation_id}-to-framing" "state-transition"
  assert_transition_event_type "$PWD" "$validation_id" "${validation_id}-pause-risk" "approval-pause"
  assert_transition_event_type "$PWD" "$validation_id" "${validation_id}-resume-risk" "resume"
  assert_transition_event_type "$PWD" "$validation_id" "${validation_id}-link-decision" "artifact-link"

  (
    . "$script_dir/lib_state.sh"
    acquire_named_lock "validation-lock-release-check"
  )

  if [ -d "$state_locks_dir/validation-lock-release-check.lock" ]; then
    echo "validation slice failed: state lock was left behind after subshell exit" >&2
    exit 1
  fi

  "$script_dir/audit_state_system.sh" --mode core >/dev/null
  "$script_dir/validate_workspace.sh" --mode core >/dev/null

  progress_path=$(work_item_progress_path "$validation_id")

  if [ "$progress_path" != "$(canonical_work_item_progress_path "$validation_id")" ]; then
    echo "validation slice failed: progress path did not resolve to canonical task path" >&2
    exit 1
  fi

  printf 'validation slice: ok\n'
  printf 'work item: %s\n' "$validation_id"
  printf 'progress: %s\n' "$progress_path"
  printf 'dispatch: %s\n' "$validation_dispatch"
  printf 'source: %s\n' "$validation_source"
  printf 'research: %s\n' "$validation_research"
  printf 'decision: %s\n' "$validation_decision"
)

run_current_task_pointer_regression

if [ "$keep_tmp" -eq 1 ]; then
  printf 'kept sandbox at %s\n' "$sandbox"
fi
