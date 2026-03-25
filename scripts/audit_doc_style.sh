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

forbidden_patterns='^## Divergent Hypotheses$|^## First Principles Deconstruction$|^## Convergence to Excellence$|^## 问题定义$|^## 第一性原则$|^## 关键判断$'

for file in README.md AGENTS.md CLAUDE.md GEMINI.md .agents/skills/harness/docs/project-structure.md .harness/workspace/departments/README.md; do
  if [ -f "$file" ] && grep -Eq "$forbidden_patterns" "$file"; then
    fail "reasoning-style headings found in canonical doc: $file"
  fi
done

for file in $(find .agents/skills/harness/docs/charter .agents/skills/harness/docs/memory .agents/skills/harness/docs/organization .agents/skills/harness/docs/workflows -type f -name '*.md' | sort); do
  if [ -f "$file" ] && grep -Eq "$forbidden_patterns" "$file"; then
    fail "reasoning-style headings found in canonical doc: $file"
  fi
done

for file in .harness/workspace/departments/*/AGENTS.md .harness/workspace/departments/*/CLAUDE.md .harness/workspace/departments/*/GEMINI.md .harness/workspace/departments/*/README.md .harness/workspace/departments/*/charter.md .harness/workspace/departments/*/interfaces.md; do
  if [ -f "$file" ] && grep -Eq "$forbidden_patterns" "$file"; then
    fail "reasoning-style headings found in canonical doc: $file"
  fi
done

if [ "$ok" -eq 1 ]; then
  say "doc style audit: ok"
  exit 0
fi

exit 1
