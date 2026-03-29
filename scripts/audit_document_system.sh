#!/bin/sh
set -eu

quiet="${1:-}"
ok=1

if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
  echo "audit_document_system.sh checks an installed consumer repo layout, not the framework source repo. Run ./scripts/validate_source_repo.sh in the framework source repo." >&2
  exit 2
fi

say() {
  [ "$quiet" = "--quiet" ] || echo "$1"
}

fail() {
  ok=0
  say "$1"
}

require_file() {
  if [ ! -e "$1" ]; then
    fail "missing: $1"
  fi
}

require_pattern() {
  file="$1"
  pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    fail "missing pattern '$pattern' in $file"
  fi
}

forbid_pattern() {
  file="$1"
  pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    fail "forbidden pattern '$pattern' found in $file"
  fi
}

current_field_value() {
  file="$1"
  label="$2"
  awk -v label="$label" '
    index($0, "- " label ": ") == 1 {
      print substr($0, length("- " label ": ") + 1)
      exit
    }
  ' "$file"
}

infer_runtime_mode() {
  manifest=".harness/manifest.toml"

  if [ ! -f "$manifest" ]; then
    printf '%s\n' "core"
    return 0
  fi

  runtime_mode=$(awk -F'=' '/^[[:space:]]*runtime_mode[[:space:]]*=/ { value=$2; sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); gsub(/^"/, "", value); gsub(/"$/, "", value); print value; exit }' "$manifest")
  shared_writeback_enabled=$(awk -F'=' '/^[[:space:]]*advanced_governance_enabled[[:space:]]*=/ { value=$2; sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); gsub(/^"/, "", value); gsub(/"$/, "", value); print value; exit }' "$manifest")

  if [ "$runtime_mode" = "shared-writeback" ] || [ "$runtime_mode" = "advanced-governance" ] || [ "$shared_writeback_enabled" = "true" ]; then
    printf '%s\n' "shared"
  else
    printf '%s\n' "core"
  fi
}

require_file ".harness/entrypoint.md"
require_file ".harness/README.md"
require_file ".harness/manifest.toml"

require_pattern ".harness/entrypoint.md" ".harness/README.md"
require_pattern ".harness/entrypoint.md" ".harness/tasks/<task-id>/"
require_pattern ".harness/README.md" "task-record-runtime-tree-v2.toml"
require_pattern ".harness/README.md" "user-owned and out of scope"
forbid_pattern ".harness/entrypoint.md" ".agents/skills/harness"
forbid_pattern ".harness/entrypoint.md" "AGENTS.md"
forbid_pattern ".harness/entrypoint.md" "CLAUDE.md"
forbid_pattern ".harness/entrypoint.md" "GEMINI.md"
forbid_pattern ".harness/entrypoint.md" ".claude/"
forbid_pattern ".harness/entrypoint.md" ".codex/"
forbid_pattern ".harness/entrypoint.md" ".gemini/"

runtime_mode=$(infer_runtime_mode)

if [ "$runtime_mode" = "shared" ] || [ -d ".harness/workspace/current" ] || [ -d ".harness/workspace/briefs" ]; then
  require_file ".harness/workspace/current/README.md"
  require_file ".harness/workspace/archive/briefs/README.md"

  for current_file in .harness/workspace/current/*.md; do
    [ "$(basename "$current_file")" = "README.md" ] && continue
    status=$(current_field_value "$current_file" "Status")
    last_updated=$(current_field_value "$current_file" "Last updated")
    active_snapshot=$(current_field_value "$current_file" "Active snapshot" | sed 's/^`//; s/`$//')
    supersedes=$(current_field_value "$current_file" "Supersedes")

    if [ -z "$status" ]; then
      fail "$current_file has no parseable Status"
    fi

    if [ -z "$last_updated" ]; then
      fail "$current_file has no parseable Last updated"
    fi

    if [ -z "$active_snapshot" ]; then
      fail "$current_file has no parseable Active snapshot"
    elif [ ! -f "$active_snapshot" ]; then
      fail "active snapshot missing for $current_file: $active_snapshot"
    fi

    if [ -z "$supersedes" ]; then
      fail "$current_file has no parseable Supersedes"
    fi
  done

  versioned_in_current=$(find .harness/workspace/current -type f -name '*.md' ! -name 'README.md' | grep -E -- '-v[0-9]+\.md$' || true)
  if [ -n "$versioned_in_current" ]; then
    fail "versioned markdown found in .harness/workspace/current"
  fi

  versioned_in_briefs=$(find .harness/workspace/briefs -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | grep -E -- '-v[0-9]+\.md$' || true)
  if [ -n "$versioned_in_briefs" ]; then
    fail "versioned markdown found in .harness/workspace/briefs"
  fi
fi

if [ "$ok" -eq 1 ]; then
  say "document system audit: ok"
  exit 0
fi

exit 1
