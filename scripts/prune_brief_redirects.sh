#!/bin/sh
set -eu

mode="${1:-}"

case "$mode" in
  ""|--check) apply=0 ;;
  --apply) apply=1 ;;
  *)
    echo "usage: $0 [--check|--apply]" >&2
    exit 1
    ;;
esac

briefs_dir=".harness/workspace/briefs"

if [ ! -d "$briefs_dir" ]; then
  echo "missing directory: $briefs_dir" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT HUP INT TERM

count=0

for brief_file in $(find "$briefs_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort); do
  status=$(awk '
    index($0, "- Status: ") == 1 {
      print substr($0, length("- Status: ") + 1)
      exit
    }
  ' "$brief_file")

  [ "$status" = "archived-redirect" ] || continue

  brief_rel=".harness/workspace/briefs/$(basename "$brief_file")"
  repo_refs=$(rg -l -F "$brief_rel" README.md docs 2>/dev/null || true)
  retained_repo_refs=""

  if [ -n "$repo_refs" ]; then
    for ref in $repo_refs; do
      [ "$ref" = "$brief_rel" ] && continue
      retained_repo_refs="${retained_repo_refs}${ref}\n"
    done
  fi

  if [ -n "$retained_repo_refs" ]; then
    continue
  fi

  count=$((count + 1))
  printf '%s\n' "$brief_rel" >>"$tmp"

  if [ "$apply" -eq 1 ]; then
    rm -f "$brief_file"
  fi
done

if [ "$apply" -eq 1 ]; then
  echo "pruned redirect stubs: $count"
else
  echo "# Prunable Brief Redirects"
  echo
  echo "- Count: $count"
  if [ -s "$tmp" ]; then
    cat "$tmp"
  else
    echo "- none"
  fi
fi
