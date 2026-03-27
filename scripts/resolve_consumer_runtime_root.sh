#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_consumer_runtime_routes.sh"
. "$script_dir/lib_consumer_runtime.sh"

usage() {
  cat <<'EOF' >&2
usage: ./scripts/resolve_consumer_runtime_root.sh [--consumer-runtime <name>] [--consumer-runtime-table <path>] [--list] [--print-example]

examples:
  ./scripts/resolve_consumer_runtime_root.sh --consumer-runtime dogfood
  ./scripts/resolve_consumer_runtime_root.sh --list
  ./scripts/resolve_consumer_runtime_root.sh --print-example
EOF
  exit 1
}

runtime_name=""
route_table_path=""
list_mode=0
print_example=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --consumer-runtime)
      [ "$#" -ge 2 ] || usage
      runtime_name="$2"
      shift 2
      ;;
    --consumer-runtime-table)
      [ "$#" -ge 2 ] || usage
      route_table_path="$2"
      shift 2
      ;;
    --list)
      list_mode=1
      shift
      ;;
    --print-example)
      print_example=1
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

if [ "$print_example" -eq 1 ]; then
  consumer_runtime_route_table_example
  exit 0
fi

if [ "$list_mode" -eq 1 ]; then
  list_consumer_runtime_routes "$route_table_path"
  exit 0
fi

[ -n "$runtime_name" ] || usage

resolved_runtime_root=$(resolve_consumer_runtime_root_from_table "$runtime_name" "$route_table_path")
resolved_runtime_root=$(normalize_consumer_runtime_root "$resolved_runtime_root")
[ -n "$resolved_runtime_root" ] || {
  echo "unable to resolve consumer runtime root for '$runtime_name'" >&2
  exit 1
}

printf '%s\n' "$resolved_runtime_root"
