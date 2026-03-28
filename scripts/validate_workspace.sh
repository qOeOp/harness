#!/bin/sh
set -eu

quiet=""
mode=""
ok=1
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

while [ $# -gt 0 ]; do
  case "$1" in
    --quiet)
      quiet="--quiet"
      ;;
    --mode)
      shift
      if [ $# -eq 0 ]; then
        echo "usage: $0 [--quiet] [--mode core|shared|governance]" >&2
        exit 2
      fi
      case "$1" in
        core)
          mode="core"
          ;;
        shared|governance)
          mode="shared"
          ;;
        *)
          echo "invalid mode: $1" >&2
          exit 2
          ;;
      esac
      ;;
    *)
      echo "usage: $0 [--quiet] [--mode core|shared|governance]" >&2
      exit 2
      ;;
  esac
  shift
done

infer_runtime_mode() {
  manifest=".harness/manifest.toml"

  if [ ! -f "$manifest" ]; then
    printf '%s\n' "core"
    return 0
  fi

  runtime_mode=$(awk -F'=' '/^[[:space:]]*runtime_mode[[:space:]]*=/ { value=$2; sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); gsub(/^"/, "", value); gsub(/"$/, "", value); print value; exit }' "$manifest")
  governance_enabled=$(awk -F'=' '/^[[:space:]]*advanced_governance_enabled[[:space:]]*=/ { value=$2; sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); gsub(/^"/, "", value); gsub(/"$/, "", value); print value; exit }' "$manifest")

  if [ "$runtime_mode" = "advanced-governance" ] || [ "$governance_enabled" = "true" ]; then
    printf '%s\n' "shared"
  else
    printf '%s\n' "core"
  fi
}

if [ -z "$mode" ]; then
  mode=$(infer_runtime_mode)
fi

if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
  echo "validate_workspace.sh checks an installed consumer repo layout. Run ./scripts/validate_source_repo.sh in the framework source repo." >&2
  exit 2
fi

check_file() {
  if [ ! -e "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing: $1"
  fi
}

check_exec() {
  if [ ! -x "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "not executable: $1"
  fi
}

check_contains() {
  file="$1"
  pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing pattern '$pattern' in $file"
  fi
}

check_dir() {
  if [ ! -d "$1" ]; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "missing directory: $1"
  fi
}

fail_message() {
  ok=0
  [ "$quiet" = "--quiet" ] || echo "$1"
}

run_core_checks() {
  check_file ".harness/entrypoint.md"
  check_file ".harness/README.md"
  check_file ".harness/manifest.toml"
  check_dir ".harness/tasks"
  check_dir ".harness/locks"

  check_contains ".harness/entrypoint.md" ".harness/README.md"
  check_contains ".harness/entrypoint.md" ".harness/tasks/<task-id>/task.md"
  check_contains ".harness/entrypoint.md" "Recovery"
  check_contains ".harness/README.md" "task-record-runtime-tree-v2.toml"
  check_contains ".harness/README.md" "user-owned and out of scope"

  if grep -Eq 'AGENTS\.md|CLAUDE\.md|GEMINI\.md|\.claude/|\.codex/|\.gemini/|\.agents/skills/harness' ".harness/entrypoint.md"; then
    fail_message ".harness/entrypoint.md must stay inside harness-owned runtime surface"
  fi

  if ! "$script_dir/audit_state_system.sh" --mode core --quiet >/dev/null 2>&1; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "state system audit failed (core)"
  fi
}

run_shared_writeback_checks() {
  check_file ".harness/workspace/decisions/log/README.md"
  check_file ".harness/workspace/current/README.md"
  check_file ".harness/workspace/research/dispatches/README.md"
  check_file ".harness/workspace/status/digests/README.md"
  check_file ".harness/workspace/status/process-audits/README.md"
  check_file ".harness/workspace/status/snapshots/README.md"
  check_file ".harness/workspace/research/sources/README.md"
  check_file ".harness/workspace/intake/inbox/README.md"
  check_file ".harness/workspace/state/README.md"
  check_file ".harness/workspace/state/boards/README.md"
  check_file ".harness/workspace/state/board-refreshes/README.md"
  check_dir ".harness/workspace/current"
  check_dir ".harness/workspace/archive"
  check_dir ".harness/workspace/state/boards"
  check_dir ".harness/workspace/state/board-refreshes"

  if [ -f ".harness/manifest.toml" ]; then
    check_contains ".harness/manifest.toml" "runtime_mode = \"advanced-governance\""
    check_contains ".harness/manifest.toml" "advanced_governance_enabled = true"
  fi

  for current_file in .harness/workspace/current/*.md; do
    [ -f "$current_file" ] || continue
    case "$(basename "$current_file")" in
      README.md) ;;
      *) check_file "$current_file" ;;
    esac
  done

  if ! "$script_dir/audit_document_system.sh" --quiet >/dev/null 2>&1; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "document routing audit failed"
  fi

  if ! "$script_dir/audit_doc_style.sh" --quiet >/dev/null 2>&1; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "doc style audit failed"
  fi

  if ! "$script_dir/audit_state_system.sh" --mode shared --quiet >/dev/null 2>&1; then
    ok=0
    [ "$quiet" = "--quiet" ] || echo "state system audit failed (shared writeback)"
  fi
}

run_core_checks

if [ "$mode" = "shared" ]; then
  run_shared_writeback_checks
fi

if [ "$ok" -eq 1 ]; then
  [ "$quiet" = "--quiet" ] || echo "workspace baseline ($mode): ok"
  exit 0
fi

exit 1
