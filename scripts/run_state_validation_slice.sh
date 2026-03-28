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

  [ -d "$canonical_transition_dir" ] || return 1

  for event_file in $(find "$canonical_transition_dir" -maxdepth 1 -type f -name 'TX-*.md' | sort); do
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

run_node_free_control_loop_regression() {
  node_free_sandbox="$tmp_root/node-free-control-loop"

  "$script_dir/materialize_runtime_fixture.sh" \
    --target "$node_free_sandbox" \
    --source-repo "$repo_root" >/dev/null

  (
    cd "$node_free_sandbox"
    . "$script_dir/lib_state.sh"
    export STATE_ACTOR="validation-slice"
    export STATE_INVOKER="${STATE_INVOKER:-$(default_harness_command "run_state_validation_slice.sh")}"
    no_node_path="/usr/bin:/bin:/usr/sbin:/sbin"

    task_version() {
      task_id="$1"
      field_value "$(canonical_work_item_path "$task_id")" "State version"
    }

    control_item=$("$script_dir/new_work_item.sh" governance "Node-Free Task Record Control Loop")
    control_id=$(field_value "$control_item" "ID")

    "$script_dir/update_work_item_fields.sh" \
      --expected-version "$(task_version "$control_id")" \
      --operation-id "${control_id}-seed-fields" \
      "$control_id" \
      "Objective" "Prove the minimum-core task-record control loop works without node in PATH." \
      "Ready criteria" "The item can reach ready without node-backed parsing." \
      "Done criteria" "The item can reach review with node removed from PATH." >/dev/null

    "$script_dir/transition_work_item.sh" \
      --expected-from-status backlog \
      --expected-version "$(task_version "$control_id")" \
      --operation-id "${control_id}-to-planning" \
      "$control_id" \
      planning \
      none \
      none \
      "node-free planning" >/dev/null

    "$script_dir/transition_work_item.sh" \
      --expected-from-status planning \
      --expected-version "$(task_version "$control_id")" \
      --operation-id "${control_id}-to-ready" \
      "$control_id" \
      ready \
      none \
      none \
      "node-free ready" >/dev/null

    ctl_command="$script_dir/work_item_ctl.sh"

    PATH="$no_node_path" "$ctl_command" status --json --all >/dev/null
    PATH="$no_node_path" "$ctl_command" start --json company >/dev/null
    PATH="$no_node_path" "$ctl_command" close --json --target-status review --work-item "$control_id" company >/dev/null

    if [ "$(field_value "$(canonical_work_item_path "$control_id")" "Status")" != "review" ]; then
      echo "validation slice failed: node-free control loop did not reach review" >&2
      exit 1
    fi
  )
}

