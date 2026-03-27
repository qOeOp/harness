#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

briefs_dir=".harness/workspace/briefs"
archive_root=".harness/workspace/archive/briefs"
current_dir=".harness/workspace/current"

if [ ! -d "$briefs_dir" ]; then
  echo "missing directory: $briefs_dir" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

current_file="$tmpdir/current.txt"
inflight_file="$tmpdir/inflight.txt"
candidate_file="$tmpdir/candidate.txt"
redirect_file="$tmpdir/redirect.txt"
prunable_redirect_file="$tmpdir/prunable-redirect.txt"
bucket_file="$tmpdir/buckets.txt"

append_csv() {
  current="$1"
  value="$2"

  case "$current" in
    ""|none) printf '%s\n' "$value" ;;
    *) printf '%s, %s\n' "$current" "$value" ;;
  esac
}

render_list_or_none() {
  file="$1"
  if [ -s "$file" ]; then
    cat "$file"
  else
    echo "- none"
  fi
}

current_count=0
inflight_count=0
candidate_count=0
redirect_count=0
prunable_redirect_count=0
bucket_count=0

for file in $(find "$current_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort); do
  current_count=$((current_count + 1))
  current_rel=".harness/workspace/current/$(basename "$file")"
  status=$(field_value_or_none "$file" "Status")
  snapshot=$(field_value_or_none "$file" "Active snapshot")
  printf '%s | status: %s | active snapshot: %s\n' \
    "$current_rel" \
    "$status" \
    "$snapshot" >>"$current_file"
done

for brief_file in $(find "$briefs_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort); do
  brief_rel=".harness/workspace/briefs/$(basename "$brief_file")"
  brief_status=$(field_value_or_none "$brief_file" "Status")
  linked_work_items=$(artifact_work_item_links "$brief_file")
  archived_snapshot=$(field_value_or_none "$brief_file" "Archived snapshot")
  current_route_refs="none"
  nonterminal_item_refs="none"
  terminal_item_refs="none"

  route_refs=$(rg -l -F "$brief_rel" .harness/workspace/current "$state_boards_dir" "$task_runtime_dir" 2>/dev/null || true)
  if [ -n "$route_refs" ]; then
    for ref_file in $route_refs; do
      current_route_refs=$(append_csv "$current_route_refs" "$ref_file")
    done
  fi

  if [ -n "$linked_work_items" ] && [ "$linked_work_items" != "none" ]; then
    old_ifs=${IFS- }
    IFS=','
    set -- $linked_work_items
    IFS=$old_ifs
    for item_id in "$@"; do
      item_id=$(trim "$item_id")
      [ -n "$item_id" ] || continue
      item_ref=$(work_item_path "$item_id")
      [ -f "$item_ref" ] || continue
      item_status=$(field_value_or_none "$item_ref" "Status")
      item_entry="$item_id($item_status)"
      case "$item_status" in
        done|killed)
          terminal_item_refs=$(append_csv "$terminal_item_refs" "$item_entry")
          ;;
        *)
          nonterminal_item_refs=$(append_csv "$nonterminal_item_refs" "$item_entry")
          ;;
      esac
    done
  fi

  if [ "$brief_status" = "archived-redirect" ]; then
    repo_refs=$(rg -l -F "$brief_rel" README.md docs .harness/workspace/departments 2>/dev/null || true)
    retained_repo_refs="none"

    if [ -n "$repo_refs" ]; then
      for ref in $repo_refs; do
        [ "$ref" = "$brief_rel" ] && continue
        retained_repo_refs=$(append_csv "$retained_repo_refs" "$ref")
      done
    fi

    if [ "$retained_repo_refs" = "none" ]; then
      prunable_redirect_count=$((prunable_redirect_count + 1))
      printf '%s | archived snapshot: %s\n' \
        "$brief_rel" \
        "$archived_snapshot" >>"$prunable_redirect_file"
      continue
    fi

    redirect_count=$((redirect_count + 1))
    printf '%s | archived snapshot: %s | linked work items: %s | repo refs: %s\n' \
      "$brief_rel" \
      "$archived_snapshot" \
      "${linked_work_items:-none}" \
      "$retained_repo_refs" >>"$redirect_file"
    continue
  fi

  if [ "$current_route_refs" != "none" ] || [ "$nonterminal_item_refs" != "none" ]; then
    inflight_count=$((inflight_count + 1))
    printf '%s | linked work items: %s | non-terminal item refs: %s | direct route refs: %s\n' \
      "$brief_rel" \
      "${linked_work_items:-none}" \
      "$nonterminal_item_refs" \
      "$current_route_refs" >>"$inflight_file"
    continue
  fi

  candidate_count=$((candidate_count + 1))
  printf '%s | linked work items: %s | terminal item refs: %s | direct route refs: %s\n' \
    "$brief_rel" \
    "${linked_work_items:-none}" \
    "$terminal_item_refs" \
    "$current_route_refs" >>"$candidate_file"
done

if [ -d "$archive_root" ]; then
  for bucket_dir in $(find "$archive_root" -mindepth 1 -maxdepth 1 -type d | sort); do
    bucket_count=$((bucket_count + 1))
    bucket_rel=".harness/workspace/archive/briefs/$(basename "$bucket_dir")"
    count=$(find "$bucket_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
    printf '%s | files: %s\n' "$bucket_rel" "$count" >>"$bucket_file"
  done
fi

echo "# Brief Registry Report"
echo
echo "- Date: $(date +%F)"
echo "- Purpose: derived index for progressive disclosure across current, in-flight, redirect, and archive brief layers"
echo "- Current truth pointers: $current_count"
echo "- In-flight full-body briefs: $inflight_count"
echo "- Dormant full-body archive candidates: $candidate_count"
echo "- Referenced redirect stubs in .harness/workspace/briefs: $redirect_count"
echo "- Prunable redirect stubs in .harness/workspace/briefs: $prunable_redirect_count"
echo "- Archive buckets: $bucket_count"
echo
echo "## Recommended Reading Order"
echo "1. Read \`.harness/workspace/current/*.md\` first."
echo "2. If an active work item or current route points to a full-body brief, read that in-flight brief next."
echo "3. If you only encounter an old \`.harness/workspace/briefs/*.md\` path, treat it as a redirect stub and follow its archive snapshot."
echo "4. Only read archive snapshots when you need historical derivation."
echo
echo "## Current Truth Pointers"
render_list_or_none "$current_file"
echo
echo "## In-Flight Full-Body Briefs"
render_list_or_none "$inflight_file"
echo
echo "## Dormant Full-Body Archive Candidates"
render_list_or_none "$candidate_file"
echo
echo "## Referenced Redirect Stubs In .harness/workspace/briefs"
render_list_or_none "$redirect_file"
echo
echo "## Prunable Redirect Stubs In .harness/workspace/briefs"
render_list_or_none "$prunable_redirect_file"
echo
echo "## Archive Buckets"
render_list_or_none "$bucket_file"
