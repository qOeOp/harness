#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (CDPATH= cd -- "$script_dir/.." && pwd))

usage() {
  cat <<'EOF' >&2
usage: ./scripts/enforce_role_policy.sh --role <slug> --entrypoint <path> --action <action> [--consumer-runtime-root <path>] [--proposal <path>] [--stage <name>]
EOF
  exit 1
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

csv_contains() {
  csv="$1"
  needle="$2"
  printf '%s' "$csv" | tr ',' '\n' | awk -v needle="$needle" '
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

resolve_dir() {
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

resolve_file() {
  target="$1"
  [ -f "$target" ] || return 1
  target_dir=$(dirname "$target")
  target_file=$(basename "$target")
  (
    CDPATH= cd -- "$target_dir" 2>/dev/null && printf '%s/%s\n' "$(pwd)" "$target_file"
  )
}

path_within_csv_roots() {
  relative_path="$1"
  csv_roots="$2"

  if [ "$csv_roots" = "none" ]; then
    return 1
  fi

  printf '%s' "$csv_roots" | tr ',' '\n' | awk -v path="$relative_path" '
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 == "") {
        next
      }
      root = $0
      if (path == root || index(path, root) == 1) {
        found = 1
        exit
      }
    }
    END { exit found ? 0 : 1 }
  '
}

role_slug=""
entrypoint=""
action=""
runtime_root=""
proposal_path=""
stage=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role)
      [ "$#" -ge 2 ] || usage
      role_slug="$2"
      shift 2
      ;;
    --entrypoint)
      [ "$#" -ge 2 ] || usage
      entrypoint="$2"
      shift 2
      ;;
    --action)
      [ "$#" -ge 2 ] || usage
      action="$2"
      shift 2
      ;;
    --runtime-root)
      [ "$#" -ge 2 ] || usage
      runtime_root="$2"
      shift 2
      ;;
    --consumer-runtime-root)
      [ "$#" -ge 2 ] || usage
      runtime_root="$2"
      shift 2
      ;;
    --proposal)
      [ "$#" -ge 2 ] || usage
      proposal_path="$2"
      shift 2
      ;;
    --stage)
      [ "$#" -ge 2 ] || usage
      stage="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$role_slug" ] || usage
[ -n "$entrypoint" ] || usage
[ -n "$action" ] || usage

role_file="$repo_root/roles/$role_slug.md"
[ -f "$role_file" ] || {
  echo "missing role file: $role_file" >&2
  exit 1
}

policy_allowed_entrypoints=$(frontmatter_value "$role_file" "policy_allowed_entrypoints")
policy_allowed_actions=$(frontmatter_value "$role_file" "policy_allowed_actions")
policy_mutation_actions=$(frontmatter_value "$role_file" "policy_mutation_actions")
policy_write_roots=$(frontmatter_value "$role_file" "policy_write_roots")
policy_forbidden_roots=$(frontmatter_value "$role_file" "policy_forbidden_roots")
policy_required_artifact_type=$(frontmatter_value "$role_file" "policy_required_artifact_type")
policy_required_stage=$(frontmatter_value "$role_file" "policy_required_stage")

[ -n "$policy_allowed_entrypoints" ] || {
  echo "role $role_slug does not declare policy schema" >&2
  exit 1
}

csv_contains "$policy_allowed_entrypoints" "$entrypoint" || {
  echo "entrypoint '$entrypoint' is not allowed for role $role_slug" >&2
  exit 1
}

csv_contains "$policy_allowed_actions" "$action" || {
  echo "action '$action' is not allowed for role $role_slug" >&2
  exit 1
}

is_mutation=1
if [ "$policy_mutation_actions" = "none" ]; then
  is_mutation=0
elif ! csv_contains "$policy_mutation_actions" "$action"; then
  is_mutation=0
fi

if [ -n "$runtime_root" ]; then
  resolved_runtime_root=$(resolve_dir "$runtime_root")
  [ -n "$resolved_runtime_root" ] || {
    echo "unable to resolve runtime root: $runtime_root" >&2
    exit 1
  }
else
  resolved_runtime_root=""
fi

if [ "$is_mutation" -eq 1 ]; then
  [ -n "$resolved_runtime_root" ] || {
    echo "mutation action '$action' requires --consumer-runtime-root" >&2
    exit 1
  }

  target_relative=".harness/workspace/roles/"
  path_within_csv_roots "$target_relative" "$policy_write_roots" || {
    echo "target path '$target_relative' is outside allowed write roots for role $role_slug" >&2
    exit 1
  }

  if [ "$policy_forbidden_roots" != "none" ] && path_within_csv_roots "$target_relative" "$policy_forbidden_roots"; then
    echo "target path '$target_relative' is inside forbidden roots for role $role_slug" >&2
    exit 1
  fi

  if [ "$policy_required_stage" != "none" ]; then
    [ "$stage" = "$policy_required_stage" ] || {
      echo "mutation action '$action' requires stage '$policy_required_stage' for role $role_slug" >&2
      exit 1
    }
  fi

  if [ "$policy_required_artifact_type" = "role-change-proposal" ]; then
    [ -n "$proposal_path" ] || {
      echo "mutation action '$action' requires --proposal for role $role_slug" >&2
      exit 1
    }

    resolved_proposal_path=$(resolve_file "$proposal_path" || true)
    if [ -z "$resolved_proposal_path" ] && [ -n "$resolved_runtime_root" ]; then
      case "$proposal_path" in
        /*) ;;
        *)
          resolved_proposal_path=$(resolve_file "$resolved_runtime_root/$proposal_path" || true)
          ;;
      esac
    fi
    [ -n "$resolved_proposal_path" ] || {
      echo "unable to resolve proposal file: $proposal_path" >&2
      exit 1
    }

    case "$resolved_proposal_path" in
      "$resolved_runtime_root"/.harness/tasks/WI-*/closure/*-role-change-proposal.md) ;;
      *)
        echo "proposal must live under .harness/tasks/<task-id>/closure/*-role-change-proposal.md" >&2
        exit 1
        ;;
    esac

    grep -Fq "# Role Change Proposal" "$resolved_proposal_path" || {
      echo "proposal is missing Role Change Proposal heading: $resolved_proposal_path" >&2
      exit 1
    }

    relative_proposal_path=${resolved_proposal_path#"$resolved_runtime_root"/}
    work_item_id=$(printf '%s\n' "$relative_proposal_path" | sed 's#^.harness/tasks/\(WI-[^/]*\)/closure/.*$#\1#')
    task_file="$resolved_runtime_root/.harness/tasks/$work_item_id/task.md"
    [ -f "$task_file" ] || {
      echo "missing linked task file for proposal: $task_file" >&2
      exit 1
    }

    grep -Fq "$relative_proposal_path|role-change-proposal|" "$task_file" || {
      echo "proposal is not linked from task artifact list: $task_file" >&2
      exit 1
    }
  fi
fi
