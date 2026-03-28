#!/bin/sh
set -eu

quiet=""
role_dir=""
ok=1

usage() {
  cat <<'EOF' >&2
usage: ./scripts/audit_role_schema.sh [--quiet] [--role-dir <path>]
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quiet)
      quiet="--quiet"
      shift
      ;;
    --role-dir)
      [ "$#" -ge 2 ] || usage
      role_dir="${2:-}"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ -n "$role_dir" ]; then
  canonical_root="$role_dir"
elif [ -f "SKILL.md" ] && [ -d "roles" ] && [ ! -d ".harness" ]; then
  canonical_root="roles"
else
  echo "audit_role_schema.sh only validates the framework source repo canonical roles directory unless --role-dir is provided." >&2
  exit 1
fi

[ -d "$canonical_root" ] || {
  echo "missing role directory: $canonical_root" >&2
  exit 1
}

say() {
  [ "$quiet" = "--quiet" ] || echo "$1"
}

fail() {
  ok=0
  say "$1"
}

csv_contains() {
  csv="$1"
  needle="$2"
  value_list=$(printf '%s' "$csv" | tr ',' '\n')
  printf '%s\n' "$value_list" | awk -v needle="$needle" '
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 == needle) {
        found = 1
        exit
      }
    }
    END { exit found ? 0 : 1 }
  '
}

trim() {
  printf '%s\n' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
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

validate_skill_csv() {
  role_file="$1"
  key="$2"
  csv=$(frontmatter_value "$role_file" "$key")

  [ -n "$csv" ] || return 0
  [ "$csv" != "none" ] || return 0

  old_ifs=${IFS- }
  IFS=','
  set -- $csv
  IFS=$old_ifs

  for skill_slug in "$@"; do
    skill_slug=$(trim "$skill_slug")
    [ -n "$skill_slug" ] || continue
    case "$skill_slug" in
      *[!a-z0-9-]*)
        fail "invalid skill slug '$skill_slug' in $key of $role_file"
        continue
        ;;
    esac

    if [ -d "skills/$skill_slug" ]; then
      continue
    fi

    fail "unknown skill slug '$skill_slug' in $key of $role_file"
  done
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

  validate_skill_csv "$role_file" "default_skills"
  validate_skill_csv "$role_file" "secondary_skills"

  schema_version=$(frontmatter_value "$role_file" "schema_version")
  slug=$(frontmatter_value "$role_file" "slug")
  claude_file=$(frontmatter_value "$role_file" "claude_file")
  codex_file=$(frontmatter_value "$role_file" "codex_file")

  [ "$schema_version" = "1" ] || fail "unsupported schema_version '$schema_version' in $role_file"
  [ "$slug" = "$(basename "$role_file" .md)" ] || fail "role slug '$slug' does not match file basename in $role_file"

  if ! grep -Eq '^## (Canonical|Runtime) Instructions$' "$role_file"; then
    fail "missing Canonical Instructions or Runtime Instructions section in $role_file"
  fi

  policy_present=0
  for policy_key in \
    policy_allowed_entrypoints \
    policy_allowed_actions \
    policy_mutation_actions \
    policy_write_roots \
    policy_forbidden_roots \
    policy_required_artifact_type \
    policy_required_stage
  do
    if [ -n "$(frontmatter_value "$role_file" "$policy_key")" ]; then
      policy_present=1
      break
    fi
  done

  if [ "$policy_present" -eq 1 ] || [ "$slug" = "runtime-role-manager" ]; then
    for policy_key in \
      policy_allowed_entrypoints \
      policy_allowed_actions \
      policy_mutation_actions \
      policy_write_roots \
      policy_forbidden_roots \
      policy_required_artifact_type \
      policy_required_stage
    do
      require_key "$role_file" "$policy_key"
    done

    policy_allowed_entrypoints=$(frontmatter_value "$role_file" "policy_allowed_entrypoints")
    policy_allowed_actions=$(frontmatter_value "$role_file" "policy_allowed_actions")
    policy_mutation_actions=$(frontmatter_value "$role_file" "policy_mutation_actions")
    policy_write_roots=$(frontmatter_value "$role_file" "policy_write_roots")
    policy_required_artifact_type=$(frontmatter_value "$role_file" "policy_required_artifact_type")
    policy_required_stage=$(frontmatter_value "$role_file" "policy_required_stage")

    [ "$policy_allowed_entrypoints" != "none" ] || fail "policy_allowed_entrypoints must not be none in $role_file"
    [ "$policy_allowed_actions" != "none" ] || fail "policy_allowed_actions must not be none in $role_file"

    if [ "$policy_mutation_actions" != "none" ] && [ "$policy_write_roots" = "none" ]; then
      fail "mutation-capable role must declare policy_write_roots in $role_file"
    fi

    if [ "$policy_required_artifact_type" != "none" ] && [ "$policy_required_stage" = "none" ]; then
      fail "artifact-gated role must declare policy_required_stage in $role_file"
    fi

    if [ "$slug" = "runtime-role-manager" ]; then
      csv_contains "$policy_allowed_entrypoints" "scripts/runtime_role_manager.sh" || fail "runtime-role-manager must allow scripts/runtime_role_manager.sh in $role_file"
      csv_contains "$policy_allowed_actions" "create" || fail "runtime-role-manager policy must allow create in $role_file"
      csv_contains "$policy_allowed_actions" "edit" || fail "runtime-role-manager policy must allow edit in $role_file"
      csv_contains "$policy_allowed_actions" "audit" || fail "runtime-role-manager policy must allow audit in $role_file"
      [ "$policy_required_artifact_type" = "role-change-proposal" ] || fail "runtime-role-manager must require role-change-proposal in $role_file"
      [ "$policy_required_stage" = "post-acceptance-compounding" ] || fail "runtime-role-manager must require post-acceptance-compounding in $role_file"
    fi
  fi

done

if [ "$ok" -eq 1 ]; then
  say "role schema audit: ok"
  exit 0
fi

exit 1
