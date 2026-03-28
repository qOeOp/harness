#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -L)
exec "$script_dir/run_surface_diagnostic.sh" "$@"
