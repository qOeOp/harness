# Top-Level Surface

Only three allowed dispositions exist for canonical functional top-level surfaces:

1. `move-to-skill-source`
2. `move-to-runtime`
3. `delete`

Never use:

1. `legacy`
2. `archive`
3. `compat`
4. `temporary canonical`

Provider adapters are the explicit exception. They may remain top-level as thin, tool-specific shims:

1. `.claude/`
2. `.codex/`
3. `.gemini/`

Current intended destinations:

## Move to skill source

No remaining top-level functional candidates.

Already absorbed into skill source:

1. existing parallel skills under `.agents/skills/` -> `skills/`
2. `docs/` -> `docs/`
3. `codex/` -> `references/provider-adapters/codex/`
4. `.agents/roles/` -> `roles/`
5. `scripts/` -> `scripts/`

## Keep as top-level provider adapters

1. `.claude/`
2. `.codex/`
3. `.gemini/`

## Move to runtime

No remaining top-level runtime candidates.

Already absorbed into runtime:

1. `workspace/` -> `.harness/workspace/`
2. `departments/` -> `.harness/workspace/departments/`

## Delete

Any functional surface that belongs to neither of the above.
