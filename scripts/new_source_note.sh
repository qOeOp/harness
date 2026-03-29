#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
. "$script_dir/lib_state.sh"

template_path="$repo_root/skills/research/templates/source-note.md"
artifact_label="source note"
artifact_suffix="source-note"
workspace_dir=".harness/workspace/research/sources"
artifact_type="source-note"

render_template() {
  linked_work_items="$1"
  artifact_date="$2"
  artifact_title="$3"

  [ -f "$template_path" ] || {
    echo "missing template: $template_path" >&2
    exit 1
  }

  awk \
    -v linked_work_items="$linked_work_items" \
    -v artifact_date="$artifact_date" \
    -v artifact_title="$artifact_title" \
    '
      /^- Date:$/ { $0 = "- Date: " artifact_date }
      /^- Source:$/ { $0 = "- Source: " artifact_title }
      /^- Accessed date:$/ { $0 = "- Accessed date: " artifact_date }
      /^- Linked work items:$/ { $0 = "- Linked work items: " linked_work_items }
      /^- Topic:$/ { $0 = "- Topic: " artifact_title }
      { print }
    ' \
    "$template_path"
}

work_item_id=""
promote_shared_writeback=0
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  cat <<EOF >&2
usage: $0 [--work-item <WI-xxxx>] [--promote-shared-writeback|--promote-governance] <topic>
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
    --promote-shared-writeback|--promote-governance)
      promote_shared_writeback=1
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

title="${1:-untitled-source}"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)
resolved_work_item_id=""

if [ "$promote_shared_writeback" -eq 1 ]; then
  if [ -n "$work_item_id" ]; then
    require_work_item "$work_item_id" >/dev/null
  fi
  require_shared_writeback_mode_for_workspace_artifact "$artifact_label" || exit 1
  target="$workspace_dir/${date}-${slug}.md"
else
  if [ -z "$work_item_id" ]; then
    require_explicit_promotion_for_workspace_artifact "$artifact_label" || exit 1
  fi
  resolved_work_item_id="$work_item_id"
fi

if [ -n "$resolved_work_item_id" ]; then
  work_item_id="$resolved_work_item_id"
  require_work_item "$work_item_id" >/dev/null
  ensure_task_directory_skeleton "$work_item_id"
  target="$(canonical_work_item_attachment_sources_dir "$work_item_id")/${date}-${slug}.md"
elif [ "$promote_shared_writeback" -ne 1 ]; then
  require_explicit_promotion_for_workspace_artifact "$artifact_label" || exit 1
fi

mkdir -p "$(dirname "$target")"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_template "${work_item_id:-n/a}" "$date" "$title" >"$target"

if [ -n "$work_item_id" ]; then
  require_explicit_state_actor "$actor" "$0"
  work_item_file=$(require_work_item "$work_item_id")
  expected_version=$(field_value "$work_item_file" "State version")
  "$script_dir/link_work_item_artifact.sh" \
    --expected-version "$expected_version" \
    "$work_item_id" \
    "$target" \
    "$artifact_type" \
    "draft" >/dev/null
fi

echo "$target"
