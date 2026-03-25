# Harness Framework And Dogfood Layering Spec v2

- Status: latest
- Canonical snapshot:
  - [2026-03-25-harness-framework-and-dogfood-layering-spec-v2.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-harness-framework-and-dogfood-layering-spec-v2.md)

## Read This

当前最终目标已压成最简两层：

1. `.agents/skills/harness/`
   - 连接远程 `harness-framework` 的 clean framework skill subrepo
2. `.harness/`
   - 当前仓所有 repo-local runtime and instance workspace

root `AGENTS.md / CLAUDE.md / GEMINI.md` 仅保留 overlay / redirect 责任。
