#!/bin/sh
set -eu

usage() {
  cat <<'EOF' >&2
usage: ./scripts/new_role.sh --slug <role-slug> --claude-description <text> --codex-description <text> [options]

required:
  --slug <slug>
  --claude-description <text>
  --codex-description <text>

optional:
  --print-template                    print a role-design brief template and exit
  --consumer-runtime <name>           resolve a consumer runtime root from the user-owned route table
  --consumer-runtime-root <path>      create a consumer-local runtime role under <path>/.harness/workspace/roles/
  --consumer-runtime-table <path>     override the route table used by --consumer-runtime
  --runtime-root <path>               deprecated alias for --consumer-runtime-root
  --claude-name <name>                 default: <slug>
  --claude-tools <csv>                default: Read, Glob, Grep, Bash
  --claude-model <model>              default: sonnet
  --codex-name <name>                 default: <slug without -lead, hyphens -> underscores>
  --codex-model <model>               default: gpt-5.4-mini
  --codex-reasoning-effort <level>    default: medium
  --codex-sandbox-mode <mode>         default: read-only
  --codex-nicknames <csv>             default: auto-generated from slug
  --default-skills <csv>              optional default skill affinity list
  --secondary-skills <csv>            optional secondary skill affinity list
  --policy-allowed-entrypoints <csv>  optional role policy extension
  --policy-allowed-actions <csv>      optional role policy extension
  --policy-mutation-actions <csv>     optional role policy extension
  --policy-write-roots <csv>          optional role policy extension
  --policy-forbidden-roots <csv>      optional role policy extension
  --policy-required-artifact-type <t> optional role policy extension
  --policy-required-stage <name>      optional role policy extension
  --instructions-file <path>          use file contents as Canonical Instructions body
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
default_skills=""
secondary_skills=""
policy_allowed_entrypoints=""
policy_allowed_actions=""
policy_mutation_actions=""
policy_write_roots=""
policy_forbidden_roots=""
policy_required_artifact_type=""
policy_required_stage=""
instructions_file=""
runtime_root=""
runtime_name=""
route_table_path=""
deprecated_runtime_root_flag=0
print_template=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --print-template) print_template=1; shift ;;
    --consumer-runtime) runtime_name="${2:-}"; shift 2 ;;
    --consumer-runtime-root) runtime_root="${2:-}"; shift 2 ;;
    --consumer-runtime-table) route_table_path="${2:-}"; shift 2 ;;
    --runtime-root)
      runtime_root="${2:-}"
      deprecated_runtime_root_flag=1
      shift 2
      ;;
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
    --default-skills) default_skills="${2:-}"; shift 2 ;;
    --secondary-skills) secondary_skills="${2:-}"; shift 2 ;;
    --policy-allowed-entrypoints) policy_allowed_entrypoints="${2:-}"; shift 2 ;;
    --policy-allowed-actions) policy_allowed_actions="${2:-}"; shift 2 ;;
    --policy-mutation-actions) policy_mutation_actions="${2:-}"; shift 2 ;;
    --policy-write-roots) policy_write_roots="${2:-}"; shift 2 ;;
    --policy-forbidden-roots) policy_forbidden_roots="${2:-}"; shift 2 ;;
    --policy-required-artifact-type) policy_required_artifact_type="${2:-}"; shift 2 ;;
    --policy-required-stage) policy_required_stage="${2:-}"; shift 2 ;;
    --instructions-file) instructions_file="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$slug" ] || usage
[ -n "$claude_description" ] || usage
[ -n "$codex_description" ] || usage

case "$slug" in
  *[!a-z0-9-]*|'') echo "invalid slug: $slug" >&2; exit 1 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_consumer_runtime.sh"
. "$script_dir/lib_consumer_runtime_routes.sh"
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))
cd "$repo_root"

template_path="$repo_root/docs/templates/role-design-brief.md"

[ -z "$runtime_root" ] || [ -z "$runtime_name" ] || {
  echo "use either --consumer-runtime or --consumer-runtime-root, not both." >&2
  exit 1
}

if [ -n "$runtime_name" ]; then
  runtime_root=$(resolve_consumer_runtime_root_from_table "$runtime_name" "$route_table_path")
fi

if [ -n "$runtime_root" ]; then
  resolved_runtime_root=$(normalize_consumer_runtime_root "$runtime_root")
  [ -n "$resolved_runtime_root" ] || {
    echo "unable to resolve runtime root: $runtime_root" >&2
    exit 1
  }
  if [ "$deprecated_runtime_root_flag" -eq 1 ]; then
    echo "warning: --runtime-root is deprecated; use --consumer-runtime-root instead." >&2
  fi
  require_advanced_governance_consumer_runtime_root "$resolved_runtime_root" "new_role.sh" "$repo_root"
  role_dir="$resolved_runtime_root/.harness/workspace/roles"
  instructions_heading="## Runtime Instructions"
else
  if [ -f "SKILL.md" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
    role_dir="$repo_root/roles"
    instructions_heading="## Canonical Instructions"
  else
    echo "new_role.sh only runs in the framework source repo unless --consumer-runtime or --consumer-runtime-root is provided." >&2
    exit 1
  fi
fi

if [ "$print_template" -eq 1 ]; then
  cat "$template_path"
  exit 0
fi

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

policy_enabled=0
for value in \
  "$policy_allowed_entrypoints" \
  "$policy_allowed_actions" \
  "$policy_mutation_actions" \
  "$policy_write_roots" \
  "$policy_forbidden_roots" \
  "$policy_required_artifact_type" \
  "$policy_required_stage"
do
  if [ -n "$value" ]; then
    policy_enabled=1
    break
  fi
done

if [ "$policy_enabled" -eq 1 ]; then
  [ -n "$policy_allowed_entrypoints" ] || policy_allowed_entrypoints="none"
  [ -n "$policy_allowed_actions" ] || policy_allowed_actions="none"
  [ -n "$policy_mutation_actions" ] || policy_mutation_actions="none"
  [ -n "$policy_write_roots" ] || policy_write_roots="none"
  [ -n "$policy_forbidden_roots" ] || policy_forbidden_roots="none"
  [ -n "$policy_required_artifact_type" ] || policy_required_artifact_type="none"
  [ -n "$policy_required_stage" ] || policy_required_stage="none"
  policy_block=$(cat <<EOF
policy_allowed_entrypoints: $policy_allowed_entrypoints
policy_allowed_actions: $policy_allowed_actions
policy_mutation_actions: $policy_mutation_actions
policy_write_roots: $policy_write_roots
policy_forbidden_roots: $policy_forbidden_roots
policy_required_artifact_type: $policy_required_artifact_type
policy_required_stage: $policy_required_stage
EOF
)
else
  policy_block=""
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
default_skills: ${default_skills:-none}
secondary_skills: ${secondary_skills:-none}
$policy_block
---

${instructions_heading}

$instructions_body
EOF

"$script_dir/audit_role_schema.sh" --quiet --role-dir "$role_dir"

echo "$role_file"
