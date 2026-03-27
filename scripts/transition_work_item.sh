#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

actor="${STATE_ACTOR:-}"
require_explicit_state_actor "$actor" "$0"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"
expected_from_status=""
expected_version=""
operation_id=""
allow_terminal_transition="${STATE_ALLOW_TERMINAL_TRANSITION:-0}"
interrupt_marker=""
resume_target=""

usage() {
  printf 'usage: %s --expected-from-status <status> --expected-version <version> [--operation-id <id>] [--interrupt-marker <marker>] [--resume-target <status>] <work-item-id> <next-status> [current-blocker] [next-handoff] [reason]\n' "$(default_harness_command "transition_work_item.sh")" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-from-status)
      [ "$#" -ge 2 ] || usage
      expected_from_status="$2"
      shift 2
      ;;
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
    --interrupt-marker)
      [ "$#" -ge 2 ] || usage
      interrupt_marker="$2"
      shift 2
      ;;
    --resume-target)
      [ "$#" -ge 2 ] || usage
      resume_target="$2"
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

id="${1:-}"
next_status="${2:-}"
current_blocker="${3:-}"
next_handoff="${4:-}"
reason="${5:-state transition}"

if [ -z "$id" ] || [ -z "$next_status" ]; then
  usage
fi

if ! is_valid_work_item_status "$next_status"; then
  echo "invalid status: $next_status" >&2
  exit 1
fi

if [ -z "$expected_from_status" ] || [ -z "$expected_version" ]; then
  usage
fi

if ! is_valid_work_item_status "$expected_from_status"; then
  echo "invalid expected-from-status: $expected_from_status" >&2
  exit 1
fi

if ! is_nonnegative_integer "$expected_version"; then
  echo "invalid expected-version: $expected_version" >&2
  exit 1
fi

case "$next_status" in
  done|killed)
    if [ "$allow_terminal_transition" != "1" ]; then
      echo "terminal transitions require $(default_harness_command "finalize_work_item.sh") --expected-from-status $expected_from_status --expected-version $expected_version $id $next_status [current-blocker] [next-handoff] [reason]" >&2
      exit 1
    fi
    ;;
esac

acquire_work_item_lock "$id"
file=$(require_work_item_for_write "$id")
current_status=$(field_value "$file" "Status")
current_version=$(field_value "$file" "State version")
last_operation_id=$(field_value "$file" "Last operation ID")
last_transition_event=$(field_value "$file" "Last transition event")
objective=$(field_value "$file" "Objective")
ready_criteria=$(field_value "$file" "Ready criteria")
done_criteria=$(field_value "$file" "Done criteria")
required_artifacts=$(field_value "$file" "Required artifacts")
existing_blocker=$(field_value "$file" "Current blocker")
founder_escalation=$(field_value "$file" "Founder escalation")
existing_interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")
existing_resume_target=$(field_value_or_none "$file" "Resume target")
owner=$(field_value_or_none "$file" "Owner")
current_assignee=$(field_value_or_none "$file" "Assignee")
current_worktree=$(field_value_or_none "$file" "Worktree")
current_claimed_at=$(field_value_or_none "$file" "Claimed at")
current_claim_expires_at=$(field_value_or_none "$file" "Claim expires at")
current_archived_at=$(field_value_or_none "$file" "Archived at")
current_lease_version=$(field_value_or_none "$file" "Lease version")

if ! is_nonnegative_integer "$current_lease_version"; then
  current_lease_version="0"
fi

if [ -n "$interrupt_marker" ] && ! is_valid_interrupt_marker "$interrupt_marker"; then
  echo "invalid interrupt marker: $interrupt_marker" >&2
  exit 1
fi

if [ -n "$resume_target" ] && ! is_valid_resume_target "$resume_target"; then
  echo "invalid resume target: $resume_target" >&2
  exit 1
fi

if ! is_nonnegative_integer "$current_version"; then
  echo "invalid current state version in $file: $current_version" >&2
  exit 1
fi

if [ -z "$operation_id" ]; then
  operation_id=$(default_operation_id "$id" "$current_status-to-$next_status")
fi

if ! transition_allowed "$current_status" "$next_status"; then
  echo "invalid transition: $current_status -> $next_status" >&2
  exit 1
fi

next_interrupt_marker="none"
next_resume_target="none"
event_type=$(transition_event_type_for_status_change "$current_status" "$next_status")

