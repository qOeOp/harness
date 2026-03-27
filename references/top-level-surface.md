# Top-Level Surface

For the framework source repo, the top level is already the canonical source surface.
For a consumer repo, only two allowed dispositions exist for harness-owned functional top-level surfaces:

1. `move-to-runtime`
2. `delete`

Never use:

1. `legacy`
2. `archive`
3. `temporary canonical`

Provider adapters remain an explicit user-owned exception in consumer repos. They may exist as thin, tool-specific shims, but harness does not generate, mutate, or validate them:

1. `.claude/`
2. `.codex/`
3. `.gemini/`

Framework source repo shape:

1. `SKILL.md`
2. `skills/`
3. `roles/`
4. `scripts/`
5. `docs/`
6. `references/`
7. provider adapter examples or generators only if they are part of distribution logic

Consumer repo intended destinations:

## User-owned optional provider adapters

1. `.claude/`
2. `.codex/`
3. `.gemini/`

## Move to runtime

Runtime belongs under `.harness/`.

## Delete

Any functional surface in a consumer repo that belongs to neither harness-owned runtime nor user-owned provider adapters.
