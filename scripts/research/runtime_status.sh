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
echo "- playwright_module: $(have_python_module playwright && printf '%s' yes || printf '%s' no)"
echo "- playwright_command: $(have_cmd playwright && printf '%s' yes || printf '%s' no)"
echo "- browser_storage_state: $(env_var_state HARNESS_RESEARCH_BROWSER_STORAGE_STATE)"
echo "- browser_user_data_dir: $(env_var_state HARNESS_RESEARCH_BROWSER_USER_DATA_DIR)"
echo "- browser_channel: $(env_var_state HARNESS_RESEARCH_BROWSER_CHANNEL)"
echo "- browser_local_browser: $(env_var_state HARNESS_RESEARCH_BROWSER_LOCAL_BROWSER)"
echo "- browser_profile_directory: $(env_var_state HARNESS_RESEARCH_BROWSER_PROFILE_DIRECTORY)"
echo "- http_cache_dir: $(env_var_state HARNESS_RESEARCH_HTTP_CACHE_DIR)"
echo "- disable_http_cache: $(env_var_state HARNESS_RESEARCH_DISABLE_HTTP_CACHE)"
echo "- http_retries: $(env_var_state HARNESS_RESEARCH_HTTP_RETRIES)"
echo "- http_max_retry_after: $(env_var_state HARNESS_RESEARCH_HTTP_MAX_RETRY_AFTER)"

echo
echo "## Suggested routes"

if [ "$(env_var_state TAVILY_API_KEY)" = "set" ]; then
  echo "- search: tavily"
else
  echo "- search: unavailable until TAVILY_API_KEY is set"
fi

echo "- extract-url: stdlib fetcher with conditional requests, retry/backoff, and local cache validators"
echo "- crawl: stdlib same-host crawl on top of the same polite HTTP layer"

if have_python_module playwright; then
  echo "- browser: headless Playwright renderer for JS-dependent pages"
  echo "  auth reuse: HARNESS_RESEARCH_BROWSER_STORAGE_STATE or HARNESS_RESEARCH_BROWSER_USER_DATA_DIR"
  echo "  local browser copy: HARNESS_RESEARCH_BROWSER_LOCAL_BROWSER + HARNESS_RESEARCH_BROWSER_PROFILE_DIRECTORY"
else
  echo "- browser: unavailable until Python Playwright is installed"
fi

if have_cmd markitdown || have_python_module markitdown; then
  echo "- ingest-local: markitdown available for rich document formats"
else
  echo "- ingest-local: stdlib text/html/json ingest only; install markitdown for pdf/docx/pptx/xlsx"
fi
