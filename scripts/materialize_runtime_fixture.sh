#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))

target=""
source_repo="$repo_root"
force=0

usage() {
  cat <<'EOF' >&2
usage: ./scripts/materialize_runtime_fixture.sh [--target <dir>] [--source-repo <dir>] [--force]
EOF
  exit 1
}

write_file() {
  target_file="$1"
  mkdir -p "$(dirname "$target_file")"
  cat >"$target_file"
}

dir_is_empty() {
  [ -d "$1" ] || return 1
  [ -z "$(find "$1" -mindepth 1 -print -quit 2>/dev/null)" ]
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || usage
      target="$2"
      shift 2
      ;;
    --source-repo)
      [ "$#" -ge 2 ] || usage
      source_repo="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

[ -f "$source_repo/SKILL.md" ] || {
  echo "source repo does not look like the harness source repo: $source_repo" >&2
  exit 1
}

if [ -z "$target" ]; then
  target=$(mktemp -d "${TMPDIR:-/tmp}/harness-runtime.XXXXXX")
else
  if [ -e "$target" ]; then
    if [ -d "$target" ] && dir_is_empty "$target"; then
      :
    elif [ "$force" -ne 1 ]; then
      echo "target already exists; pass --force to reuse: $target" >&2
      exit 1
    else
      rm -rf "$target"
      mkdir -p "$target"
    fi
  else
    mkdir -p "$target"
  fi
fi

mkdir -p \
  "$target/.harness/tasks" \
  "$target/.harness/locks"

today=$(date +%F)
contract_path="references/contracts/task-record-runtime-tree-v2.toml"

write_file "$target/.harness/README.md" <<EOF
# Harness Runtime

- Generated from source repo: $source_repo
- Runtime mode: minimum-core
- Contract: \`$contract_path\`
- Purpose: consumer sandbox fixture for validation and smoke-chain execution
- Harness-owned surface: \`.harness/\`
- Optional support root: \`.harness/runtime/\` for tool-owned caches and isolated runtime support state
- Durable support state under \`.harness/runtime/\` must carry explicit schema / format version
- Cross-version restore of runtime support state must migrate or fail closed
- Canonical task truth: \`.harness/tasks/<task-id>/task.md\`
- Long-running execution should record explicit budget / stop boundary in task recovery or a linked artifact
- Skill installation path, provider config, and provider entry files remain user-owned and out of scope
EOF

write_file "$target/.harness/entrypoint.md" <<EOF
# Harness Entrypoint

Read in this order:

1. \`.harness/README.md\`
2. \`.harness/tasks/<task-id>/task.md\` when a task exists
3. \`.harness/tasks/<task-id>/task.md\` `## Recovery` section when a task is active or paused

Runtime notes:

- Mode: minimum-core
- Task truth lives under \`.harness/tasks/<task-id>/\`
- Recovery lives inside each task record
- Long-running tasks should carry an explicit budget / stop boundary in \`## Recovery\`
- Slow human approval / review should pause the task and resume later, not hide in session wait state
- Harness does not manage consumer root/provider entry files or skill install location
EOF

write_file "$target/.harness/manifest.toml" <<EOF
schema_version = 1
runtime_mode = "minimum-core"
advanced_governance_enabled = false
created_at = "$today"
updated_at = "$today"
EOF

printf '%s\n' "$target"
