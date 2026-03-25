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
  if [ ! -e "$1" ]; then
    fail "missing: $1"
  fi
}

same_file() {
  left="$1"
  right="$2"
  if ! cmp -s "$left" "$right"; then
    fail "mismatch: $left != $right"
  fi
}

require_file "AGENTS.md"
require_file "CLAUDE.md"
require_file "GEMINI.md"
require_file ".gemini/settings.json"

same_file "AGENTS.md" "CLAUDE.md"
same_file "AGENTS.md" "GEMINI.md"

if ! grep -Fq '"GEMINI.md"' ".gemini/settings.json"; then
  fail "missing GEMINI.md context routing in .gemini/settings.json"
fi

for file in .harness/workspace/departments/*/AGENTS.md; do
  dir=$(dirname "$file")
  require_file "$dir/CLAUDE.md"
  require_file "$dir/GEMINI.md"
  same_file "$file" "$dir/CLAUDE.md"
  same_file "$file" "$dir/GEMINI.md"
done

if [ "$ok" -eq 1 ]; then
  say "tool parity audit: ok"
  exit 0
fi

exit 1
