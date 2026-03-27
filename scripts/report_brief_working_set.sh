#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

briefs_dir=".harness/workspace/briefs"

if [ ! -d "$briefs_dir" ]; then
  echo "missing directory: $briefs_dir" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

active_full_file="$tmpdir/active-full.txt"
candidate_full_file="$tmpdir/candidate-full.txt"
redirect_file="$tmpdir/redirect.txt"

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

total=0
redirect_count=0
full_body_count=0
active_full_count=0
archive_candidate_count=0
direct_route_count=0
nonterminal_link_count=0

for brief_file in $(find "$briefs_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort); do
  total=$((total + 1))
  brief_rel_path=".harness/workspace/briefs/$(basename "$brief_file")"
  brief_status=$(field_value_or_none "$brief_file" "Status")
  linked_work_items=$(artifact_work_item_links "$brief_file")
  archived_snapshot=$(field_value_or_none "$brief_file" "Archived snapshot")
  current_route_refs="none"
  nonterminal_item_refs="none"
  terminal_item_refs="none"

  route_refs=$(rg -l -F "$brief_rel_path" .harness/workspace/current "$state_boards_dir" "$task_runtime_dir" 2>/dev/null || true)
  if [ -n "$route_refs" ]; then
    for ref_file in $route_refs; do
      current_route_refs=$(append_csv "$current_route_refs" "$ref_file")
    done
    direct_route_count=$((direct_route_count + 1))
  fi

  if [ -n "$linked_work_items" ] && [ "$linked_work_items" != "none" ]; then
    old_ifs=${IFS- }
    IFS=','
    set -- $linked_work_items
    IFS=$old_ifs
    for item_id in "$@"; do
      item_id=$(trim "$item_id")
      [ -n "$item_id" ] || continue
      item_file=$(work_item_path "$item_id")
      [ -f "$item_file" ] || continue
      item_status=$(field_value_or_none "$item_file" "Status")
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

  if [ "$nonterminal_item_refs" != "none" ]; then
    nonterminal_link_count=$((nonterminal_link_count + 1))
  fi

  if [ "$brief_status" = "archived-redirect" ]; then
    redirect_count=$((redirect_count + 1))
    printf '%s | linked work items: %s | archived snapshot: %s\n' \
      "$brief_rel_path" \
      "${linked_work_items:-none}" \
      "$archived_snapshot" >>"$redirect_file"
    continue
  fi

  full_body_count=$((full_body_count + 1))

  if [ "$current_route_refs" != "none" ] || [ "$nonterminal_item_refs" != "none" ]; then
    active_full_count=$((active_full_count + 1))
    printf '%s | non-terminal item refs: %s | direct route refs: %s | terminal item refs: %s\n' \
      "$brief_rel_path" \
      "$nonterminal_item_refs" \
      "$current_route_refs" \
      "$terminal_item_refs" >>"$active_full_file"
    continue
  fi

  archive_candidate_count=$((archive_candidate_count + 1))
  printf '%s | linked work items: %s | terminal item refs: %s | direct route refs: %s\n' \
    "$brief_rel_path" \
    "${linked_work_items:-none}" \
    "$terminal_item_refs" \
    "$current_route_refs" >>"$candidate_full_file"
done

echo "# Brief Working Set Report"
echo
echo "- Date: $(date +%F)"
echo "- Scanned directory: $briefs_dir"
echo "- Total brief files: $total"
echo "- Full-body briefs: $full_body_count"
echo "- Archived redirect stubs: $redirect_count"
echo "- Full-body briefs blocked by active routing: $active_full_count"
echo "- Full-body archive candidates: $archive_candidate_count"
echo "- Briefs directly referenced by current/board/progress: $direct_route_count"
echo "- Briefs linked from non-terminal work items: $nonterminal_link_count"
echo
echo "## Full-Body Briefs Blocked By Active Routing"
render_list_or_none "$active_full_file"
echo
echo "## Full-Body Archive Candidates"
render_list_or_none "$candidate_full_file"
echo
echo "## Archived Redirect Stubs"
render_list_or_none "$redirect_file"
