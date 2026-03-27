#!/bin/sh
set -eu

mode="${1:-}"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

append_file() {
  file="$1"
  [ -n "$file" ] || return 0
  printf '%s\n' "$file" >>"$tmp"
}

collect_all_files() {
  for dir in \
    .harness/tasks \
    .harness/workspace/research/sources \
    .harness/workspace/research/dispatches \
    .harness/workspace/decisions/log \
    .harness/workspace/briefs \
    .harness/workspace/departments
  do
    [ -d "$dir" ] || continue
    find "$dir" -type f -name '*.md'
  done | sort
}

collect_staged_files() {
  git diff --cached --name-only --diff-filter=ACMR
}

is_governed_artifact() {
  case "$1" in
    .harness/tasks/*/refs/*.md|.harness/tasks/*/refs/sources/*.md|.harness/tasks/*/working/*.md|.harness/tasks/*/working/*/*.md|.harness/tasks/*/outputs/*.md|.harness/tasks/*/closure/*.md|\
    .harness/workspace/research/sources/*.md|.harness/workspace/research/dispatches/*.md|.harness/workspace/decisions/log/*.md|.harness/workspace/briefs/*.md|.harness/workspace/departments/*/workspace/memos/*.md|.harness/workspace/departments/*/workspace/outputs/*.md)
      case "$(basename "$1")" in
        README.md)
          return 1
          ;;
      esac
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_dispatch_note() {
  case "$1" in
    .harness/tasks/*/working/*-research-dispatch.md|\
    .harness/workspace/research/dispatches/*.md)
      case "$(basename "$1")" in
        README.md)
          return 1
          ;;
      esac
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_source_note() {
  case "$1" in
    .harness/tasks/*/refs/sources/*.md|\
    .harness/workspace/research/sources/*.md)
      case "$(basename "$1")" in
        README.md)
          return 1
          ;;
      esac
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_field() {
  file="$1"
  label="$2"

  if ! awk -v label="$label" '
    BEGIN {
      prefix = "- " label ":"
      found = 0
      waiting = 0
    }
    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value != "") {
        found = 1
        exit 0
      }
      waiting = 1
      next
    }
    waiting == 1 {
      if ($0 ~ /^-[[:space:]]/) {
        exit 1
      }
      if ($0 ~ /^[[:space:]]*$/) {
        next
      }
      found = 1
      exit 0
    }
    END {
      if (found == 1) {
        exit 0
      }
      exit 1
    }
  ' "$file"; then
    printf '%s\n' "freshness gate failed: $file missing non-empty field '${label}'" >&2
    return 1
  fi

  return 0
}

validate_source_note() {
  file="$1"
  ok=0

  require_field "$file" "Source" || ok=1
  require_field "$file" "URL" || ok=1
  require_field "$file" "Type" || ok=1
  require_field "$file" "Accessed date" || ok=1
  require_field "$file" "Trust level" || ok=1
  require_field "$file" "Notes" || ok=1

  return "$ok"
}

validate_dispatch_note() {
  file="$1"
  ok=0

  require_field "$file" "Date" || ok=1
  require_field "$file" "Dispatcher" || ok=1
  require_field "$file" "Topic" || ok=1
  require_field "$file" "Volatile status" || ok=1
  require_field "$file" "Research owner" || ok=1
  require_field "$file" "Required freshness window" || ok=1
  require_field "$file" "Required source types" || ok=1
  require_field "$file" "Required deliverable" || ok=1
  require_field "$file" "Downstream consumer" || ok=1
  require_field "$file" "Blocking status" || ok=1
  require_field "$file" "Notes" || ok=1

  return "$ok"
}

field_content() {
  file="$1"
  label="$2"

  awk -v label="$label" '
    BEGIN {
      prefix = "- " label ":"
      capture = 0
    }
    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value != "") {
        print value
      }
      capture = 1
      next
    }
    capture == 1 {
      if ($0 ~ /^-[[:space:]]/) {
        exit
      }
      if ($0 ~ /^[[:space:]]*$/) {
        next
      }
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print $0
    }
  ' "$file" | paste -sd ' ' -
}

validate_verification_mode() {
  file="$1"
  mode=$(field_content "$file" "Verification mode")

  case "$mode" in
    internal-only|web-verified|mixed)
      return 0
      ;;
    *)
      printf '%s\n' "freshness gate failed: $file has invalid 'Verification mode' value '$mode'" >&2
      return 1
      ;;
  esac
}

require_external_reference_if_needed() {
  file="$1"
  mode=$(field_content "$file" "Verification mode")
  sources=$(field_content "$file" "Sources reviewed")

  case "$mode" in
    web-verified|mixed)
      if ! printf '%s\n' "$sources" | grep -Eq 'https?://|.harness/tasks/[A-Za-z0-9._-]+/refs/sources/|.harness/workspace/research/sources/'; then
        printf '%s\n' "freshness gate failed: $file is '$mode' but 'Sources reviewed' has no URL or source-note reference" >&2
        return 1
      fi
      ;;
  esac

  return 0
}

validate_referenced_source_notes() {
  file="$1"
  mode=$(field_content "$file" "Verification mode")
  refs=$(
    grep -Eo '(\.harness/tasks/[A-Za-z0-9._-]+/refs/sources/[A-Za-z0-9._/-]+\.md|\.harness/workspace/research/sources/[A-Za-z0-9._/-]+\.md)' "$file" | sort -u || true
  )

  case "$mode" in
    web-verified|mixed)
      if [ -n "$refs" ]; then
        for ref in $refs; do
          if [ ! -f "$ref" ]; then
            printf '%s\n' "freshness gate failed: $file references missing source note '$ref'" >&2
            return 1
          fi
          if ! validate_source_note "$ref"; then
            printf '%s\n' "freshness gate failed: $file references invalid source note '$ref'" >&2
            return 1
          fi
        done
      fi
      ;;
  esac

  return 0
}

validate_referenced_dispatches() {
  file="$1"
  refs=$(
    grep -Eo '(\.harness/tasks/[A-Za-z0-9._-]+/working/[A-Za-z0-9._/-]+-research-dispatch\.md|\.harness/workspace/research/dispatches/[A-Za-z0-9._/-]+\.md)' "$file" | sort -u || true
  )

  [ -n "$refs" ] || return 0

  for ref in $refs; do
    if [ ! -f "$ref" ]; then
      printf '%s\n' "freshness gate failed: $file references missing research dispatch '$ref'" >&2
      return 1
    fi
    if ! validate_dispatch_note "$ref"; then
      printf '%s\n' "freshness gate failed: $file references invalid research dispatch '$ref'" >&2
      return 1
    fi
  done

  return 0
}

require_dispatch_reference_if_needed() {
  file="$1"
  mode=$(field_content "$file" "Verification mode")
  dispatch=$(field_content "$file" "Research dispatch")

  case "$mode" in
    web-verified|mixed)
      if ! printf '%s\n' "$dispatch" | grep -Eq '.harness/tasks/[A-Za-z0-9._-]+/working/[A-Za-z0-9._/-]+-research-dispatch\.md|.harness/workspace/research/dispatches/[A-Za-z0-9._/-]+\.md'; then
        printf '%s\n' "freshness gate failed: $file is '$mode' but 'Research dispatch' does not reference a dispatch artifact" >&2
        return 1
      fi
      ;;
  esac

  return 0
}

validate_file() {
  file="$1"
  ok=0

  heading=$(sed -n '1p' "$file" | tr -d '\r')

  if is_source_note "$file"; then
    validate_source_note "$file" || ok=1
    return "$ok"
  fi

  if is_dispatch_note "$file"; then
    validate_dispatch_note "$file" || ok=1
    return "$ok"
  fi

  case "$heading" in
    "# Research Memo")
      require_field "$file" "Research dispatch" || ok=1
      require_field "$file" "Verification date" || ok=1
      require_field "$file" "Verification mode" || ok=1
      require_field "$file" "Freshness level" || ok=1
      require_field "$file" "Sources reviewed" || ok=1
      require_field "$file" "Conflicting sources" || ok=1
      require_field "$file" "Earliest-source check" || ok=1
      validate_verification_mode "$file" || ok=1
      require_dispatch_reference_if_needed "$file" || ok=1
      require_external_reference_if_needed "$file" || ok=1
      validate_referenced_source_notes "$file" || ok=1
      validate_referenced_dispatches "$file" || ok=1
      ;;
    "# Decision Pack")
      require_field "$file" "Research dispatch" || ok=1
      require_field "$file" "Verification date" || ok=1
      require_field "$file" "Verification mode" || ok=1
      require_field "$file" "Sources reviewed" || ok=1
      require_field "$file" "Freshness caveats" || ok=1
      validate_verification_mode "$file" || ok=1
      require_dispatch_reference_if_needed "$file" || ok=1
      require_external_reference_if_needed "$file" || ok=1
      validate_referenced_source_notes "$file" || ok=1
      validate_referenced_dispatches "$file" || ok=1
      ;;
    "# Vision Meeting Brief"|"# Requirements Meeting Brief"|"# Governance Meeting Brief")
      require_field "$file" "Verification date" || ok=1
      require_field "$file" "Verification mode" || ok=1
      require_field "$file" "Sources reviewed" || ok=1
      require_field "$file" "What remains unverified" || ok=1
      validate_verification_mode "$file" || ok=1
      require_external_reference_if_needed "$file" || ok=1
      validate_referenced_source_notes "$file" || ok=1
      ;;
    "# Brainstorming Notes")
      require_field "$file" "External claims needing freshness check" || ok=1
      ;;
    *)
      return 0
      ;;
  esac

  return "$ok"
}

case "$mode" in
  --staged)
    collect_staged_files >"$tmp"
    shift
    ;;
  "")
    collect_all_files >"$tmp"
    ;;
  *)
    : >"$tmp"
    for file in "$@"; do
      append_file "$file"
    done
    ;;
esac

checked=0
failed=0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue
  is_governed_artifact "$file" || continue
  checked=$((checked + 1))
  if ! validate_file "$file"; then
    failed=1
  fi
done <"$tmp"

if [ "$failed" -eq 1 ]; then
  exit 1
fi

printf '%s\n' "freshness gate: ok (${checked} files checked)"
