#!/bin/sh

normalize_consumer_runtime_root() {
  target="$1"
  case "$target" in
    */.harness)
      target="${target%/.harness}"
      ;;
  esac

  (
    CDPATH= cd -- "$target" 2>/dev/null && pwd
  )
}

consumer_runtime_manifest_path() {
  runtime_root="$1"
  printf '%s/.harness/manifest.toml\n' "$runtime_root"
}

consumer_runtime_manifest_value() {
  runtime_root="$1"
  key="$2"
  manifest_path=$(consumer_runtime_manifest_path "$runtime_root")

  [ -f "$manifest_path" ] || return 1

  awk -F= -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value = $2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$manifest_path"
}

consumer_runtime_governance_enabled() {
  runtime_root="$1"
  runtime_mode=$(consumer_runtime_manifest_value "$runtime_root" "runtime_mode" || printf '%s\n' "")
  governance_enabled=$(consumer_runtime_manifest_value "$runtime_root" "advanced_governance_enabled" || printf '%s\n' "")

  if [ "$runtime_mode" = "shared-writeback" ] || [ "$runtime_mode" = "advanced-governance" ] || [ "$governance_enabled" = "true" ]; then
    return 0
  fi

  return 1
}

require_materialized_consumer_runtime_root() {
  runtime_root="$1"
  caller_name="$2"
  source_repo_root="${3:-}"

  [ -n "$runtime_root" ] || {
    echo "$caller_name requires a consumer runtime root" >&2
    exit 1
  }

  if [ -n "$source_repo_root" ] && [ "$runtime_root" = "$source_repo_root" ]; then
    echo "$caller_name must not target the harness framework source repo itself." >&2
    exit 1
  fi

  manifest_path=$(consumer_runtime_manifest_path "$runtime_root")
  [ -f "$manifest_path" ] || {
    echo "$caller_name requires a materialized consumer runtime with .harness/manifest.toml: $runtime_root" >&2
    exit 1
  }

  [ -d "$runtime_root/.harness/tasks" ] || {
    echo "$caller_name requires a materialized consumer runtime with .harness/tasks/: $runtime_root" >&2
    exit 1
  }
}

require_advanced_governance_consumer_runtime_root() {
  runtime_root="$1"
  caller_name="$2"
  source_repo_root="${3:-}"

  require_materialized_consumer_runtime_root "$runtime_root" "$caller_name" "$source_repo_root"

  consumer_runtime_governance_enabled "$runtime_root" || {
    echo "$caller_name requires a consumer runtime with shared writeback enabled: $runtime_root" >&2
    exit 1
  }

  [ -d "$runtime_root/.harness/workspace" ] || {
    echo "$caller_name requires .harness/workspace/ to exist in the target consumer runtime: $runtime_root" >&2
    exit 1
  }
}
