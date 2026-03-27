#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
. "$script_dir/lib_state.sh"

dispatch_template_path="$repo_root/skills/research/templates/research-dispatch.md"

render_research_dispatch_template() {
  linked_work_items="$1"
  dispatch_date="$2"
  dispatch_title="$3"

  [ -f "$dispatch_template_path" ] || {
    echo "missing template: $dispatch_template_path" >&2
    exit 1
  }

  awk \
    -v linked_work_items="$linked_work_items" \
    -v dispatch_date="$dispatch_date" \
    -v dispatch_title="$dispatch_title" \
    '
      /^- Linked work items:$/ { $0 = "- Linked work items: " linked_work_items }
      /^- Date:$/ { $0 = "- Date: " dispatch_date }
      /^- Topic:$/ { $0 = "- Topic: " dispatch_title }
      { print }
    ' \
    "$dispatch_template_path"
}

work_item_id=""
promote_governance=0
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  cat <<EOF >&2
usage: $0 [--work-item <WI-xxxx>] [--promote-governance] <title>

Research dispatches default to task-local routing.
Pass --work-item explicitly for task-local routing.
Use --promote-governance only for cross-task dispatches in advanced governance mode.
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

title="${1:-untitled-dispatch}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
resolved_work_item_id=""

if [ "$promote_governance" -eq 1 ]; then
  if [ -n "$work_item_id" ]; then
    require_work_item "$work_item_id" >/dev/null
  fi
  require_governance_mode_for_workspace_artifact "research dispatch" || exit 1
  target=".harness/workspace/research/dispatches/${date}-${slug}.md"
else
  if [ -z "$work_item_id" ]; then
    require_explicit_promotion_for_workspace_artifact "research dispatch" || exit 1
  fi
  resolved_work_item_id="$work_item_id"
fi

if [ -n "$resolved_work_item_id" ]; then
  work_item_id="$resolved_work_item_id"
  require_work_item "$work_item_id" >/dev/null
  ensure_task_directory_skeleton "$work_item_id"
  target="$(canonical_work_item_attachments_dir "$work_item_id")/${date}-${slug}-research-dispatch.md"
elif [ "$promote_governance" -ne 1 ]; then
  require_explicit_promotion_for_workspace_artifact "research dispatch" || exit 1
fi

mkdir -p "$(dirname "$target")"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_research_dispatch_template "${work_item_id:-n/a}" "$date" "$title" >"$target"

if [ -n "$work_item_id" ]; then
  require_explicit_state_actor "$actor" "$0"
  work_item_file=$(require_work_item "$work_item_id")
  expected_version=$(field_value "$work_item_file" "State version")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    "$work_item_id" \
    "$target" \
    "research-dispatch" \
    "draft" >/dev/null
fi

echo "$target"
