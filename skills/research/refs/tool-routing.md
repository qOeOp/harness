# Tool Routing

Route by information shape, not by habit.

## Preferred order

1. `search`
   - use for discovery, candidate generation, and official-source finding
   - prefer open or self-hostable backends when they preserve enough freshness and result quality
2. `extract-url`
   - use when the URL is already known and the goal is clean page content
   - prefer simpler public surfaces such as RSS, Atom, oEmbed, JSON, or print views when the host provides them
3. `crawl`
   - use when the topic spans many pages under one site or docs tree
4. `browser`
   - use only when interaction, login, pagination, or JS rendering blocks simpler routes
   - keep browser runs headless by default so the desktop is not part of the operator experience
   - prefer imported auth state or a dedicated copied profile over a live personal browser profile
   - if local browser state is needed, snapshot the chosen local profile into a temporary copy before the run
5. `crawl4ai`
   - use when browser rendering is required, but the page also needs richer extraction, hooks, browser-native crawl controls, or managed browser features
   - keep it optional; it is a heavier dependency than the default Playwright route
6. `ingest-local`
   - use for PDFs, Office docs, markdown, code, and repo-local evidence

## Routing rules

1. Default to the cheapest reliable path first.
2. Prefer public structured surfaces over rendered pages when both can answer the question.
3. Escalate to browser only after a simpler method fails or misses required content.
4. Reuse conditional requests, local cache validators, and polite retry/backoff before increasing route complexity.
5. Use scripts for normalization, deduplication, and export when the same cleanup is likely to recur.
6. Reach for Crawl4AI only when its richer browser/crawl features materially improve the run over the lighter Playwright browser route.
7. If a site is broad but repetitive, prefer crawl plus ranking over manual browsing.
