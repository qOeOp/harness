#!/bin/sh
set -eu

department="${1:-}"
task="${2:-}"

if [ -z "$department" ] || [ -z "$task" ]; then
  echo "usage: $0 <department> <task>" >&2
  exit 1
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "worktree requires at least one commit on HEAD; create the initial commit first" >&2
  exit 1
fi

slug=$(printf '%s' "$task" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
branch="codex/${department}-${slug}"
base_dir="../harness-worktrees"
target="${base_dir}/${department}-${slug}"

mkdir -p "$base_dir"
git worktree add -b "$branch" "$target" HEAD
echo "$target"
