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
  browser-profiles [--format markdown|json]
  search <query> [--backend auto|tavily|searxng] [--max-results N] [--topic general|news|finance] [--search-depth basic|advanced]
  extract-url <url> [--format markdown|json] [--max-chars N] [--insecure]
  crawl <seed-url> [--max-pages N] [--max-depth N] [--format markdown|json] [--insecure]
  browser <url> [--format markdown|json] [--max-chars N] [--wait-until load|domcontentloaded|networkidle] [--storage-state path | --user-data-dir dir | --local-browser chrome|edge|chromium]
  crawl4ai <url> [--format markdown|json] [--max-chars N] [--wait-for cond] [--user-data-dir dir | --local-browser chrome|edge|chromium]
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
  browser-profiles)
    exec python3 -B "$runtime_dir/local_browser_profiles.py" "$@"
    ;;
  search)
    exec python3 -B "$runtime_dir/search_auto.py" "$@"
    ;;
  extract-url)
    exec python3 -B "$runtime_dir/extract_url.py" "$@"
    ;;
  crawl)
    exec python3 -B "$runtime_dir/crawl_site.py" "$@"
    ;;
  browser)
    exec python3 -B "$runtime_dir/browser_extract.py" "$@"
    ;;
  crawl4ai)
    exec python3 -B "$runtime_dir/crawl4ai_extract.py" "$@"
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
