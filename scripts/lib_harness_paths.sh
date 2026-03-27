#!/bin/sh
set -eu

join_harness_rel_path() {
  base="$1"
  leaf="$2"

  case "$base" in
    ""|.)
      printf '%s\n' "$leaf"
      ;;
    *)
      printf '%s/%s\n' "$base" "$leaf"
      ;;
  esac
}

resolve_harness_root_dir() {
  current="$1"

  while :; do
    if [ -f "$current/SKILL.md" ] && [ -d "$current/scripts" ] && [ -d "$current/docs" ]; then
      printf '%s\n' "$current"
      return 0
    fi

    parent=$(CDPATH= cd -- "$current/.." && pwd -L 2>/dev/null || pwd)
    if [ "$parent" = "$current" ]; then
      break
    fi
    current="$parent"
  done

  echo "unable to resolve harness root from: $1" >&2
  return 1
}

detect_harness_layout() {
  printf '%s\n' "source"
}

init_harness_paths() {
  harness_script_dir="$1"

  HARNESS_SCRIPT_DIR="$harness_script_dir"
  if [ -n "${HARNESS_ROOT_OVERRIDE:-}" ]; then
    HARNESS_ROOT="$HARNESS_ROOT_OVERRIDE"
  else
    HARNESS_ROOT=$(resolve_harness_root_dir "$harness_script_dir")
  fi
  HARNESS_LAYOUT=$(detect_harness_layout "$HARNESS_ROOT")

  case "$HARNESS_LAYOUT" in
    source)
      HARNESS_REPO_ROOT="$HARNESS_ROOT"
      HARNESS_ROOT_REL="."
      ;;
    *)
      echo "unsupported harness layout: $HARNESS_LAYOUT" >&2
      return 1
      ;;
  esac

  HARNESS_SCRIPTS_REL=$(join_harness_rel_path "$HARNESS_ROOT_REL" "scripts")
  HARNESS_DOCS_REL=$(join_harness_rel_path "$HARNESS_ROOT_REL" "docs")
  HARNESS_ROLES_REL=$(join_harness_rel_path "$HARNESS_ROOT_REL" "roles")
  HARNESS_SKILLS_REL=$(join_harness_rel_path "$HARNESS_ROOT_REL" "skills")
  HARNESS_PATHS_INITIALIZED=1
}

require_harness_paths() {
  if [ "${HARNESS_PATHS_INITIALIZED:-0}" != "1" ]; then
    echo "harness paths are not initialized" >&2
    return 1
  fi

  return 0
}

harness_repo_relative_path() {
  require_harness_paths
  join_harness_rel_path "$HARNESS_ROOT_REL" "$1"
}

harness_command_path() {
  require_harness_paths
  printf './%s\n' "$(join_harness_rel_path "$HARNESS_SCRIPTS_REL" "$1")"
}
