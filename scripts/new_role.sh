#!/bin/sh
set -eu

usage() {
  cat <<'EOF' >&2
usage: ./.agents/skills/harness/scripts/new_role.sh --slug <role-slug> --claude-description <text> --codex-description <text> [options]

required:
  --slug <slug>
  --claude-description <text>
  --codex-description <text>

optional:
  --print-template                    print a role-design brief template and exit
  --claude-name <name>                 default: <slug>
  --claude-tools <csv>                default: Read, Glob, Grep, Bash
  --claude-model <model>              default: sonnet
  --codex-name <name>                 default: <slug without -lead, hyphens -> underscores>
  --codex-model <model>               default: gpt-5.4-mini
  --codex-reasoning-effort <level>    default: medium
  --codex-sandbox-mode <mode>         default: read-only
  --codex-nicknames <csv>             default: auto-generated from slug
  --instructions-file <path>          use file contents as Canonical Instructions body
  --no-sync                           do not run sync + audit after scaffold
EOF
  exit 1
}

slug=""
claude_name=""
claude_description=""
claude_tools="Read, Glob, Grep, Bash"
claude_model="sonnet"
codex_name=""
codex_description=""
codex_model="gpt-5.4-mini"
codex_reasoning_effort="medium"
codex_sandbox_mode="read-only"
codex_nicknames=""
instructions_file=""
do_sync=1
print_template=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --print-template) print_template=1; shift ;;
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
    --no-sync) do_sync=0; shift ;;
    *) usage ;;
  esac
done

if [ "$print_template" -eq 1 ]; then
  cat ".agents/skills/harness/docs/templates/role-design-brief.md"
  exit 0
fi

[ -n "$slug" ] || usage
[ -n "$claude_description" ] || usage
[ -n "$codex_description" ] || usage

case "$slug" in
  *[!a-z0-9-]*|'') echo "invalid slug: $slug" >&2; exit 1 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../../.." && pwd)
cd "$repo_root"

role_dir=".agents/skills/harness/roles"
role_file="$role_dir/$slug.md"

[ ! -e "$role_file" ] || {
  echo "role already exists: $role_file" >&2
  exit 1
}

if [ -n "$instructions_file" ] && [ ! -f "$instructions_file" ]; then
  echo "missing instructions file: $instructions_file" >&2
  exit 1
fi

default_codex_stem=$(printf '%s' "$slug" | sed 's/-lead$//')
default_codex_name=$(printf '%s' "$default_codex_stem" | tr '-' '_')

[ -n "$claude_name" ] || claude_name="$slug"
[ -n "$codex_name" ] || codex_name="$default_codex_name"

claude_file="$slug.md"
codex_file="$default_codex_stem.toml"

if [ -z "$codex_nicknames" ]; then
  base_one=$(printf '%s' "$default_codex_stem" | awk -F- '{print $1}')
  base_two=$(printf '%s' "$default_codex_stem" | awk -F- '{print $NF}')
  base_three=$(printf '%s' "$slug" | tr '-' ' ' | awk '{print $1 $NF}')
  codex_nicknames=$(printf '%s, %s, %s' "$base_one" "$base_two" "$base_three" | sed 's/  */ /g')
fi

mkdir -p "$role_dir"

if [ -n "$instructions_file" ]; then
  instructions_body=$(cat "$instructions_file")
else
  instructions_body=$(cat <<'EOF'
- 在这里写角色的核心职责。
- 在这里写不能做的事。
- 在这里写必须优先读取的文档。
- 在这里写对 volatile 外部议题的默认动作。
- 在这里写输出契约。
EOF
)
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
