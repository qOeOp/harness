#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec node "$script_dir/render_founder_review_page.js" "$@"