run_runtime_surface_boundary_regression() {
  runtime_sandbox="$tmp_root/runtime-surface-boundary"

  "$script_dir/materialize_runtime_fixture.sh" \
    --target "$runtime_sandbox" \
    --source-repo "$repo_root" >/dev/null

  (
    cd "$runtime_sandbox"

    for forbidden_path in \
      ".agents" \
      "AGENTS.md" \
      "CLAUDE.md" \
      "GEMINI.md" \
      ".claude" \
      ".codex" \
      ".gemini"
    do
      if [ -e "$forbidden_path" ]; then
        echo "validation slice failed: runtime fixture materialized forbidden surface $forbidden_path" >&2
        exit 1
      fi
    done
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
  . "$script_dir/lib_state.sh"
  export STATE_ACTOR="validation-slice"
  export STATE_INVOKER="${STATE_INVOKER:-$(default_harness_command "run_state_validation_slice.sh")}"

  task_version() {
    task_id="$1"
    field_value "$(canonical_work_item_path "$task_id")" "State version"
  }

  assert_absent() {
    path="$1"
    if [ -e "$path" ]; then
      echo "validation slice failed: deprecated surface still exists at $path" >&2
      exit 1
    fi
  }

  "$script_dir/validate_workspace.sh" --mode core >/dev/null

  for no_context_command in \
    "\"$script_dir/new_research_dispatch.sh\" \"Dispatch Without Task Context\"" \
    "\"$script_dir/new_research.sh\" \"Research Without Task Context\"" \
    "\"$script_dir/new_decision.sh\" \"Decision Without Task Context\"" \
    "\"$script_dir/new_acceptance_ledger.sh\" \"Acceptance Without Task Context\"" \
    "\"$script_dir/new_source_note.sh\" \"Source Without Task Context\"" \
    "\"$script_dir/new_checkpoint.sh\" \"Checkpoint Without Task Context\"" \
    "\"$script_dir/new_role_change_proposal.sh\" \"Role Change Without Task Context\""
  do
    if eval "$no_context_command" >/dev/null 2>&1; then
      echo "validation slice failed: minimum-core runtime allowed task-local artifact creation without explicit --work-item" >&2
      exit 1
    fi
  done

  validation_item=$("$script_dir/new_work_item.sh" governance "Harness Task Record Smoke Chain" "Workflow & Automation Lead" high general-manager)
  validation_id=$(field_value "$validation_item" "ID")

  if [ "$validation_item" != "$(canonical_work_item_path "$validation_id")" ]; then
    echo "validation slice failed: new work item did not resolve to canonical task path" >&2
    exit 1
  fi

  assert_absent ".harness/current-task"
  assert_absent ".harness/archive"

  "$script_dir/update_work_item_fields.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-seed-fields" \
    "$validation_id" \
    "Objective" "Prove the generated minimum-core runtime can execute a task-record lifecycle end-to-end." \
    "Ready criteria" "The item reaches ready with routing, gate, and recovery fields populated." \
    "Done criteria" "Attachments stay task-local, recovery stays in task.md, and terminal states audit cleanly." \
    "Required artifacts" "research-dispatch,source-note,research-memo,decision-pack,checkpoint" \
    "Current stage owner" "Workflow & Automation Lead" \
    "Current stage role" "planner" \
    "Next gate" "ready" >/dev/null

  "$script_dir/upsert_work_item_recovery.sh" \
    --expected-version "$(task_version "$validation_id")" \
    "$validation_id" \
    "Frame the smoke chain inside a generated consumer sandbox." \
    "./scripts/work_item_ctl.sh status --json --all" \
    "This task exists only in the generated consumer fixture." >/dev/null

  if [ "$(recovery_field_value_or_none "$(canonical_work_item_path "$validation_id")" "Current focus")" = "none" ]; then
    echo "validation slice failed: recovery writeback did not update task.md" >&2
    exit 1
  fi

  "$script_dir/transition_work_item.sh" \
    --expected-from-status backlog \
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

  if [ "$(field_value "$validation_item" "Assignee")" != "validation-slice" ]; then
    echo "validation slice failed: start_work_item did not set assignee" >&2
    exit 1
  fi

  if [ "$(field_value_or_none "$validation_item" "Claim expires at")" = "none" ]; then
    echo "validation slice failed: start_work_item did not set claim expiry" >&2
    exit 1
  fi

  if [ "$(field_value_or_none "$validation_item" "Lease version")" = "0" ]; then
    echo "validation slice failed: start_work_item did not increment lease version" >&2
    exit 1
  fi

  if [ "$(field_value "$validation_item" "Current stage role")" != "executor" ]; then
    echo "validation slice failed: in-progress item did not switch to executor stage role" >&2
    exit 1
  fi

  (
    acquire_named_lock "validation-slice-contract" 1 0.01
    lock_dir=".harness/locks/validation-slice-contract.lock"
    for required_file in pid owner claimed_at lease_expires_at lease_id; do
      if [ ! -f "$lock_dir/$required_file" ]; then
        echo "validation slice failed: lock metadata missing $required_file" >&2
        exit 1
      fi
    done
  )

  validation_dispatch=$("$script_dir/new_research_dispatch.sh" --work-item "$validation_id" "Runtime Smoke Dispatch")
  case "$validation_dispatch" in
    ".harness/tasks/$validation_id/attachments/"*-research-dispatch.md) ;;
    *)
      echo "validation slice failed: dispatch did not stay in task-local attachments" >&2
      exit 1
      ;;
  esac

  validation_source=$("$script_dir/new_source_note.sh" --work-item "$validation_id" "Runtime Smoke Source")
  case "$validation_source" in
    ".harness/tasks/$validation_id/attachments/sources/"*.md) ;;
    *)
      echo "validation slice failed: source note did not stay in task-local attachment sources" >&2
      exit 1
      ;;
  esac

  validation_research=$("$script_dir/new_research.sh" --work-item "$validation_id" "Runtime Smoke Research")
  case "$validation_research" in
    ".harness/tasks/$validation_id/attachments/"*-research-memo.md) ;;
    *)
      echo "validation slice failed: research memo did not stay in task-local attachments" >&2
      exit 1
      ;;
  esac

  validation_decision=$("$script_dir/new_decision.sh" --work-item "$validation_id" "Runtime Smoke Decision")
  case "$validation_decision" in
    ".harness/tasks/$validation_id/attachments/"*-decision-pack.md) ;;
    *)
      echo "validation slice failed: decision pack did not stay in task-local attachments" >&2
      exit 1
      ;;
  esac

  validation_acceptance_ledger=$("$script_dir/new_acceptance_ledger.sh" --work-item "$validation_id" "Runtime Smoke Acceptance")
  case "$validation_acceptance_ledger" in
    ".harness/tasks/$validation_id/attachments/"*-acceptance-ledger.md) ;;
    *)
      echo "validation slice failed: acceptance ledger did not stay in task-local attachments" >&2
      exit 1
      ;;
  esac

  validation_checkpoint=$("$script_dir/new_checkpoint.sh" --work-item "$validation_id" "Runtime Smoke Checkpoint")
  case "$validation_checkpoint" in
    ".harness/tasks/$validation_id/attachments/"*-checkpoint.md) ;;
    *)
      echo "validation slice failed: checkpoint did not stay in task-local attachments" >&2
      exit 1
      ;;
  esac

  validation_role_change=$("$script_dir/new_role_change_proposal.sh" --work-item "$validation_id" "Runtime Role Compounding")
  case "$validation_role_change" in
    ".harness/tasks/$validation_id/closure/"*-role-change-proposal.md) ;;
    *)
      echo "validation slice failed: role change proposal did not stay in task-local closure" >&2
      exit 1
      ;;
  esac

  for artifact in \
    "$validation_dispatch|research-dispatch|approved" \
    "$validation_source|source-note|approved" \
    "$validation_research|research-memo|approved" \
    "$validation_decision|decision-pack|approved"
  do
    artifact_path=${artifact%%|*}
    remainder=${artifact#*|}
    artifact_type=${remainder%%|*}
    artifact_status=${artifact##*|}

    "$script_dir/set_work_item_artifact_status.sh" \
      --expected-version "$(task_version "$validation_id")" \
      "$validation_id" \
      "$artifact_path" \
      "$artifact_status" \
      "$artifact_type" >/dev/null
  done

  "$script_dir/pause_work_item.sh" \
    --expected-from-status in-progress \
    --expected-version "$(task_version "$validation_id")" \
    --interrupt-marker risk-review-required \
    --operation-id "${validation_id}-pause-risk" \
    "$validation_id" \
    "waiting for risk review" \
    "workflow-automation -> runtime-smoke" \
    "runtime smoke pause for risk review" >/dev/null

  assert_transition_event_type "$sandbox" "$validation_id" "${validation_id}-pause-risk" "approval-pause"

  "$script_dir/resume_work_item.sh" \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-resume-risk" \
    "$validation_id" \
    "runtime-smoke -> workflow-automation" \
    "runtime smoke resume after risk review" >/dev/null

  assert_transition_event_type "$sandbox" "$validation_id" "${validation_id}-resume-risk" "resume"

  "$script_dir/complete_work_item.sh" \
    --target-status review \
    --work-item "$validation_id" \
    --reason "runtime smoke review handoff" \
    --operation-id "${validation_id}-review" \
    company >/dev/null

  if [ "$(field_value "$validation_item" "Status")" != "review" ]; then
    echo "validation slice failed: complete_work_item did not move item to review" >&2
    exit 1
  fi

  if [ "$(field_value_or_none "$validation_item" "Claim expires at")" != "none" ]; then
    echo "validation slice failed: review item still carries claim expiry" >&2
    exit 1
  fi

  "$script_dir/complete_work_item.sh" \
    --target-status done \
    --work-item "$validation_id" \
    --reason "runtime smoke done" \
    --operation-id "${validation_id}-done" \
    company >/dev/null

  if [ "$(field_value "$validation_item" "Status")" != "done" ]; then
    echo "validation slice failed: complete_work_item did not move item to done" >&2
    exit 1
  fi

  "$script_dir/transition_work_item.sh" \
    --expected-from-status done \
    --expected-version "$(task_version "$validation_id")" \
    --operation-id "${validation_id}-archived" \
    "$validation_id" \
    archived \
    none \
    none \
    "runtime smoke archive" >/dev/null

  if [ "$(field_value "$validation_item" "Status")" != "archived" ]; then
    echo "validation slice failed: task did not move to archived" >&2
    exit 1
  fi

  if [ "$(field_value_or_none "$validation_item" "Archived at")" = "none" ]; then
    echo "validation slice failed: archived task is missing Archived at" >&2
    exit 1
  fi

  if "$script_dir/query_work_items.sh" --id-only | grep -q "$validation_id"; then
    echo "validation slice failed: archived task still appears in default query surface" >&2
    exit 1
  fi

  if [ "$("$script_dir/query_work_items.sh" --id-only --all --task-id "$validation_id")" != "$validation_id" ]; then
    echo "validation slice failed: archived task missing from --all query surface" >&2
    exit 1
  fi

  assert_absent ".harness/current-task"
  assert_absent ".harness/archive"

  "$script_dir/validate_workspace.sh" --mode core >/dev/null
  "$script_dir/audit_state_system.sh" --mode core >/dev/null
)

run_node_free_control_loop_regression
run_runtime_surface_boundary_regression

printf '%s\n' "$sandbox"
