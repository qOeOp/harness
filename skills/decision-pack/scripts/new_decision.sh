#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
bundle_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_root=$(CDPATH= cd -- "$bundle_dir/../.." && pwd)

exec "$repo_root/scripts/new_decision.sh" "$@"
