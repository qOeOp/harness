#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_runtime.sh"

echo "# Research Runtime Status"
echo
echo "- python3: $(have_python3 && printf '%s' yes || printf '%s' no)"
echo "- node: $(have_cmd node && printf '%s' yes || printf '%s' no)"
echo "- tavily_api_key: $(env_var_state TAVILY_API_KEY)"
echo "- markitdown_command: $(have_cmd markitdown && printf '%s' yes || printf '%s' no)"
echo "- markitdown_module: $(have_python_module markitdown && printf '%s' yes || printf '%s' no)"
echo "- crawl4ai_module: $(have_python_module crawl4ai && printf '%s' yes || printf '%s' no)"
echo "- browser_use_module: $(have_python_module browser_use && printf '%s' yes || printf '%s' no)"
echo "- playwright_command: $(have_cmd playwright && printf '%s' yes || printf '%s' no)"

echo
echo "## Suggested routes"

if [ "$(env_var_state TAVILY_API_KEY)" = "set" ]; then
  echo "- search: tavily"
else
  echo "- search: unavailable until TAVILY_API_KEY is set"
fi

echo "- extract-url: stdlib fetcher"
echo "- crawl: stdlib same-host crawl"

if have_cmd markitdown || have_python_module markitdown; then
  echo "- ingest-local: markitdown available for rich document formats"
else
  echo "- ingest-local: stdlib text/html/json ingest only; install markitdown for pdf/docx/pptx/xlsx"
fi
