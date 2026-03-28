# Research Runtime Contract

The research runtime exposes one primary control surface:

- `scripts/research_ctl.sh`

## Commands

1. `status`
   - show which optional providers are currently available
2. `search`
   - use Tavily search when `TAVILY_API_KEY` is present
3. `extract-url`
   - fetch one URL and convert it into markdown-ish text
4. `crawl`
   - same-host shallow crawl with bounded depth and page count
5. `ingest-local`
   - ingest repo-local or local filesystem documents

## Design Rules

1. Core commands should work with Python standard library only.
2. Optional providers should improve results, not become hard prerequisites.
3. Command output must be stable enough to become a `source-note` or an optional `evidence ledger` input.
4. TLS verification stays enabled by default. Use `--insecure` only as an explicit operator override when the local Python trust store is broken or intercepted.
