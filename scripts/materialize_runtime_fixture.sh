#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))

target=""
source_repo="$repo_root"
projection_mode="symlink"
with_projections=1
force=0

usage() {
  cat <<'EOF' >&2
usage: ./scripts/materialize_runtime_fixture.sh [--target <dir>] [--source-repo <dir>] [--projection-mode symlink|copy] [--no-projections] [--force]
EOF
  exit 1
}

copy_tree() {
  source_dir="$1"
  target_dir="$2"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a \
      --exclude '.git/' \
      --exclude '.idea/' \
      --exclude 'node_modules/' \
      --exclude '.harness/' \
      --exclude '.DS_Store' \
      "$source_dir/" "$target_dir/"
    return 0
  fi

  (
    cd "$source_dir"
    tar \
      --exclude '.git' \
      --exclude '.idea' \
      --exclude 'node_modules' \
      --exclude '.harness' \
      --exclude '.DS_Store' \
      -cf - .
  ) | (
    cd "$target_dir"
    tar -xf -
  )
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
    --projection-mode)
      [ "$#" -ge 2 ] || usage
      projection_mode="$2"
      shift 2
      ;;
    --no-projections)
      with_projections=0
      shift
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

case "$projection_mode" in
  symlink|copy) ;;
  *) echo "invalid projection mode: $projection_mode" >&2; exit 1 ;;
esac

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
  "$target/.agents/skills" \
  "$target/.harness/tasks" \
  "$target/.harness/archive/tasks" \
  "$target/.harness/locks"

skill_root="$target/.agents/skills/harness"
case "$projection_mode" in
  symlink)
    ln -s "$source_repo" "$skill_root"
    ;;
  copy)
    mkdir -p "$skill_root"
    copy_tree "$source_repo" "$skill_root"
    ;;
esac

today=$(date +%F)
contract_path=".agents/skills/harness/references/contracts/minimum-core-runtime-tree.toml"

write_file "$target/README.md" <<EOF
# Harness Runtime Fixture

This consumer sandbox is generated from the harness source repo.

Start here:

- \`.harness/entrypoint.md\`
EOF

write_file "$target/AGENTS.md" <<EOF
# Harness Consumer Routing

Read \`.harness/entrypoint.md\` first.
EOF

write_file "$target/CLAUDE.md" <<EOF
# Harness Consumer Routing

Read \`.harness/entrypoint.md\` first.
EOF

write_file "$target/GEMINI.md" <<EOF
# Harness Consumer Routing

Read \`.harness/entrypoint.md\` first.
EOF

write_file "$target/.harness/README.md" <<EOF
# Harness Runtime

- Generated from source repo: $source_repo
- Runtime mode: minimum-core
- Contract: \`$contract_path\`
- Purpose: consumer sandbox fixture for validation and smoke-chain execution
EOF

write_file "$target/.harness/entrypoint.md" <<EOF
# Harness Entrypoint

Read in this order:

1. \`.agents/skills/harness/SKILL.md\`
2. \`.agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md\`
3. \`.agents/skills/harness/docs/workflows/agent-operator-contract.md\`
4. \`.harness/README.md\`

Runtime notes:

- Mode: minimum-core
- Current task pointer appears only after the first tracked task is created
- Task truth lives under \`.harness/tasks/<task-id>/\`
EOF

write_file "$target/.harness/manifest.toml" <<EOF
schema_version = 1
runtime_mode = "minimum-core"
advanced_governance_enabled = false
created_at = "$today"
updated_at = "$today"
EOF

if [ "$with_projections" -eq 1 ]; then
  (
    cd "$target"
    ./.agents/skills/harness/scripts/sync_claude_skill_projections.sh >/dev/null
    ./.agents/skills/harness/scripts/sync_agent_projections.sh >/dev/null
  )
fi

printf '%s\n' "$target"
