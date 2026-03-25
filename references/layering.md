# Layering

Canonical layering target:

1. `.agents/skills/harness/`
   - clean framework skill source
   - remote counterpart: `harness-framework`
2. `.harness/`
   - repo-local runtime workspace
   - project context, decisions, briefs, state, logs, runs, status, metadata
3. root entry files
   - redirect / overlay only

Current repo identity:

`trading-agent = dogfood / canary consumer repo`

Hosted-kernel reminder:

1. framework source lives in the harness skill carrier
2. consumer runtime lives in `.harness/`
3. the repo should not grow a third functional surface
