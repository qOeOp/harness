#!/bin/sh

default_consumer_runtime_route_table_path() {
  if [ -n "${HARNESS_CONSUMER_RUNTIME_ROUTE_TABLE:-}" ]; then
    printf '%s\n' "$HARNESS_CONSUMER_RUNTIME_ROUTE_TABLE"
    return 0
  fi

  if [ -n "${HOME:-}" ]; then
    printf '%s/.harness/consumer-runtime-routes.tsv\n' "$HOME"
    return 0
  fi

  return 1
}

resolve_consumer_runtime_route_table_path() {
  table_path="${1:-}"

  if [ -n "$table_path" ]; then
    printf '%s\n' "$table_path"
    return 0
  fi

  default_consumer_runtime_route_table_path
}

consumer_runtime_route_table_example() {
  cat <<'EOF'
# consumer-runtime<TAB>consumer-repo-root<TAB>optional-notes
dogfood	/absolute/path/to/consumer-repo	Daily sandbox
prod-like	/absolute/path/to/another-consumer-repo	Advanced governance runtime
EOF
}

resolve_consumer_runtime_root_from_table() {
  runtime_name="$1"
  requested_table_path="${2:-}"
  table_path=$(resolve_consumer_runtime_route_table_path "$requested_table_path" || true)

  [ -n "$table_path" ] || {
    echo "unable to determine consumer runtime route table path; set HARNESS_CONSUMER_RUNTIME_ROUTE_TABLE or pass --consumer-runtime-table" >&2
    return 1
  }

  [ -f "$table_path" ] || {
    echo "missing consumer runtime route table: $table_path" >&2
    consumer_runtime_route_table_example >&2
    return 1
  }

  awk -F '\t' -v runtime_name="$runtime_name" '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    NF < 2 { next }
    {
      name = $1
      root = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", root)
      if (name != runtime_name) {
        next
      }
      count += 1
      last_root = root
    }
    END {
      if (count == 1) {
        print last_root
        exit 0
      }
      if (count > 1) {
        print "duplicate consumer runtime entry: " runtime_name > "/dev/stderr"
        exit 2
      }
      print "unknown consumer runtime: " runtime_name > "/dev/stderr"
      exit 1
    }
  ' "$table_path"
}

list_consumer_runtime_routes() {
  requested_table_path="${1:-}"
  table_path=$(resolve_consumer_runtime_route_table_path "$requested_table_path" || true)

  [ -n "$table_path" ] || {
    echo "unable to determine consumer runtime route table path; set HARNESS_CONSUMER_RUNTIME_ROUTE_TABLE or pass --consumer-runtime-table" >&2
    return 1
  }

  [ -f "$table_path" ] || {
    echo "missing consumer runtime route table: $table_path" >&2
    consumer_runtime_route_table_example >&2
    return 1
  }

  awk -F '\t' '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    NF < 2 { next }
    {
      name = $1
      root = $2
      notes = $3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", root)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", notes)
      if (notes == "") {
        notes = "none"
      }
      printf "%s\t%s\t%s\n", name, root, notes
    }
  ' "$table_path"
}
