#!/bin/sh
set -eu

cat CLAUDE.md > GEMINI.md

for file in .harness/workspace/departments/*/AGENTS.md; do
  dir=$(dirname "$file")
  cat "$file" > "$dir/CLAUDE.md"
  cat "$file" > "$dir/GEMINI.md"
done

echo "tool entrypoints synced"
