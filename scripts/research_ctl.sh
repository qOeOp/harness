#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
runtime_dir="$script_dir/research"
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE

usage() {
  cat <<EOF >&2
usage: $0 <command> [args]

commands:
  status
  search <query> [--max-results N] [--topic general|news|finance] [--search-depth basic|advanced]
  extract-url <url> [--format markdown|json] [--max-chars N] [--insecure]
  crawl <seed-url> [--max-pages N] [--max-depth N] [--format markdown|json] [--insecure]
  ingest-local <path> [--format markdown|json] [--max-chars N]
EOF
  exit 1
}

[ "$#" -ge 1 ] || usage

command_name="$1"
shift

case "$command_name" in
  status)
    exec "$runtime_dir/runtime_status.sh" "$@"
    ;;
  search)
    exec python3 -B "$runtime_dir/search_tavily.py" "$@"
    ;;
  extract-url)
    exec python3 -B "$runtime_dir/extract_url.py" "$@"
    ;;
  crawl)
    exec python3 -B "$runtime_dir/crawl_site.py" "$@"
    ;;
  ingest-local)
    exec python3 -B "$runtime_dir/ingest_local.py" "$@"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    echo "unknown research command: $command_name" >&2
    usage
    ;;
esac
