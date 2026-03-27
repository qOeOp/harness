#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
company_retro_template_path="$repo_root/skills/retro/templates/process-audit.md"
department_retro_template_path="$repo_root/skills/retro/templates/department-retro.md"

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

render_department_retro_template() {
  department_name="$1"

  [ -f "$department_retro_template_path" ] || {
    echo "missing template: $department_retro_template_path" >&2
    exit 1
  }

  awk \
    -v retro_date="$date" \
    -v department_name="$department_name" \
    '
      /^- Date:$/ { $0 = "- Date: " retro_date }
      /^- Department:$/ { $0 = "- Department: " department_name }
      { print }
    ' \
    "$department_retro_template_path"
}

scope="${1:-}"
label="${2:-retro}"

if [ -z "$scope" ]; then
  echo "usage: $0 <company|department> [label]" >&2
  exit 1
fi

slug=$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
date=$(date +%F)

if [ "$scope" = "company" ]; then
  target=".harness/workspace/status/process-audits/${date}-${slug}.md"
  render_company_retro_template >"$target"
  echo "$target"
  exit 0
fi

base=".harness/workspace/departments/${scope}/workspace/reports/retros"
if [ ! -d "$base" ]; then
  echo "unknown department retros path: $base" >&2
  exit 1
fi

target="${base}/${date}-${slug}.md"
if [ -e "$target" ]; then
  echo "exists: $target" >&2
  exit 1
fi

render_department_retro_template "$scope" >"$target"

echo "$target"
