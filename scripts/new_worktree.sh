#!/bin/sh
set -eu

tag="${1:-}"
task="${2:-}"

if [ -z "$tag" ] || [ -z "$task" ]; then
  echo "usage: $0 <tag> <task>" >&2
  exit 1
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "worktree requires at least one commit on HEAD; create the initial commit first" >&2
  exit 1
fi

slug=$(printf '%s' "$task" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
branch="codex/${tag}-${slug}"
base_dir="../harness-worktrees"
target="${base_dir}/${tag}-${slug}"

mkdir -p "$base_dir"
git worktree add -b "$branch" "$target" HEAD
echo "$target"
