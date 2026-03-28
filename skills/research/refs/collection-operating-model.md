# Research Collection Operating Model

The `research` bundle includes both routing and collection, but not every run needs every layer.

## Default ladder

1. `dispatch`
   - only when freshness, ownership, or blocking status needs to be made explicit
2. `brief`
   - only when the collection plan is non-trivial
3. `collect`
   - search, extract, crawl, or local ingest
4. `source-note`
   - default durable evidence artifact
5. `memo`
   - only when a cross-source synthesis is needed

## Optional support layer

`evidence-ledger` is optional.

Use it only when:

1. the run is long
2. many sources need ranking or deduplication
3. handoff or pause/resume is likely

## Raw capture rule

Do not treat full raw capture as a default formal artifact.

Keep raw material only when it is:

1. difficult to reproduce
2. highly volatile
3. access-constrained
4. required for audit or dispute resolution