case "$next_status" in
  paused)
    if value_is_missing "$interrupt_marker" || [ "$interrupt_marker" = "none" ]; then
      echo "transition to paused requires --interrupt-marker <manual-review-required|founder-review-required|risk-review-required>" >&2
      exit 1
    fi

    if [ -z "$resume_target" ]; then
      resume_target="$current_status"
    fi

    if value_is_missing "$resume_target" || [ "$resume_target" = "paused" ]; then
      echo "transition to paused requires a non-paused resume target" >&2
      exit 1
    fi

    next_interrupt_marker="$interrupt_marker"
    next_resume_target="$resume_target"

    if [ -z "$current_blocker" ]; then
      current_blocker=$(interrupt_default_blocker "$next_interrupt_marker")
    fi
    ;;
  *)
    case "$current_status" in
      paused)
        if value_is_missing "$existing_interrupt_marker" || value_is_missing "$existing_resume_target"; then
          echo "paused work item is missing interrupt metadata: $id" >&2
          exit 1
        fi

        if [ "$next_status" = "killed" ]; then
          if [ -n "$interrupt_marker" ] && [ "$interrupt_marker" != "none" ]; then
            echo "killing a paused work item must clear interrupt marker" >&2
            exit 1
          fi
          if [ -n "$resume_target" ] && [ "$resume_target" != "none" ]; then
            echo "killing a paused work item must clear resume target" >&2
            exit 1
          fi
          next_interrupt_marker="none"
          next_resume_target="none"
        else
          if [ "$next_status" != "$existing_resume_target" ]; then
            echo "paused work item can only resume to $existing_resume_target, got: $next_status" >&2
            exit 1
          fi
          if [ -n "$interrupt_marker" ] && [ "$interrupt_marker" != "none" ]; then
            echo "resuming a paused work item must clear interrupt marker" >&2
            exit 1
          fi
          if [ -n "$resume_target" ] && [ "$resume_target" != "none" ]; then
            echo "resuming a paused work item must clear resume target" >&2
            exit 1
          fi
          next_interrupt_marker="none"
          next_resume_target="none"
          if [ -z "$current_blocker" ]; then
            current_blocker="none"
          fi
          if [ -z "$next_handoff" ]; then
            next_handoff="none"
          fi
        fi
        ;;
      *)
        if [ -n "$interrupt_marker" ] && [ "$interrupt_marker" != "none" ]; then
          echo "interrupt marker can only be set when transitioning to paused" >&2
          exit 1
        fi
        if [ -n "$resume_target" ] && [ "$resume_target" != "none" ]; then
          echo "resume target can only be set when transitioning to paused" >&2
          exit 1
        fi
        ;;
    esac
    ;;
esac

if [ -n "$operation_id" ] && [ "$last_operation_id" = "$operation_id" ] && [ -f "$last_transition_event" ]; then
  last_to=$(field_value "$last_transition_event" "To")
  last_expected_from=$(field_value "$last_transition_event" "Expected from")
  last_expected_version=$(field_value "$last_transition_event" "Expected version")
  last_interrupt_marker=$(field_value_or_none "$last_transition_event" "Interrupt marker")
  last_resume_target=$(field_value_or_none "$last_transition_event" "Resume target")
  if [ "$last_to" = "$next_status" ] && [ "$last_expected_from" = "$expected_from_status" ] && [ "$last_expected_version" = "$expected_version" ] && [ "$last_interrupt_marker" = "$next_interrupt_marker" ] && [ "$last_resume_target" = "$next_resume_target" ]; then
    echo "$file"
    exit 0
  fi
  echo "operation id already used for a different transition: $operation_id" >&2
  exit 1
fi

if [ "$expected_from_status" != "$current_status" ]; then
  echo "expected-from-status mismatch: wanted $expected_from_status but found $current_status" >&2
  exit 1
fi

if [ "$expected_version" != "$current_version" ]; then
  echo "expected-version mismatch: wanted $expected_version but found $current_version" >&2
  exit 1
fi

