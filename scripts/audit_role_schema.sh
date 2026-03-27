#!/bin/sh
set -eu

quiet="${1:-}"
ok=1

if [ -f "SKILL.md" ] && [ -d "roles" ]; then
  canonical_root="roles"
elif [ -f ".agents/skills/harness/SKILL.md" ] && [ -d ".agents/skills/harness/roles" ]; then
  canonical_root=".agents/skills/harness/roles"
else
  echo "unable to resolve canonical roles directory" >&2
  exit 1
fi

claude_root=".claude/agents"
codex_root=".codex/agents"
check_claude_projection=0
check_codex_projection=0

[ -d "$claude_root" ] && check_claude_projection=1
[ -d "$codex_root" ] && check_codex_projection=1

say() {
  [ "$quiet" = "--quiet" ] || echo "$1"
}

fail() {
  ok=0
  say "$1"
}

frontmatter_value() {
  file="$1"
  key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && index($0, key ": ") == 1 {
      print substr($0, length(key ": ") + 1)
      exit
    }
  ' "$file"
}

require_key() {
  file="$1"
  key="$2"
  value=$(frontmatter_value "$file" "$key")
  if [ -z "$value" ]; then
    fail "missing frontmatter key '$key' in $file"
  fi
}

for role_file in "$canonical_root"/*.md; do
  [ -f "$role_file" ] || continue
  [ "$(basename "$role_file")" = "README.md" ] && continue

  first_line=$(sed -n '1p' "$role_file")
  [ "$first_line" = "---" ] || fail "role file missing opening frontmatter fence in $role_file"

  if ! awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { found = 1; exit }
    END { exit found ? 0 : 1 }
  ' "$role_file"; then
    fail "role file missing closing frontmatter fence in $role_file"
    continue
  fi

  for key in \
    schema_version \
    slug \
    claude_file \
    claude_name \
    claude_description \
    claude_tools \
    claude_model \
    codex_file \
    codex_name \
    codex_description \
    codex_model \
    codex_reasoning_effort \
    codex_sandbox_mode \
    codex_nicknames
  do
    require_key "$role_file" "$key"
  done

  schema_version=$(frontmatter_value "$role_file" "schema_version")
  slug=$(frontmatter_value "$role_file" "slug")
  claude_file=$(frontmatter_value "$role_file" "claude_file")
  codex_file=$(frontmatter_value "$role_file" "codex_file")

  [ "$schema_version" = "1" ] || fail "unsupported schema_version '$schema_version' in $role_file"
  [ "$slug" = "$(basename "$role_file" .md)" ] || fail "role slug '$slug' does not match file basename in $role_file"

  if ! grep -Fq "## Canonical Instructions" "$role_file"; then
    fail "missing Canonical Instructions section in $role_file"
  fi

  if [ "$check_claude_projection" -eq 1 ]; then
    if [ ! -f "$claude_root/$claude_file" ]; then
      fail "missing Claude projection '$claude_root/$claude_file' for $role_file"
    elif ! grep -Fq "AUTO-GENERATED projection" "$claude_root/$claude_file"; then
      fail "Claude projection missing generated marker in $claude_root/$claude_file"
    fi
  fi

  if [ "$check_codex_projection" -eq 1 ]; then
    if [ ! -f "$codex_root/$codex_file" ]; then
      fail "missing Codex projection '$codex_root/$codex_file' for $role_file"
    elif ! grep -Fq "AUTO-GENERATED projection" "$codex_root/$codex_file"; then
      fail "Codex projection missing generated marker in $codex_root/$codex_file"
    fi
  fi
done

if [ "$ok" -eq 1 ]; then
  say "role schema audit: ok"
  exit 0
fi

exit 1
