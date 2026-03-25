# Harness Framework And Dogfood Layering Spec v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready
- Depends on:
  - [Hosted Kernel Harness v1.31](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-31.md)
  - [Self-Governing Agent Company Harness v2.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md)

## Divergent Hypotheses

1. 继续把 `trading-agent` 同时当 framework source repo 和 dogfood repo 使用。
2. 立即在当前仓里塞一个本地 `harness-framework/` 目录，当作半成品子仓。
3. 正式锁定分层：
   - `harness-framework = distribution product repo`
   - `trading-agent = dogfood / canary consumer repo`
   - 当前仓先完成 truth layering 与迁移清单，不在本仓伪造最终拆仓形态

## First Principles Deconstruction

1. framework repo 与 dogfood repo 解决的是两类不同问题：
   - framework repo 负责 `distribution source of truth`
   - dogfood repo 负责 `真实消费、真实 telemetry、真实失败、真实学习`
2. 这和 consumer runtime 的 `Hosted Kernel` 架构不是同一个维度：
   - 仓级分层回答：`谁发布 skill/package，谁承载 dogfood truth`
   - 运行时分层回答：`skill/package 在外，.harness 在 repo 内`
3. 如果同一层同时承载 framework source truth 与 dogfood truth，所有 contract 最终都会泄漏：
   - 哪些文件是产品源码
   - 哪些文件是 consumer runtime state
   - 哪些 learning 属于 release discipline
4. 当前仓已经产生了大量：
   - decisions
   - briefs
   - status snapshots
   - state items
   - dogfood evolutionary runs

这些东西说明：

