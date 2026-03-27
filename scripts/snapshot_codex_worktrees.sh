#!/bin/sh
set -eu

usage() {
  cat <<'EOF' >&2
usage: ./scripts/snapshot_codex_worktrees.sh [--dry-run] [--no-commit] [--date-tag YYYYMMDD] [--branch-prefix prefix]

Create named snapshot branches for detached codex worktrees and optionally commit their current changes.
EOF
  exit 1
}

dry_run=0
commit_changes=1
date_tag=$(date +%Y%m%d)
branch_prefix="codex/converge-snapshot"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --no-commit)
      commit_changes=0
      shift
      ;;
    --date-tag)
      [ "$#" -ge 2 ] || usage
      date_tag="$2"
      shift 2
      ;;
    --branch-prefix)
      [ "$#" -ge 2 ] || usage
      branch_prefix="$2"
      shift 2
      ;;
    --help|-h|help)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf '+'
    for arg in "$@"; do
      printf ' %s' "$arg"
    done
    printf '\n'
    return 0
  fi

  "$@"
}

root=$(git rev-parse --show-toplevel)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT HUP INT TERM
git worktree list --porcelain >"$tmp"

process_worktree() {
  worktree_path="$1"
  [ -n "$worktree_path" ] || return 0
  [ "$worktree_path" = "$root" ] && return 0

  worktree_id=$(basename "$(dirname "$worktree_path")")
  target_branch="${branch_prefix}-${worktree_id}-${date_tag}"
  current_branch=$(git -C "$worktree_path" branch --show-current)
  branch_note="$current_branch"

  if [ -z "$current_branch" ]; then
    run git -C "$worktree_path" switch -c "$target_branch"
    branch_note="$target_branch"
  fi

  status=$(git -C "$worktree_path" status --porcelain)
  if [ -z "$status" ]; then
    printf '%s\t%s\tclean\n' "$worktree_id" "$branch_note"
    return 0
  fi

  if [ "$commit_changes" -eq 0 ]; then
    printf '%s\t%s\tdirty\n' "$worktree_id" "$branch_note"
    return 0
  fi

  run git -C "$worktree_path" add -A
  run git -C "$worktree_path" commit -m "snapshot: preserve codex worktree ${worktree_id} before convergence"

  if [ "$dry_run" -eq 1 ]; then
    printf '%s\t%s\tcommit:DRY_RUN\n' "$worktree_id" "$branch_note"
  else
    head=$(git -C "$worktree_path" rev-parse --short HEAD)
    printf '%s\t%s\tcommit:%s\n' "$worktree_id" "$branch_note" "$head"
  fi
}

worktree_path=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    worktree\ *)
      if [ -n "$worktree_path" ]; then
        process_worktree "$worktree_path"
      fi
      worktree_path=${line#worktree }
      ;;
    "")
      if [ -n "$worktree_path" ]; then
        process_worktree "$worktree_path"
        worktree_path=""
      fi
      ;;
  esac
done <"$tmp"

if [ -n "$worktree_path" ]; then
  process_worktree "$worktree_path"
fi
