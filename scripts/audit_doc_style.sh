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

for file in README.md docs/project-structure.md; do
  if [ -f "$file" ] && grep -Eq "$forbidden_patterns" "$file"; then
    fail "reasoning-style headings found in canonical doc: $file"
  fi
done

for file in $(find docs/charter docs/memory docs/organization docs/workflows -type f -name '*.md' 2>/dev/null | sort); do
  if [ -f "$file" ] && grep -Eq "$forbidden_patterns" "$file"; then
    fail "reasoning-style headings found in canonical doc: $file"
  fi
done

if [ "$ok" -eq 1 ]; then
  say "doc style audit: ok"
  exit 0
fi

exit 1