`trading-agent` 的真实身份已经更像 dogfood consumer，而不是 framework source repo。`

5. 真正应该先分开的，不是 git remote，而是：
   - truth ownership
   - file classes
   - migration boundaries

## Convergence To Excellence

采纳第 `3` 条路线。

## Canonical Layering

### Layer 1: `harness-framework`

定位：

`distribution product repo`

职责：

1. Hosted Kernel / distribution contracts
2. installer / update / doctor / repair carriers
3. portable schemas
4. provider-native carrier definitions
5. profiles
6. fixture repos 与 acceptance suite contracts
7. 发布：
   - global skill/package
   - skill 内 bootstrap/update/doctor logic

禁止承载：

1. trading-specific current truth
2. dogfood runtime state
3. founder-only product decisions of a consumer repo
4. consumer-side live work items and progress

### Layer 2: `trading-agent`

定位：

`dogfood / canary consumer repo`

职责：

1. 真实消费 `harness-framework`
2. 真实承载 repo-local `.harness` workspace
3. 真实执行 dogfood / canary rollout
4. 暴露 framework 在真实对象上的问题
5. 积累：
   - decision
   - brief
   - status
   - telemetry
   - run artifacts

禁止承载：

1. `harness-framework` 的最终 source of truth
2. framework-only release packaging
3. 把 consumer telemetry 误冒充 framework product truth

### Layer 3: `shared portability boundary`

这是逻辑边界，不是第三个仓。

作用：

定义哪些东西未来可以从 `trading-agent` 提取到 `harness-framework`。

## Current Repo Identity

自本版本起，当前仓库正式定位为：

`trading-agent = dogfood / canary consumer repo`

它的主要职责不再是“直接长成 framework”，而是：

1. 吃 framework contract
2. 暴露真实使用问题
3. 为 future `harness-framework` 提供 dogfood learning

## Hosted Kernel Runtime Reminder

为避免误读，当前最终锁定的 consumer runtime 架构仍然是：

1. global `harness` skill/package
2. installer/bootstrap logic in that skill/package
3. repo-local `.harness/`
4. root overlay -> `.harness` first hop

所以这份 layering spec 不是在改成 vendored framework，也不是要在 `trading-agent` 里长一个本地 framework repo。
它只是在回答：

`谁是 distribution source repo，谁是 dogfood consumer repo。`

## File-Class Partition

### A. Framework-Owned Candidates

这些内容的长期归属应当是 `harness-framework`：

1. Hosted Kernel consumer-repo contracts
2. Evolutionary Hardening mode contracts
3. round / scorecard / lineage / manifest / telemetry schemas
4. portable install / doctor / update contract docs
5. provider-native carrier specs

在当前仓中的代表：

1. [2026-03-25-hosted-kernel-harness-spec-v1-31.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-31.md)
2. [2026-03-25-self-governing-agent-company-harness-spec-v2-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md)
3. [2026-03-25-evolutionary-hardening-mode-spec-v3-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-50.md)
4. [2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md)
5. [2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md)
6. [2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md)

### B. Dogfood-Owned Runtime Truth

这些内容明确留在 `trading-agent`：

1. [product-vision.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/product-vision.md)
2. [repo-trust-mode.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/repo-trust-mode.md)
3. future repo-local `.harness/` workspace and runtime state
4. `.harness/workspace/state/`
5. `.harness/workspace/decisions/log/`
6. `.harness/workspace/status/snapshots/`
7. product-specific briefs and research
8. dogfood evolutionary runs against real repo objects

### C. Framework-Dogfood Bridge Artifacts

这些内容属于 dogfood learning，但其结构会反哺 framework：

1. [product-vision-refresh-2026-03-25 run](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/runs/product-vision-refresh-2026-03-25/README.md)
2. dogfood scorecard summaries
3. dogfood telemetry
4. release learning notes

规则：

1. bridge artifacts 默认留在 dogfood repo
2. 只有其 schema / carrier 形式被提炼后，才进入 framework repo

## Anti-Confusion Rules

1. 不允许在 `trading-agent` 中再创建一个伪正式的 `harness-framework/` source-of-truth 目录。
2. 不允许把 dogfood runtime state 误标为 framework product assets。
3. 不允许把 framework spec 的最终真相与当前 consumer repo truth 混在同一个 current 文件里。
4. 不允许把 `framework-owned candidate` 的演进，与 `dogfood runtime truth` 的更新当成同一类变更。
5. 不允许把“仓级分层”误读成“否定 Hosted Kernel”。

## Immediate Layering Moves

这一步不做真正拆仓，但立刻锁定 4 条动作：

1. 当前仓新增一个 stable current truth，声明：
   - 本仓是 `dogfood / canary consumer`
   - 不是 framework source repo
2. 当前仓新增一份 migration table，明确哪些现有 artifact 未来属于 `harness-framework`
3. 后续所有关于 framework 形态的演化，默认归类到 `framework-owned candidates`
4. 后续所有真实对象 dogfood run，默认归类到 `dogfood-owned runtime truth` 或 `bridge artifacts`

## Migration Table

### Wave 1: Freeze Boundaries

先做：

1. current truth 声明
2. layering decision
3. migration inventory

不做：

1. git remote 拆分
2. 子仓嵌套
3. 自动搬文件

### Wave 2: Extract Framework Candidates

未来迁走：

1. `.agents/skills/harness/references/archive/harness/` 中的 framework-owned specs
2. portable schemas
3. distribution/update/install contracts

### Wave 3: Keep Dogfood Runtime Local

始终留在 `trading-agent`：

1. current truths
2. work items
3. decisions
4. snapshots
5. product-specific research
6. dogfood runs against real repo objects

## Acceptance Bar

这一轮 layering 算完成，至少满足：

1. 当前仓的 repo identity 已明确
2. framework-owned / dogfood-owned / bridge 三类文件已分层
3. 后续不会再把“拆仓”误解成“在当前仓里继续长一个假 framework 子树”

## Residual Risk

1. 真正的 `harness-framework` 新仓还未创建
2. framework-owned candidates 仍暂时物理留在当前仓
3. 迁移 inventory 还未 machine-readable
