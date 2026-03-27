#!/bin/sh
set -eu

usage() {
  cat <<'EOF' >&2
usage: ./scripts/edit_role.sh --slug <role-slug> [options]

optional updates:
  --claude-name <name>
  --claude-description <text>
  --claude-tools <csv>
  --claude-model <model>
  --codex-name <name>
  --codex-description <text>
  --codex-model <model>
  --codex-reasoning-effort <level>
  --codex-sandbox-mode <mode>
  --codex-nicknames <csv>
  --instructions-file <path>    replace Canonical Instructions body with file contents
  --print-current               print current role file and exit
  --no-sync                     do not run sync + audit after edit
EOF
  exit 1
}

frontmatter_value() {
  file="$1"
  key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && index($0, key ": ") == 1 {
      print substr($0, length(key ": ") + 1)
      exit
    }
  ' "$file"
}

slug=""
claude_name=""
claude_description=""
claude_tools=""
claude_model=""
codex_name=""
codex_description=""
codex_model=""
codex_reasoning_effort=""
codex_sandbox_mode=""
codex_nicknames=""
instructions_file=""
print_current=0
do_sync=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --slug) slug="${2:-}"; shift 2 ;;
    --claude-name) claude_name="${2:-}"; shift 2 ;;
    --claude-description) claude_description="${2:-}"; shift 2 ;;
    --claude-tools) claude_tools="${2:-}"; shift 2 ;;
    --claude-model) claude_model="${2:-}"; shift 2 ;;
    --codex-name) codex_name="${2:-}"; shift 2 ;;
    --codex-description) codex_description="${2:-}"; shift 2 ;;
    --codex-model) codex_model="${2:-}"; shift 2 ;;
    --codex-reasoning-effort) codex_reasoning_effort="${2:-}"; shift 2 ;;
    --codex-sandbox-mode) codex_sandbox_mode="${2:-}"; shift 2 ;;
    --codex-nicknames) codex_nicknames="${2:-}"; shift 2 ;;
    --instructions-file) instructions_file="${2:-}"; shift 2 ;;
    --print-current) print_current=1; shift ;;
    --no-sync) do_sync=0; shift ;;
    *) usage ;;
  esac
done

[ -n "$slug" ] || usage

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))
cd "$repo_root"

if [ -f "SKILL.md" ] && [ -d "roles" ]; then
  role_file="roles/$slug.md"
elif [ -f ".agents/skills/harness/SKILL.md" ] && [ -d ".agents/skills/harness/roles" ]; then
  role_file=".agents/skills/harness/roles/$slug.md"
else
  echo "unable to resolve harness repo layout" >&2
  exit 1
fi

[ -f "$role_file" ] || {
  echo "missing role: $role_file" >&2
  exit 1
}

if [ "$print_current" -eq 1 ]; then
  cat "$role_file"
  exit 0
fi

if [ -n "$instructions_file" ] && [ ! -f "$instructions_file" ]; then
  echo "missing instructions file: $instructions_file" >&2
  exit 1
fi

[ -n "$claude_name" ] || claude_name=$(frontmatter_value "$role_file" "claude_name")
[ -n "$claude_description" ] || claude_description=$(frontmatter_value "$role_file" "claude_description")
[ -n "$claude_tools" ] || claude_tools=$(frontmatter_value "$role_file" "claude_tools")
[ -n "$claude_model" ] || claude_model=$(frontmatter_value "$role_file" "claude_model")
[ -n "$codex_name" ] || codex_name=$(frontmatter_value "$role_file" "codex_name")
[ -n "$codex_description" ] || codex_description=$(frontmatter_value "$role_file" "codex_description")
[ -n "$codex_model" ] || codex_model=$(frontmatter_value "$role_file" "codex_model")
[ -n "$codex_reasoning_effort" ] || codex_reasoning_effort=$(frontmatter_value "$role_file" "codex_reasoning_effort")
[ -n "$codex_sandbox_mode" ] || codex_sandbox_mode=$(frontmatter_value "$role_file" "codex_sandbox_mode")
[ -n "$codex_nicknames" ] || codex_nicknames=$(frontmatter_value "$role_file" "codex_nicknames")

claude_file=$(frontmatter_value "$role_file" "claude_file")
codex_file=$(frontmatter_value "$role_file" "codex_file")

if [ -n "$instructions_file" ]; then
  instructions_body=$(cat "$instructions_file")
else
  instructions_body=$(awk 'seen_heading {print} /^## Canonical Instructions$/ {seen_heading=1; next}' "$role_file" | sed '/./,$!d')
fi

cat >"$role_file" <<EOF
---
schema_version: 1
slug: $slug
claude_file: $claude_file
claude_name: $claude_name
claude_description: $claude_description
claude_tools: $claude_tools
claude_model: $claude_model
codex_file: $codex_file
codex_name: $codex_name
codex_description: $codex_description
codex_model: $codex_model
codex_reasoning_effort: $codex_reasoning_effort
codex_sandbox_mode: $codex_sandbox_mode
codex_nicknames: $codex_nicknames
---

## Canonical Instructions

$instructions_body
EOF

if [ "$do_sync" -eq 1 ]; then
  "$script_dir/sync_agent_projections.sh" >/dev/null
  "$script_dir/audit_role_schema.sh" >/dev/null
fi

echo "$role_file"
