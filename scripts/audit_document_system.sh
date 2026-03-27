#!/bin/sh
set -eu

quiet="${1:-}"
ok=1

if [ -f "SKILL.md" ] && [ -d "skills" ] && [ -d "roles" ] && [ ! -d ".agents/skills/harness" ]; then
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

require_file "CLAUDE.md"
require_file "AGENTS.md"
require_file "README.md"
require_file ".harness/entrypoint.md"
require_file ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md"
require_file ".agents/skills/harness/docs/workflows/agent-operator-contract.md"
require_file ".agents/skills/harness/docs/workflows/provider-deltas/codex.md"
require_file ".agents/skills/harness/docs/workflows/code_review.md"
require_file ".harness/workspace/current/README.md"
require_file ".harness/workspace/archive/briefs/README.md"

require_pattern "CLAUDE.md" ".harness/entrypoint.md"
require_pattern "AGENTS.md" ".harness/entrypoint.md"
require_pattern "README.md" ".harness/entrypoint.md"
require_pattern "README.md" ".harness/workspace/current/product-vision.md"
require_pattern "README.md" "code_review.md"
require_pattern "README.md" "agent-operator-contract.md"
require_pattern ".harness/entrypoint.md" ".agents/skills/harness/SKILL.md"
require_pattern ".harness/entrypoint.md" ".harness/README.md"
require_pattern ".harness/entrypoint.md" ".harness/compatibility.toml"
require_pattern ".harness/entrypoint.md" ".harness/migration-inventory.toml"
require_pattern ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" ".harness/entrypoint.md"
require_pattern ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" "code_review.md"
require_pattern ".agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md" "agent-operator-contract.md"

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

if [ "$ok" -eq 1 ]; then
  say "document system audit: ok"
  exit 0
fi

exit 1
