# Top-Level Surface

For the framework source repo, the top level is already the canonical source surface.
For a consumer repo, only three allowed dispositions exist for functional top-level surfaces:

1. `move-to-skill-source`
2. `move-to-runtime`
3. `delete`

Never use:

1. `legacy`
2. `archive`
3. `compat`
4. `temporary canonical`

Provider adapters remain an explicit exception in consumer repos. They may remain top-level as thin, tool-specific shims:

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

## Move to skill source

Install or project the framework source into `.agents/skills/harness/`.

## Keep as top-level provider adapters

1. `.claude/`
2. `.codex/`
3. `.gemini/`

## Move to runtime

Runtime belongs under `.harness/`.

## Delete

Any functional surface in a consumer repo that belongs to neither installed skill source nor runtime.
