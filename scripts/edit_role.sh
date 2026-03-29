#!/bin/sh
set -eu

usage() {
  cat <<'EOF' >&2
usage: ./scripts/edit_role.sh --slug <role-slug> [options]

optional updates:
  --consumer-runtime <name>        resolve a consumer runtime root from the user-owned route table
  --consumer-runtime-root <path>   edit a consumer-local runtime role under <path>/.harness/workspace/roles/
  --consumer-runtime-table <path>  override the route table used by --consumer-runtime
  --runtime-root <path>            deprecated alias for --consumer-runtime-root
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
  --default-skills <csv>
  --secondary-skills <csv>
  --policy-allowed-entrypoints <csv>
  --policy-allowed-actions <csv>
  --policy-mutation-actions <csv>
  --policy-write-roots <csv>
  --policy-forbidden-roots <csv>
  --policy-required-artifact-type <t>
  --policy-required-stage <name>
  --instructions-file <path>    replace Canonical Instructions body with file contents
  --print-current               print current role file and exit
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
runtime_root=""
runtime_name=""
route_table_path=""
deprecated_runtime_root_flag=0
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
print_current=0
while [ "$#" -gt 0 ]; do
  case "$1" in
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
    --print-current) print_current=1; shift ;;
    *) usage ;;
  esac
done

[ -n "$slug" ] || usage

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_consumer_runtime.sh"
. "$script_dir/lib_consumer_runtime_routes.sh"
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))
cd "$repo_root"

current_heading() {
  file="$1"
  awk '
    /^## Canonical Instructions$/ { print "## Canonical Instructions"; exit }
    /^## Runtime Instructions$/ { print "## Runtime Instructions"; exit }
  ' "$file"
}

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
  require_shared_writeback_consumer_runtime_root "$resolved_runtime_root" "edit_role.sh" "$repo_root"
  role_file="$resolved_runtime_root/.harness/workspace/roles/$slug.md"
  default_heading="## Runtime Instructions"
else
  if [ -f "SKILL.md" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
    role_file="$repo_root/roles/$slug.md"
    default_heading="## Canonical Instructions"
  else
    echo "edit_role.sh only runs in the framework source repo unless --consumer-runtime or --consumer-runtime-root is provided." >&2
    exit 1
  fi
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
[ -n "$default_skills" ] || default_skills=$(frontmatter_value "$role_file" "default_skills")
[ -n "$secondary_skills" ] || secondary_skills=$(frontmatter_value "$role_file" "secondary_skills")
current_policy_allowed_entrypoints=$(frontmatter_value "$role_file" "policy_allowed_entrypoints")
current_policy_allowed_actions=$(frontmatter_value "$role_file" "policy_allowed_actions")
current_policy_mutation_actions=$(frontmatter_value "$role_file" "policy_mutation_actions")
current_policy_write_roots=$(frontmatter_value "$role_file" "policy_write_roots")
current_policy_forbidden_roots=$(frontmatter_value "$role_file" "policy_forbidden_roots")
current_policy_required_artifact_type=$(frontmatter_value "$role_file" "policy_required_artifact_type")
current_policy_required_stage=$(frontmatter_value "$role_file" "policy_required_stage")

claude_file=$(frontmatter_value "$role_file" "claude_file")
codex_file=$(frontmatter_value "$role_file" "codex_file")
heading=$(current_heading "$role_file")
[ -n "$heading" ] || heading="$default_heading"

policy_enabled=0
for value in \
  "$current_policy_allowed_entrypoints" \
  "$current_policy_allowed_actions" \
  "$current_policy_mutation_actions" \
  "$current_policy_write_roots" \
  "$current_policy_forbidden_roots" \
  "$current_policy_required_artifact_type" \
  "$current_policy_required_stage" \
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
  [ -n "$policy_allowed_entrypoints" ] || policy_allowed_entrypoints="${current_policy_allowed_entrypoints:-none}"
  [ -n "$policy_allowed_actions" ] || policy_allowed_actions="${current_policy_allowed_actions:-none}"
  [ -n "$policy_mutation_actions" ] || policy_mutation_actions="${current_policy_mutation_actions:-none}"
  [ -n "$policy_write_roots" ] || policy_write_roots="${current_policy_write_roots:-none}"
  [ -n "$policy_forbidden_roots" ] || policy_forbidden_roots="${current_policy_forbidden_roots:-none}"
  [ -n "$policy_required_artifact_type" ] || policy_required_artifact_type="${current_policy_required_artifact_type:-none}"
  [ -n "$policy_required_stage" ] || policy_required_stage="${current_policy_required_stage:-none}"
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

if [ -n "$instructions_file" ]; then
  instructions_body=$(cat "$instructions_file")
else
  instructions_body=$(awk '
    /^## Canonical Instructions$/ || /^## Runtime Instructions$/ {
      seen_heading = 1
      next
    }
    seen_heading { print }
  ' "$role_file" | sed '/./,$!d')
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

${heading}

$instructions_body
EOF

"$script_dir/audit_role_schema.sh" --quiet --role-dir "$(dirname "$role_file")"

echo "$role_file"
