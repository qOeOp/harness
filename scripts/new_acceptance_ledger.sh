#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
. "$script_dir/lib_state.sh"

template_path="$repo_root/skills/acceptance-review/templates/acceptance-ledger.md"
artifact_label="acceptance ledger"
artifact_suffix="acceptance-ledger"
artifact_type="acceptance-ledger"

render_template() {
  linked_work_items="$1"
  artifact_date="$2"
  artifact_scope="$3"

  [ -f "$template_path" ] || {
    echo "missing template: $template_path" >&2
    exit 1
  }

  awk \
    -v linked_work_items="$linked_work_items" \
    -v artifact_date="$artifact_date" \
    -v artifact_scope="$artifact_scope" \
    '
      /^- Linked work items:$/ { $0 = "- Linked work items: " linked_work_items }
      /^- Date:$/ { $0 = "- Date: " artifact_date }
      /^- Scope:$/ { $0 = "- Scope: " artifact_scope }
      { print }
    ' \
    "$template_path"
}

work_item_id=""
actor="${STATE_ACTOR:-}"
export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"

usage() {
  cat <<EOF >&2
usage: $0 --work-item <WI-xxxx> <scope>

Acceptance ledgers are task-local only.
They do not support shared writeback promotion.
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
    --help|-h)
      usage
      ;;
    *)
      break
      ;;
  esac
done

[ -n "$work_item_id" ] || {
  echo "acceptance ledger requires explicit --work-item; shared promotion is not supported" >&2
  exit 1
}

scope="${1:-acceptance-scope}"
slug=$(printf '%s' "$scope" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

require_work_item "$work_item_id" >/dev/null
ensure_task_directory_skeleton "$work_item_id"
target="$(canonical_work_item_attachments_dir "$work_item_id")/${date}-${slug}-${artifact_suffix}.md"

mkdir -p "$(dirname "$target")"

if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_template "$work_item_id" "$date" "$scope" >"$target"

require_explicit_state_actor "$actor" "$0"
work_item_file=$(require_work_item "$work_item_id")
expected_version=$(field_value "$work_item_file" "State version")
"$script_dir/link_work_item_artifact.sh" \
  --expected-version "$expected_version" \
  "$work_item_id" \
  "$target" \
  "$artifact_type" \
  "draft" >/dev/null

echo "$target"
