# Research Runtime Contract

The research runtime exposes one primary control surface:

- `scripts/research_ctl.sh`

## Commands

1. `status`
   - show which optional providers are currently available
2. `search`
   - default to auto-dispatch across available search backends
   - prefer Tavily when `TAVILY_API_KEY` is present, otherwise use a configured SearXNG instance when `HARNESS_RESEARCH_SEARXNG_URL` is present
3. `extract-url`
   - fetch one URL and convert it into markdown-ish text
   - reuse conditional requests and a small local cache when validators such as `ETag` or `Last-Modified` are available
4. `crawl`
   - same-host shallow crawl with bounded depth and page count
   - inherits the same polite HTTP fetch behavior as `extract-url`
5. `browser`
   - render one page with headless Playwright when simpler fetch routes miss JS-dependent content
   - may reuse auth via storage state or a configured browser profile directory
   - may snapshot a local Chrome / Edge / Chromium profile into a temporary headless copy
6. `crawl4ai`
   - optional heavy-duty headless crawler for dynamic pages, richer extraction, and browser-native crawling features
   - may reuse a configured browser profile directory or a temporary local Chrome / Edge / Chromium profile copy
7. `ingest-local`
   - ingest repo-local or local filesystem documents

## Design Rules

1. Core commands should work with Python standard library only.
2. Optional providers should improve results, not become hard prerequisites.
3. Command output must be stable enough to become a `source-note` or an optional `evidence ledger` input.
4. TLS verification stays enabled by default. Use `--insecure` only as an explicit operator override when the local Python trust store is broken or intercepted.
5. Browser automation in research mode should stay headless by default; user-visible windows are not part of the normal collection path.
6. For authenticated browser runs, prefer storage state or a dedicated copied profile; reusing a live personal profile directly can be brittle.
7. When borrowing local browser state, copy only the selected browser profile into a temporary working directory and discard it after the run.
8. Prefer polite HTTP behavior by default: conditional requests, bounded retry/backoff, and local validator reuse should come before more aggressive collection tactics.
