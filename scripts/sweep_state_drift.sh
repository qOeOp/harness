#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

stale_days=7
today=$(date +%F)
issues=0

usage() {
  echo "usage: $0 [--stale-days <days>]" >&2
  exit 1
}

date_days_ago() {
  days="$1"
  if date -v-"$days"d +%F >/dev/null 2>&1; then
    date -v-"$days"d +%F
  else
    date -d "-$days days" +%F
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --stale-days)
      [ "$#" -ge 2 ] || usage
      stale_days="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if ! is_nonnegative_integer "$stale_days"; then
  echo "invalid stale-days: $stale_days" >&2
  exit 1
fi

cutoff=$(date_days_ago "$stale_days")

report() {
  issues=1
  echo "$1"
}

for file in $(list_work_items); do
  id=$(field_value "$file" "ID")
  title=$(field_value "$file" "Title")
  status=$(field_value "$file" "Status")
  updated_at=$(field_value "$file" "Updated at")
  deadline=$(field_value "$file" "Deadline")
  founder_escalation=$(field_value "$file" "Founder escalation")
  current_blocker=$(field_value "$file" "Current blocker")
  blocks=$(field_value "$file" "Blocks")
  required_artifacts=$(field_value "$file" "Required artifacts")
  linked_artifacts=$(field_value "$file" "Linked attachments")

  case "$status" in
    backlog|planning|ready|in-progress|review|paused)
      if [ "$updated_at" \< "$cutoff" ]; then
        report "stale active item: $id ($title) last updated $updated_at"
      fi
      ;;
  esac

  if [ "$status" = "in-progress" ]; then
    recovery_sync_state=$(work_item_recovery_sync_state "$id")
    case "$recovery_sync_state" in
      missing)
        report "in-progress item missing progress artifact: $id ($title)"
        ;;
      unlinked)
        report "in-progress item has unlinked progress artifact: $id ($title)"
        ;;
      stale)
        report "in-progress item has stale progress artifact: $id ($title)"
        ;;
    esac
  fi

  case "$status" in
    done|killed)
      blocked_by=$(field_value "$file" "Blocked by")
      next_handoff=$(field_value "$file" "Next handoff")
      if ! value_is_missing "$current_blocker"; then
        report "terminal item still has blocker: $id ($title) -> $current_blocker"
      fi
      if ! value_is_missing "$blocked_by"; then
        report "terminal item still has blocked-by dependencies: $id ($title) -> $blocked_by"
      fi
      if ! value_is_missing "$blocks"; then
        report "terminal item still blocks downstream items: $id ($title) -> $blocks"
      fi
      if ! value_is_missing "$next_handoff"; then
        report "terminal item still has next handoff: $id ($title) -> $next_handoff"
      fi
      ;;
  esac

  if [ "$founder_escalation" = "pending-founder" ] && ! value_is_missing "$deadline" && [ "$deadline" \< "$today" ]; then
    report "overdue founder escalation: $id ($title) deadline $deadline"
  fi

  case "$status" in
    ready|in-progress|review|done)
      if ! value_is_missing "$required_artifacts" && value_is_missing "$linked_artifacts"; then
        report "artifact gate risk: $id ($title) requires artifacts but none are linked"
      fi
      ;;
  esac
done

if [ "$issues" -eq 0 ]; then
  echo "state drift sweep: clean"
  exit 0
fi

exit 1
