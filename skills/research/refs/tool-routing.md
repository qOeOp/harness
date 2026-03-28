# Tool Routing

Route by information shape, not by habit.

## Preferred order

1. `search`
   - use for discovery, candidate generation, and official-source finding
2. `extract-url`
   - use when the URL is already known and the goal is clean page content
3. `crawl`
   - use when the topic spans many pages under one site or docs tree
4. `browser`
   - use only when interaction, login, pagination, or JS rendering blocks simpler routes
5. `ingest-local`
   - use for PDFs, Office docs, markdown, code, and repo-local evidence

## Routing rules

1. Default to the cheapest reliable path first.
2. Escalate to browser only after a simpler method fails or misses required content.
3. Use scripts for normalization, deduplication, and export when the same cleanup is likely to recur.
4. If a site is broad but repetitive, prefer crawl plus ranking over manual browsing.
