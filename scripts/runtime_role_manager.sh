#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_consumer_runtime.sh"
. "$script_dir/lib_consumer_runtime_routes.sh"
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))

usage() {
  cat <<'EOF' >&2
usage: ./scripts/runtime_role_manager.sh (--consumer-runtime <name> | --consumer-runtime-root <path>) [--consumer-runtime-table <path>] [--stage <name>] [--proposal <path>] <create|edit|audit> [args...]

examples:
  ./scripts/runtime_role_manager.sh --consumer-runtime dogfood --stage post-acceptance-compounding --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md create --slug role-slug --claude-description "..." --codex-description "..."
  ./scripts/runtime_role_manager.sh --consumer-runtime dogfood --stage post-acceptance-compounding --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md edit --slug role-slug --print-current
  ./scripts/runtime_role_manager.sh --consumer-runtime dogfood audit --quiet
EOF
  exit 1
}

runtime_root=""
runtime_name=""
route_table_path=""
proposal_path=""
stage=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --consumer-runtime)
      [ "$#" -ge 2 ] || usage
      runtime_name="$2"
      shift 2
      ;;
    --consumer-runtime-root)
      [ "$#" -ge 2 ] || usage
      runtime_root="$2"
      shift 2
      ;;
    --consumer-runtime-table)
      [ "$#" -ge 2 ] || usage
      route_table_path="$2"
      shift 2
      ;;
    --proposal)
      [ "$#" -ge 2 ] || usage
      proposal_path="$2"
      shift 2
      ;;
    --stage)
      [ "$#" -ge 2 ] || usage
      stage="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      break
      ;;
  esac
done

[ -n "$runtime_root$runtime_name" ] || usage
[ -z "$runtime_root" ] || [ -z "$runtime_name" ] || {
  echo "use either --consumer-runtime or --consumer-runtime-root, not both." >&2
  exit 1
}
[ "$#" -ge 1 ] || usage

action="$1"
shift

if [ -n "$runtime_name" ]; then
  runtime_root=$(resolve_consumer_runtime_root_from_table "$runtime_name" "$route_table_path")
fi

resolved_runtime_root=$(normalize_consumer_runtime_root "$runtime_root")
[ -n "$resolved_runtime_root" ] || {
  echo "unable to resolve runtime root: $runtime_root" >&2
  exit 1
}

require_shared_writeback_consumer_runtime_root \
  "$resolved_runtime_root" \
  "runtime_role_manager.sh" \
  "$repo_root"

if [ -n "$proposal_path" ] && [ -n "$stage" ]; then
  "$script_dir/enforce_role_policy.sh" \
    --role runtime-role-manager \
    --entrypoint scripts/runtime_role_manager.sh \
    --action "$action" \
    --consumer-runtime-root "$resolved_runtime_root" \
    --proposal "$proposal_path" \
    --stage "$stage"
elif [ -n "$proposal_path" ]; then
  "$script_dir/enforce_role_policy.sh" \
    --role runtime-role-manager \
    --entrypoint scripts/runtime_role_manager.sh \
    --action "$action" \
    --consumer-runtime-root "$resolved_runtime_root" \
    --proposal "$proposal_path"
elif [ -n "$stage" ]; then
  "$script_dir/enforce_role_policy.sh" \
    --role runtime-role-manager \
    --entrypoint scripts/runtime_role_manager.sh \
    --action "$action" \
    --consumer-runtime-root "$resolved_runtime_root" \
    --stage "$stage"
else
  "$script_dir/enforce_role_policy.sh" \
    --role runtime-role-manager \
    --entrypoint scripts/runtime_role_manager.sh \
    --action "$action" \
    --consumer-runtime-root "$resolved_runtime_root"
fi

case "$action" in
  create)
    exec "$script_dir/new_role.sh" --consumer-runtime-root "$resolved_runtime_root" "$@"
    ;;
  edit)
    exec "$script_dir/edit_role.sh" --consumer-runtime-root "$resolved_runtime_root" "$@"
    ;;
  audit)
    exec "$script_dir/audit_role_schema.sh" --role-dir "$resolved_runtime_root/.harness/workspace/roles" "$@"
    ;;
  *)
    usage
    ;;
esac
