#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
company_retro_template_path="$repo_root/skills/retro/templates/process-audit.md"
workstream_retro_template_path="$repo_root/skills/retro/templates/workstream-retro.md"

render_company_retro_template() {
  [ -f "$company_retro_template_path" ] || {
    echo "missing template: $company_retro_template_path" >&2
    exit 1
  }

  awk \
    -v retro_date="$date" \
    '
      /^- Date:$/ { $0 = "- Date: " retro_date }
      /^- Scope:$/ { $0 = "- Scope: company" }
      { print }
    ' \
    "$company_retro_template_path"
}

render_workstream_retro_template() {
  workstream_name="$1"

  [ -f "$workstream_retro_template_path" ] || {
    echo "missing template: $workstream_retro_template_path" >&2
    exit 1
  }

  awk \
    -v retro_date="$date" \
    -v workstream_name="$workstream_name" \
    '
      /^- Date:$/ { $0 = "- Date: " retro_date }
      /^- Workstream:$/ { $0 = "- Workstream: " workstream_name }
      { print }
    ' \
    "$workstream_retro_template_path"
}

scope="${1:-}"
label="${2:-retro}"

if [ -z "$scope" ]; then
  echo "usage: $0 <company|workstream> [label]" >&2
  exit 1
fi

require_advanced_governance_runtime_artifact "retro output" || exit 1

slug=$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ "$scope" = "company" ]; then
  target=".harness/workspace/status/process-audits/${date}-${slug}.md"
  render_company_retro_template >"$target"
  echo "$target"
  exit 0
fi

base=".harness/workspace/workstreams/${scope}/workspace/reports/retros"
if [ ! -d "$base" ]; then
  echo "unknown workstream retros path: $base" >&2
  exit 1
fi

target="${base}/${date}-${slug}.md"
if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_workstream_retro_template "$scope" >"$target"

echo "$target"
