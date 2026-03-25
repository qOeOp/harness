# Evolutionary Hardening Entropy Compression Spec v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready compression pass
- Applies to:
  - [Evolutionary Hardening Mode v3.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-50.md)
  - [product-vision-refresh-2026-03-25 run](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/runs/product-vision-refresh-2026-03-25/README.md)

## Audit Snapshot

截至本次审计，当前 harness 相关 markdown 暴露面已经明显偏厚：

1. [.harness/workspace/archive/briefs/harness](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/archive/briefs/harness) 下共有 `162` 个 markdown
2. 根层主要系列分布：
   - `hosted-kernel`: `32`
   - `self-governing-v2`: `50`
   - `evolution-v3-rounds`: `50`
   - `mode-meta`: `6`
   - `other-root-harness`: `16`
3. 当前真实 run：
   - [product-vision-refresh-2026-03-25](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/runs/product-vision-refresh-2026-03-25/README.md)
   - 共 `8` 个 markdown，其中 round artifacts `5` 个

结论不是“系统没有结构”，而是：

`系统内部正确的复杂性，已经被过度暴露成外部审阅复杂性。`

## Divergent Hypotheses

1. 保持当前高显式度，要求 reviewer 自己适应多层 lineage。
2. 把大量 raw rounds 直接藏起来，只保留最终 survivor，最大化表面简洁。
3. 维持完整 lineage，但重新定义 visibility hierarchy、carrier 粒度和 checkpoint compaction，让：
   - canonical truth 极薄
   - operator 入口单一
   - raw telemetry 默认降级

## First Principles Deconstruction

1. 进化系统必须保留：
   - survivor
   - score
   - lineage
   - checkpoint
   - residual risk
2. reviewer 不应该被迫阅读：
   - 全部 round prose
   - 并列 series
   - 多个看似同级的入口
3. 真正的 compaction，不是“再加一个 summary”，而是：
   - 改变默认可见层
   - 降级 raw telemetry carrier
   - 缩短从根入口到当前真相的路径
4. 如果机制只会 tightening / splitting / gating，而没有在既定 rubric 下的探索预算，它更像局部 hill-climbing，不是完整进化。

## Convergence To Excellence

采纳第 `3` 条路线，并追加一个硬修正：

`Entropy Compression + Controlled Exploration`

也就是：

1. reviewer 默认层更薄
2. operator 默认层单一
3. raw rounds 降级
4. checkpoint 真正承担压缩职责
5. exploration 成为既定评估框架下的受控能力，而不是游离在系统外

## Canonical Compression Objective

把当前机制从：

`强理念、厚落盘、弱审阅体验`

压成：

`强理念、强lineage、薄审阅面`

## New Visibility Hierarchy

### Level 0: Reviewer / Founder Default Surface

默认只允许 reviewer 先看这 4 类对象：

1. current canonical survivor
2. current checkpoint
3. current scorecard summary
4. current founder-facing artifact

不允许默认从 `rounds/` 开始。

### Level 1: Operator Surface

operator 默认入口应当是 `run manifest`，而不是 raw rounds。

run manifest 至少回答：

1. 当前 seed 是什么
2. 当前 survivor 是什么
3. 当前 checkpoint 是什么
4. 当前 residual risks 是什么
5. 当前 accepted delta compression 是什么
6. raw telemetry 在哪

### Level 2: Raw Telemetry Surface

以下内容属于 raw telemetry，默认降级：

1. round-by-round prose
2. rejected delta 明细
3. operator reflection 原始记录
4. lane-specific scratch material

raw telemetry 必须存在，但不再占据一级可见层。

## Run Manifest Contract

每个真实 run 必须有且只有一个 manifest 入口。

建议位置：

1. `.harness/evolution/runs/<run-id>/README.md`
2. 在当前 workspace dogfood 期，仍允许使用：
   - `.harness/workspace/runs/<run-id>/README.md`

manifest 结构至少包含：

1. mode survivor
2. target
3. seed
4. current checkpoint
5. current candidate / survivor
6. primary success condition
7. secondary outputs
8. current residual risks
9. raw telemetry links

## Round Artifact Demotion Rule

从 `v1` 开始，raw rounds 不再被视为 reviewer-facing prose documents。

未来方向：

1. `rounds/<round-id>.md` 只保留最小结构化 delta
2. 更长的 lane material 移入：
   - `telemetry/`
   - `notes/`
   - `claims/`
3. 若无特殊需要，round artifact 的默认格式应逐步演进为更结构化的 carrier
   - TOML
   - YAML
   - JSON
   - 或极短 markdown schema

## Checkpoint Compression Rule

checkpoint 不再只是“又一份总结文件”。

从现在开始，checkpoint 必须承担 3 个职责：

1. 压缩最近若干轮 accepted deltas
2. 重新声明当前 invariants、residual risks、survivor state
3. 将 raw rounds 从默认视野中移出

也就是说：

1. reviewer 看 checkpoint 即可
2. raw rounds 只在需要回放时才看

## Exploration Budget Contract

当前机制的一个真实缺口是：

`缺少在既定评估框架下的开放式探索。`

修正规则如下：

每轮 candidate population 默认包含两种预算：

1. `exploit candidate`
   - tighten / split / gate / simplify
2. `exploration candidate`
   - 在 invariants 与 rubric 不变的前提下，尝试新的 representation、framing、object model 或 evaluation surface

禁止：

1. 无约束自由发散
2. 借 exploration 绕开 invariants
3. 用 exploration 候选跳过 scorecard

## Canonical Entry Compression

对 evolution 系统，reviewer 的默认路径应压成：

1. current mode survivor
2. run manifest
3. current checkpoint
4. founder-facing artifact
5. 仅在需要时回放 raw rounds

这意味着：

1. `brief redirect`
2. `decision log`
3. `status snapshot`
4. `run manifest`

必须比 raw round 更靠前、更明确。

## What Must Stay Rich

不要把压缩误解成删除价值。

必须保留 richness 的部分：

1. lineage
2. residual risk
3. rejected delta memory
4. operator reflection
5. research provenance

真正要压的是：

1. 默认可见层
2. prose carrier 重量
3. reviewer 首跳路径

## Acceptance Bar For Compression Pass

这一轮 compression pass 算成功，至少满足：

1. reviewer 不需要扫描 raw rounds 就能理解当前结论
2. operator 不需要在多个同级入口中猜当前真相
3. round raw telemetry 仍可回放，但不再占据一级可见层
4. exploration 预算进入正式合同

## Immediate Next Move

下一步不是继续加 round，而是做 3 个具体动作：

1. 给 `v3` 和未来 run 增加正式 `scorecard summary` carrier
2. 把真实 run 的 raw rounds 从 prose-heavy 形式降级成更结构化的 carrier
3. 在 `.harness/evolution/runs/` 正式执行面里实现：
   - manifest-first
   - checkpoint-first
   - telemetry-demoted

## Residual Risk

1. 当前这轮 compression pass 还是 spec，没有真正改写 `.harness/evolution/runs/` 执行面
2. 旧的 `v1/v2/v3` archive 体量依然很大
3. `scorecard summary` 还未从概念变成正式 artifact