case "$next_status" in
  ready)
    if value_is_missing "$objective"; then
      echo "cannot transition to ready without Objective" >&2
      exit 1
    fi
    if value_is_missing "$ready_criteria"; then
      echo "cannot transition to ready without Ready criteria" >&2
      exit 1
    fi
    if ! required_departments_satisfied "$file" "ready"; then
      echo "cannot transition to ready until all required departments are assigned in Participation records" >&2
      exit 1
    fi
    ;;
  done)
    if value_is_missing "$objective"; then
      echo "cannot transition to done without Objective" >&2
      exit 1
    fi
    if value_is_missing "$done_criteria"; then
      echo "cannot transition to done without Done criteria" >&2
      exit 1
    fi
    if ! required_departments_satisfied "$file" "done"; then
      echo "cannot transition to done until all required departments are marked done" >&2
      exit 1
    fi
    if [ "$founder_escalation" = "pending-founder" ]; then
      echo "cannot transition to done while Founder escalation is pending-founder" >&2
      exit 1
    fi
    if ! value_is_missing "$required_artifacts" && ! required_artifacts_satisfied "$file"; then
      echo "cannot transition to done until all required artifacts are linked with approved/active-equivalent status" >&2
      exit 1
    fi
    if ! value_is_missing "$existing_blocker"; then
      echo "cannot transition to done while Current blocker is not none" >&2
      exit 1
    fi
    if [ -n "$current_blocker" ] && [ "$current_blocker" != "none" ]; then
      echo "cannot transition to done with a new blocker" >&2
      exit 1
    fi
    ;;
esac

next_version=$((current_version + 1))
next_assignee="$current_assignee"
next_worktree="$current_worktree"
next_claimed_at="$current_claimed_at"
next_claim_expires_at="$current_claim_expires_at"
next_lease_version="$current_lease_version"

case "$next_status" in
  in-progress)
    next_assignee="$actor"
    next_worktree=$(pwd -P)
    next_claimed_at=$(now_iso_timestamp)
    next_claim_expires_at="none"
    next_lease_version=$((current_lease_version + 1))
    ;;
  paused)
    :
    ;;
  *)
    if ! value_is_missing "$current_assignee" || ! value_is_missing "$current_worktree" || ! value_is_missing "$current_claimed_at"; then
      next_assignee="none"
      next_worktree="none"
      next_claimed_at="none"
      next_claim_expires_at="none"
      next_lease_version=$((current_lease_version + 1))
    fi
    ;;
esac

case "$next_status" in
  in-progress|paused)
    if ! value_is_missing "$next_assignee"; then
      next_stage_owner="$next_assignee"
    else
      next_stage_owner="$owner"
    fi
    ;;
  *)
    next_stage_owner=$(default_stage_owner_for_status "$file" "$next_status" "$actor")
    ;;
esac

next_stage_role=$(default_stage_role_for_status "$next_status")
next_gate=$(default_next_gate_for_status "$next_status")
next_archived_at="$current_archived_at"

case "$next_status" in
  archived)
    next_archived_at=$(now_iso_timestamp)
    ;;
  *)
    next_archived_at="none"
    ;;
esac

event_path=$(write_transition_event "$id" "$current_status" "$next_status" "$actor" "$reason" "${current_blocker:-$existing_blocker}" "${next_handoff:-none}" "$operation_id" "$expected_from_status" "$expected_version" "$current_version" "$next_version" "$next_interrupt_marker" "$next_resume_target" "$event_type")
set -- "$file" \
  "Status" "$next_status" \
  "Updated at" "$(date +%F)" \
  "State version" "$next_version" \
  "Last operation ID" "$operation_id" \
  "Assignee" "$next_assignee" \
  "Worktree" "$next_worktree" \
  "Claimed at" "$next_claimed_at" \
  "Claim expires at" "$next_claim_expires_at" \
  "Lease version" "$next_lease_version" \
  "Current stage owner" "$next_stage_owner" \
  "Current stage role" "$next_stage_role" \
  "Next gate" "$next_gate" \
  "Archived at" "$next_archived_at" \
  "Interrupt marker" "$next_interrupt_marker" \
  "Resume target" "$next_resume_target" \
  "Last transition event" "$event_path"

if [ -n "$current_blocker" ]; then
  set -- "$@" "Current blocker" "$current_blocker"
fi

if [ -n "$next_handoff" ]; then
  set -- "$@" "Next handoff" "$next_handoff"
fi

rewrite_work_item_header_snapshot "$@"
sync_recovery_snapshot_if_present "$file"
refresh_boards_if_enabled

echo "$file"
