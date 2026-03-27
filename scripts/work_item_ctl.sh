#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_harness_paths.sh"
init_harness_paths "$script_dir"
export STATE_INVOKER="${STATE_INVOKER:-$(harness_command_path "work_item_ctl.sh")}"

usage() {
  ctl_command=$(harness_command_path "work_item_ctl.sh")
  select_command=$(harness_command_path "select_work_item.sh")
  open_command=$(harness_command_path "open_current_work_item.sh")
  start_command=$(harness_command_path "start_work_item.sh")
  pause_command=$(harness_command_path "pause_work_item.sh")
  resume_command=$(harness_command_path "resume_work_item.sh")
  complete_command=$(harness_command_path "complete_work_item.sh")

  cat <<'EOF' >&2
usage: <harness-work-item-ctl> <select|open|start|pause|resume|complete|help> [args...]

subcommands:
  select     forward to <harness-select-work-item>
  open       forward to <harness-open-current-work-item>
  start      forward to <harness-start-work-item>
  pause      forward to <harness-pause-work-item>
  resume     forward to <harness-resume-work-item>
  complete   forward to <harness-complete-work-item>
  help       show this message

examples:
  <harness-work-item-ctl> select --json company
  <harness-work-item-ctl> open company
  <harness-work-item-ctl> start --json company
  <harness-work-item-ctl> pause --expected-from-status in-progress --expected-version 3 --interrupt-marker risk-review-required WI-0001
  <harness-work-item-ctl> resume --expected-version 4 WI-0001
  <harness-work-item-ctl> complete --json --target-status review company
  STATE_ACTOR=codex <harness-work-item-ctl> complete --json --target-status killed --work-item WI-0006 company
EOF

  printf '\nResolved commands:\n' >&2
  printf '  ctl: %s\n' "$ctl_command" >&2
  printf '  select: %s\n' "$select_command" >&2
  printf '  open: %s\n' "$open_command" >&2
  printf '  start: %s\n' "$start_command" >&2
  printf '  pause: %s\n' "$pause_command" >&2
  printf '  resume: %s\n' "$resume_command" >&2
  printf '  complete: %s\n' "$complete_command" >&2
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

case "$subcommand" in
  help|--help|-h)
    usage
    exit 0
    ;;
esac

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
