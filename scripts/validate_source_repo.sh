#!/bin/sh
set -eu

quiet="${1:-}"
ok=1

say() {
  [ "$quiet" = "--quiet" ] || echo "$1"
}

fail() {
  ok=0
  say "$1"
}

require_file() {
  [ -e "$1" ] || fail "missing: $1"
}

require_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
}

require_exec() {
  [ -x "$1" ] || fail "not executable: $1"
}

forbidden_path() {
  [ ! -e "$1" ] || fail "source repo must not contain consumer/runtime surface: $1"
}

require_file "SKILL.md"
require_dir "skills"
require_dir "roles"
require_dir "scripts"
require_dir "docs"
require_dir "references"

require_file "docs/project-structure.md"
require_file "references/layering.md"
require_file "references/runtime-workspace.md"
require_dir "references/contracts"
require_file "references/contracts/minimum-core-runtime-tree.toml"
require_file "references/top-level-surface.md"
require_file "roles/README.md"

require_exec "scripts/sync_agent_projections.sh"
require_exec "scripts/sync_claude_skill_projections.sh"
require_exec "scripts/materialize_runtime_fixture.sh"
require_exec "scripts/run_state_validation_slice.sh"
require_exec "scripts/audit_role_schema.sh"
require_exec "scripts/new_role.sh"
require_exec "scripts/edit_role.sh"

forbidden_path ".harness"
forbidden_path ".agents/skills/harness"
forbidden_path "AGENTS.md"
forbidden_path "CLAUDE.md"
forbidden_path "GEMINI.md"

if rg -n '/Users/[^/]+/.+/(\\.agents/skills/harness|\\.harness)/|/Users/[^/]+/.+/AGENTS\\.md|/Users/[^/]+/.+/CLAUDE\\.md|/Users/[^/]+/.+/GEMINI\\.md|/Users/[^/]+/.+/(\\.codex|\\.gemini)/' \
  --glob '!references/archive/**' \
  --glob '!docs/research/frontier-practices-2026.md' \
  . >/dev/null 2>&1; then
  fail "found consumer-specific absolute paths outside archive/"
fi

if [ "$ok" -eq 1 ]; then
  say "source repo audit: ok"
  exit 0
fi

exit 1
