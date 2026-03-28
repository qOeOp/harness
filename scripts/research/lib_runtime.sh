#!/bin/sh
set -eu

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

have_python3() {
  have_cmd python3
}

have_python_module() {
  module_name="$1"

  have_python3 || return 1

  PYTHONDONTWRITEBYTECODE=1 python3 -B - "$module_name" <<'PY'
import importlib.util
import sys

module_name = sys.argv[1]
sys.exit(0 if importlib.util.find_spec(module_name) else 1)
PY
}

env_var_state() {
  var_name="$1"

  eval "var_value=\${$var_name:-}"

  if [ -n "$var_value" ]; then
    printf '%s\n' "set"
  else
    printf '%s\n' "missing"
  fi
}

provider_state() {
  label="$1"
  shift

  if "$@"; then
    printf '%s: available\n' "$label"
  else
    printf '%s: unavailable\n' "$label"
  fi
}
