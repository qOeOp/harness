#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
. "$script_dir/lib_state.sh"

decision_template_path="$repo_root/skills/decision-pack/templates/decision-pack.md"

render_decision_pack_template() {
  linked_work_items="$1"
  decision_date="$2"
  decision_title="$3"

  [ -f "$decision_template_path" ] || {
    echo "missing template: $decision_template_path" >&2
    exit 1
  }

  awk \
    -v linked_work_items="$linked_work_items" \
    -v decision_date="$decision_date" \
    -v decision_title="$decision_title" \
    '
      /^- Linked work items:$/ { $0 = "- Linked work items: " linked_work_items }
      /^- Date:$/ { $0 = "- Date: " decision_date }
      /^- Decision:$/ { $0 = "- Decision: " decision_title }
      { print }
    ' \
    "$decision_template_path"
}

work_item_id=""
promote_governance=0
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  cat <<EOF >&2
usage: $0 [--work-item <WI-xxxx>] [--promote-governance] [company|<workstream>] <title>

Decision packs default to task-local routing.
Pass --work-item explicitly for task-local routing.
Use --promote-governance only for cross-task decisions in advanced governance mode.
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --work-item)
      [ "$#" -ge 2 ] || usage
      work_item_id="$2"
      shift 2
      ;;
    --promote-governance)
      promote_governance=1
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -le 1 ]; then
  scope="company"
  title="${1:-untitled-decision}"
else
  scope="$1"
  title="${2:-untitled-decision}"
fi
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
resolved_work_item_id=""

if [ "$promote_governance" -eq 1 ]; then
  if [ -n "$work_item_id" ]; then
    require_work_item "$work_item_id" >/dev/null
  fi
  if [ "$scope" = "company" ]; then
    require_governance_mode_for_workspace_artifact "decision pack" || exit 1
    target=".harness/workspace/decisions/log/${date}-${slug}.md"
  else
    require_governance_mode_for_workspace_artifact "workstream decision pack" || exit 1
    target=".harness/workspace/workstreams/${scope}/workspace/outputs/${date}-${slug}.md"
  fi
else
  if [ -z "$work_item_id" ]; then
    require_explicit_promotion_for_workspace_artifact "decision pack" || exit 1
  fi
  resolved_work_item_id="$work_item_id"
fi

if [ -n "$resolved_work_item_id" ]; then
  work_item_id="$resolved_work_item_id"
  require_work_item "$work_item_id" >/dev/null
  ensure_task_directory_skeleton "$work_item_id"
  target="$(canonical_work_item_attachments_dir "$work_item_id")/${date}-${slug}-decision-pack.md"
elif [ "$promote_governance" -ne 1 ]; then
  require_explicit_promotion_for_workspace_artifact "decision pack" || exit 1
fi

mkdir -p "$(dirname "$target")"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_decision_pack_template "${work_item_id:-n/a}" "$date" "$title" >"$target"

if [ -n "$work_item_id" ]; then
  require_explicit_state_actor "$actor" "$0"
  work_item_file=$(require_work_item "$work_item_id")
  expected_version=$(field_value "$work_item_file" "State version")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    "$work_item_id" \
    "$target" \
    "decision-pack" \
    "draft" >/dev/null
fi

echo "$target"
