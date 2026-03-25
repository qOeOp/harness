# Harness Framework Migration Inventory v2

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Supersedes:
  - [Harness Framework Migration Inventory v1](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-harness-framework-migration-inventory-v1.md)
- Machine-readable contract:
  - [migration-inventory.toml](/Users/vx/WebstormProjects/trading-agent/.harness/migration-inventory.toml)

## Final Buckets

### A. Move Into `.agents/skills/harness/`

目标：

`remote-linked clean framework skill subrepo`

包含：

1. hosted-kernel contracts
2. evolutionary-hardening mode contracts
3. manifest / scorecard / lineage / telemetry schemas
4. install / update / doctor / repair carriers
5. provider carriers

当前代表文件：

1. [2026-03-25-hosted-kernel-harness-spec-v1-31.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-31.md)
2. [2026-03-25-self-governing-agent-company-harness-spec-v2-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md)
3. [2026-03-25-evolutionary-hardening-mode-spec-v3-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-50.md)
4. [2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md)
5. [2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md)
6. [2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md)

### B. Keep In Repo-Local `.harness/`

目标：

`all instance/runtime workspace files`

包含：

1. project context
2. product vision and repo-local truths
3. decisions
4. briefs
5. state
6. logs
7. runs
8. snapshots
9. runtime metadata

当前代表文件或目录：

1. [product-vision.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/product-vision.md)
2. [repo-trust-mode.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/repo-trust-mode.md)
3. `.harness/workspace/state/*`
4. `.harness/workspace/decisions/log/*`
5. `.harness/workspace/status/snapshots/*`
6. `.harness/workspace/briefs/*`
7. `.harness/workspace/runs/*`

### C. Root Overlay Only

目标：

`thin redirect surface`

包含：

1. `AGENTS.md`
2. `CLAUDE.md`
3. `GEMINI.md`

规则：

1. 只做 redirect / overlay
2. 不承载 framework source
3. 不承载 instance-generated content

## Migration Rule

如果抽离后一个文件会让 reviewer 以为：

1. “这是 clean harness source”  
那它应进入 `.agents/skills/harness/`

2. “这是这个 repo 运行时产生的东西”  
那它应进入 `.harness/`

## Residual Risk

1. 当前仓还未实际建立 `.agents/skills/harness/` 远程子仓连接
2. 当前 `.harness/` 还未真实创建并承接现有 runtime artifact
3. machine-readable inventory 已存在，但还未接入执行脚本
