#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../../.." && pwd)

keep_tmp=0

usage() {
  echo "usage: $0 [--keep-temp]" >&2
  exit 1
}

copy_repo() {
  source_dir="$1"
  target_dir="$2"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a \
      --exclude '.git/' \
      --exclude '.idea/' \
      --exclude 'node_modules/' \
      --exclude '.DS_Store' \
      "$source_dir/" "$target_dir/"
    return 0
  fi

  (
    cd "$source_dir"
    tar \
      --exclude '.git' \
      --exclude '.idea' \
      --exclude 'node_modules' \
      --exclude '.DS_Store' \
      -cf - .
  ) | (
    cd "$target_dir"
    tar -xf -
  )
}

find_transition_event_by_operation_id() {
  sandbox_root="$1"
  work_item_id="$2"
  operation_id="$3"

  for event_file in $(find "$sandbox_root/.harness/workspace/state/transitions" -maxdepth 1 -type f -name "TX-*-$work_item_id-*.md" | sort); do
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
mkdir -p "$sandbox"

cleanup() {
  if [ "$keep_tmp" -ne 1 ]; then
    rm -rf "$tmp_root"
  fi
}

trap cleanup EXIT HUP INT TERM

copy_repo "$repo_root" "$sandbox"

(
  cd "$sandbox"
  . "$script_dir/lib_state.sh"
  export STATE_ACTOR="validation-slice"
  export STATE_INVOKER="./.agents/skills/harness/scripts/run_state_validation_slice.sh"

  validation_item=$("$script_dir/new_work_item.sh" governance "Harness V2 Validation Slice" "Workflow & Automation Lead" high chief-of-staff)
  validation_id=$(basename "$validation_item" .md)

  replace_field "$validation_item" "Objective" "Prove the local state harness can create, recover, transition, link evidence, and audit inside an isolated sandbox."
  replace_field "$validation_item" "Ready criteria" "Progress artifact exists, required department participation is declared, and the item reaches ready without manual board edits."
  replace_field "$validation_item" "Done criteria" "Decision artifact is linked, required department is marked done, finalization succeeds, and state audit passes."
  replace_field "$validation_item" "Required artifacts" "decision-pack"
  replace_field "$validation_item" "Why it matters" "A harness should validate one minimal control loop before claiming reliability."
  replace_field "$validation_item" "Required departments" "risk-office"
  replace_field "$validation_item" "Participation records" "risk-office=required"
  replace_field "$validation_item" "Due review at" "$(date +%F)"

  "$script_dir/upsert_work_item_progress.sh" \
    --expected-version 1 \
    --operation-id "${validation_id}-progress-init" \
    "$validation_id" \
    "Frame the validation slice and create the recovery artifact." \
    "./.agents/skills/harness/scripts/transition_work_item.sh --expected-from-status backlog --expected-version 2 $validation_id framing" \
    "Validation item exists only in the sandbox." >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status backlog \
    --expected-version 2 \
    --operation-id "${validation_id}-to-framing" \
    "$validation_id" \
    framing \
    none \
    "workflow-automation -> risk-office" \
    "validation slice framing" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status framing \
    --expected-version 3 \
    --operation-id "${validation_id}-to-planning" \
    "$validation_id" \
    planning \
    none \
    "workflow-automation -> risk-office" \
    "validation slice planning" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status planning \
    --expected-version 4 \
    --operation-id "${validation_id}-to-ready" \
    "$validation_id" \
    ready \
    none \
    "workflow-automation -> risk-office" \
    "validation slice ready" >/dev/null

  "$script_dir/upsert_work_item_progress.sh" \
    "$validation_id" \
    "Ready gate passed; enter execution and prepare evidence artifact." \
    "./.agents/skills/harness/scripts/transition_work_item.sh --expected-from-status ready --expected-version 5 $validation_id in-progress" >/dev/null

  "$script_dir/transition_work_item.sh" \
    --expected-from-status ready \
    --expected-version 5 \
    --operation-id "${validation_id}-to-in-progress" \
    "$validation_id" \
    in-progress \
    none \
    "workflow-automation -> risk-office" \
    "validation slice execution" >/dev/null

  "$script_dir/pause_work_item.sh" \
    --expected-from-status in-progress \
    --expected-version 6 \
    --interrupt-marker risk-review-required \
    --operation-id "${validation_id}-pause-risk" \
    "$validation_id" \
    "waiting for risk review" \
    "workflow-automation -> risk-office" \
    "validation slice pause for risk review" >/dev/null

  if "$script_dir/transition_work_item.sh" \
    --expected-from-status paused \
    --expected-version 7 \
    --operation-id "${validation_id}-illegal-review" \
    "$validation_id" \
    review \
    none \
    "risk-office -> workflow-automation" \
    "illegal direct review from paused" >/dev/null 2>&1
  then
    echo "validation slice failed: paused item transitioned without resume protocol" >&2
    exit 1
  fi

  "$script_dir/resume_work_item.sh" \
    --expected-version 7 \
    --operation-id "${validation_id}-resume-risk" \
    "$validation_id" \
    "risk-office -> workflow-automation" \
    "validation slice resume after risk review" >/dev/null

  validation_decision=".harness/workspace/decisions/log/$(date +%F)-${validation_id}-validation-slice.md"
  cat >"$validation_decision" <<EOF
# Decision Pack

- Linked work items: $validation_id

- Date: $(date +%F)
- Owner: Workflow & Automation Lead
- Decision: Validation slice completed in sandbox without mutating the live repository.
- Why now:
  1. Harness v2 needs one runnable loop before wider rollout.
- Research dispatch: n/a
- Verification date: $(date +%F)
- Verification mode: internal-only
- Sources reviewed:
  1. scripts/new_work_item.sh
  2. scripts/transition_work_item.sh
  3. scripts/pause_work_item.sh
  4. scripts/resume_work_item.sh
  5. scripts/finalize_work_item.sh
  6. scripts/upsert_work_item_progress.sh
  7. scripts/audit_state_system.sh
- Evidence:
  1. The sandbox task was created, paused by an interrupt marker, blocked from illegal advancement, resumed, linked, finalized, and audited.
- Dissent:
  1. This validates state control, not product runtime behavior.
- Risks:
  1. Free-text task fields still rely on disciplined editing.
- Freshness caveats:
  1. Internal-only validation.
- Tradeoffs:
  1. Sandbox execution protects the live repo but does not cover real product runtime.
- Ask from Founder:
  1. none
- Next 7 days:
  1. Extend the same validation style to a real runnable slice.
EOF

  "$script_dir/link_work_item_artifact.sh" \
    --expected-version 8 \
    --operation-id "${validation_id}-link-decision" \
    "$validation_id" \
    "$validation_decision" \
    "decision-pack" \
    "approved" >/dev/null

  replace_field "$validation_item" "Participation records" "risk-office=done"

  "$script_dir/transition_work_item.sh" \
    --expected-from-status in-progress \
    --expected-version 9 \
    --operation-id "${validation_id}-to-review" \
    "$validation_id" \
    review \
    none \
    "risk-office -> workflow-automation" \
    "validation slice review" >/dev/null

  "$script_dir/upsert_work_item_progress.sh" \
    "$validation_id" \
    "Review passed; finalize the work item and verify the audit." \
    "./.agents/skills/harness/scripts/finalize_work_item.sh --expected-from-status review --expected-version 10 $validation_id done" >/dev/null

  "$script_dir/finalize_work_item.sh" \
    --expected-from-status review \
    --expected-version 10 \
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

  latest_board_refresh=$(latest_board_refresh_event_path)
  if [ -z "$latest_board_refresh" ] || [ ! -f "$latest_board_refresh" ]; then
    echo "validation slice failed: missing board refresh ledger event" >&2
    exit 1
  fi

  if [ "$(field_value "$latest_board_refresh" "Actor")" != "validation-slice" ]; then
    echo "validation slice failed: board refresh actor mismatch" >&2
    exit 1
  fi

  board_refresh_targets=$(field_value "$latest_board_refresh" "Targets")
  if value_is_missing "$board_refresh_targets" || ! csv_contains_value "$board_refresh_targets" ".harness/workspace/state/boards/company.md"; then
    echo "validation slice failed: board refresh targets missing company board" >&2
    exit 1
  fi

  "$script_dir/audit_state_system.sh" >/dev/null

  progress_path=$(work_item_progress_path "$validation_id")

  printf 'validation slice: ok\n'
  printf 'work item: %s\n' "$validation_id"
  printf 'progress: %s\n' "$progress_path"
  printf 'decision: %s\n' "$validation_decision"
)

if [ "$keep_tmp" -eq 1 ]; then
  printf 'kept sandbox at %s\n' "$sandbox"
fi
