#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
export STATE_INVOKER="${STATE_INVOKER:-./.agents/skills/harness/scripts/work_item_ctl.sh}"

usage() {
  cat <<'EOF' >&2
usage: ./.agents/skills/harness/scripts/work_item_ctl.sh <select|open|start|pause|resume|complete|help> [args...]

subcommands:
  select     forward to ./.agents/skills/harness/scripts/select_work_item.sh
  open       forward to ./.agents/skills/harness/scripts/open_current_work_item.sh
  start      forward to ./.agents/skills/harness/scripts/start_work_item.sh
  pause      forward to ./.agents/skills/harness/scripts/pause_work_item.sh
  resume     forward to ./.agents/skills/harness/scripts/resume_work_item.sh
  complete   forward to ./.agents/skills/harness/scripts/complete_work_item.sh
  help       show this message

examples:
  ./.agents/skills/harness/scripts/work_item_ctl.sh select --json company
  ./.agents/skills/harness/scripts/work_item_ctl.sh open company
  ./.agents/skills/harness/scripts/work_item_ctl.sh start --json company
  ./.agents/skills/harness/scripts/work_item_ctl.sh pause --expected-from-status in-progress --expected-version 3 --interrupt-marker risk-review-required WI-0001
  ./.agents/skills/harness/scripts/work_item_ctl.sh resume --expected-version 4 WI-0001
  ./.agents/skills/harness/scripts/work_item_ctl.sh complete --json --target-status review company
  STATE_ACTOR=codex ./.agents/skills/harness/scripts/work_item_ctl.sh complete --json --target-status killed --work-item WI-0006 company
EOF
}

resolve_target() {
  case "$1" in
    select)
      printf '%s\n' "$script_dir/select_work_item.sh"
      ;;
    open)
      printf '%s\n' "$script_dir/open_current_work_item.sh"
      ;;
    start)
      printf '%s\n' "$script_dir/start_work_item.sh"
      ;;
    pause)
      printf '%s\n' "$script_dir/pause_work_item.sh"
      ;;
    resume)
      printf '%s\n' "$script_dir/resume_work_item.sh"
      ;;
    complete)
      printf '%s\n' "$script_dir/complete_work_item.sh"
      ;;
    help|--help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown subcommand: $1" >&2
      usage
      exit 1
      ;;
  esac
}

subcommand="${1:-}"
if [ -z "$subcommand" ]; then
  usage
  exit 1
fi
shift

target_script=$(resolve_target "$subcommand")

if [ ! -f "$target_script" ]; then
  echo "missing target script: $target_script" >&2
  exit 1
fi

if [ ! -x "$target_script" ]; then
  echo "target script is not executable: $target_script" >&2
  exit 1
fi

exec "$target_script" "$@"
