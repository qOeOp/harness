#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

resolve_runtime_root() {
  current=$(pwd)
  while [ "$current" != "/" ]; do
    if [ -f "$current/.harness/manifest.toml" ]; then
      printf '%s\n' "$current"
      return 0
    fi
    current=$(dirname "$current")
  done
  return 1
}

usage() {
  cat <<'EOF' >&2
usage: ./scripts/research/run_crawl4ai_isolated.sh <url> [crawl4ai args...]

Runs the Crawl4AI route inside a consumer runtime-local isolated environment.
By default, support state is stored under:
  .harness/runtime/research/crawl4ai-home
  .harness/runtime/research/venvs/crawl4ai

Overrides:
  HARNESS_RESEARCH_CRAWL4AI_HOME
  HARNESS_RESEARCH_VENV_ROOT
  HARNESS_RESEARCH_LOCAL_BROWSER_HOME
EOF
  exit 1
}

[ "$#" -ge 1 ] || usage

runtime_root=$(resolve_runtime_root || true)

crawl4ai_home="${HARNESS_RESEARCH_CRAWL4AI_HOME:-}"
venv_root="${HARNESS_RESEARCH_VENV_ROOT:-}"

if [ -z "$crawl4ai_home" ] || [ -z "$venv_root" ]; then
  [ -n "$runtime_root" ] || {
    echo "run_crawl4ai_isolated.sh requires a materialized consumer runtime or explicit HARNESS_RESEARCH_CRAWL4AI_HOME/HARNESS_RESEARCH_VENV_ROOT overrides." >&2
    exit 1
  }
fi

if [ -z "$crawl4ai_home" ]; then
  crawl4ai_home="$runtime_root/.harness/runtime/research/crawl4ai-home"
fi

if [ -z "$venv_root" ]; then
  venv_root="$runtime_root/.harness/runtime/research/venvs/crawl4ai"
fi

mkdir -p "$crawl4ai_home" "$venv_root"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required for run_crawl4ai_isolated.sh" >&2
  exit 1
fi

venv_python="$venv_root/bin/python"
venv_crawl4ai_setup="$venv_root/bin/crawl4ai-setup"

if [ ! -x "$venv_python" ]; then
  uv venv "$venv_root"
fi

if ! HOME="$crawl4ai_home" "$venv_python" -c 'import crawl4ai' >/dev/null 2>&1; then
  HOME="$crawl4ai_home" uv pip install --python "$venv_python" crawl4ai
fi

if [ ! -x "$venv_crawl4ai_setup" ]; then
  echo "crawl4ai installation is incomplete in $venv_root" >&2
  exit 1
fi

if [ ! -d "$crawl4ai_home/.crawl4ai" ] || [ ! -d "$crawl4ai_home/Library/Caches/ms-playwright" ]; then
  HOME="$crawl4ai_home" "$venv_crawl4ai_setup"
fi

HOME="$crawl4ai_home" PATH="$venv_root/bin:$PATH" exec "$repo_root/scripts/research_ctl.sh" crawl4ai "$@"
