#!/bin/sh
set -eu

usage() {
  echo "usage: $0 [--retain-stub] .harness/workspace/briefs/<file>.md <archive-subdir> [reason ...]" >&2
  exit 1
}

retain_stub=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --retain-stub)
      retain_stub=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

[ "$#" -ge 2 ] || usage

source_file="$1"
archive_subdir="$2"
shift 2
reason="$*"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
cd "$repo_root"

case "$source_file" in
  .harness/workspace/briefs/*.md) ;;
  *) echo "source must be a markdown file under .harness/workspace/briefs/: $source_file" >&2; exit 1 ;;
esac

if [ ! -f "$source_file" ]; then
  echo "missing source: $source_file" >&2
  exit 1
fi

if [ "$(basename "$source_file")" = "README.md" ]; then
  echo "refusing to archive .harness/workspace/briefs/README.md" >&2
  exit 1
fi

linked_work_items=$(
  awk '
    index($0, "- Linked work items: ") == 1 {
      print substr($0, length("- Linked work items: ") + 1)
      exit
    }
    index($0, "- Linked work item: ") == 1 {
      print substr($0, length("- Linked work item: ") + 1)
      exit
    }
  ' "$source_file"
)

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

active_refs=$(
  rg -n -F "$source_file" .harness/workspace/current "$state_boards_dir" "$task_runtime_dir" 2>/dev/null || true
)

if [ -n "$active_refs" ]; then
  echo "refusing to archive actively routed brief: $source_file" >&2
  echo "$active_refs" >&2
  exit 1
fi

active_item_refs=""
if [ -n "$linked_work_items" ]; then
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

    case "$item_status" in
      done|killed|archived) ;;
      *)
        active_item_refs="${active_item_refs}${item_file} (status=${item_status:-unknown})\n"
        ;;
    esac
  done
fi

if [ -n "$active_item_refs" ]; then
  echo "refusing to archive brief linked from non-terminal work items: $source_file" >&2
  printf '%b' "$active_item_refs" >&2
  exit 1
fi

archive_dir=".harness/workspace/archive/briefs/$archive_subdir"
archive_file="$archive_dir/$(basename "$source_file")"
archive_abs="$repo_root/$archive_file"
archived_on=$(date +%F)

if [ -e "$archive_file" ]; then
  echo "archive target already exists: $archive_file" >&2
  exit 1
fi

mkdir -p "$archive_dir"
cp "$source_file" "$archive_file"

if [ -z "$reason" ]; then
  reason="已被后续稳定 truth 吸收；默认应直接读取 archive 快照"
fi

repo_refs=$(
  rg -l -F "$source_file" README.md docs .harness/workspace/departments 2>/dev/null || true
)

retained_repo_refs=""

if [ -n "$repo_refs" ]; then
  for ref in $repo_refs; do
    [ "$ref" = "$source_file" ] && continue
    retained_repo_refs="${retained_repo_refs}${ref}\n"
  done
fi

if [ "$retain_stub" -ne 1 ] && [ -z "$retained_repo_refs" ]; then
  rm -f "$source_file"
  echo "archived without redirect: $source_file -> $archive_file"
  exit 0
fi

cat >"$source_file" <<EOF
# Archived Brief Redirect

- Status: archived-redirect
- Linked work items: ${linked_work_items:-n/a}
- Archived on: $archived_on
- Archived snapshot: \`$archive_file\`
- Reason: $reason

## Redirect

这个路径只作为兼容 redirect 保留，避免已经写入 append-only artifact 的 \`$source_file\` 发生路径腐烂。

默认请改读 archive 快照：

- [$archive_file]($archive_abs)
EOF

echo "archived: $source_file -> $archive_file"
