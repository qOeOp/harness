# Evolutionary Hardening Run Manifest Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Supersedes:
  - [2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md) 中关于 `manifest-first` 的概念性要求

## Divergent Hypotheses

1. run README 继续自由书写，只要大意清楚即可。
2. 每个 run 只保留 checkpoint，不需要单独 manifest。
3. 每个 run 必须有一个极薄、极稳定、极明确的 manifest，作为 operator 和 reviewer 的首跳入口。

## First Principles Deconstruction

1. reviewer 不应该进入 `rounds/` 才知道当前 run 到底进展到哪。
2. operator 不应该在 README、checkpoint、candidate、decision 之间猜哪个是当前入口。
3. 如果没有单一 manifest，checkpoint 再好也只是“另一个总结文件”。
4. manifest 的职责不是承载 rich lineage，而是承载：
   - 当前真相
   - 当前入口
   - 当前风险
   - 当前下一步

## Convergence To Excellence

采纳第 `3` 条路线。

`Run Manifest` 被定义为：

`当前 run 的唯一默认入口文件`

## Canonical Objective

Run Manifest 要做到两件事：

1. 让 reviewer 在不看 raw telemetry 的前提下理解 run 当前状态
2. 让 operator 在不猜路径的前提下进入正确对象

## Placement Rule

正式执行面默认位置：

1. `.harness/evolution/runs/<run-id>/README.md`

过渡期 dogfood 允许：

1. `.harness/workspace/runs/<run-id>/README.md`

## Manifest Must Answer

每个 run manifest 至少必须回答：

1. 这次 run 是什么
2. 为什么跑它
3. 当前 seed 是什么
4. 当前 canonical survivor / candidate 是什么
5. 当前 checkpoint 是什么
6. 当前 scorecard summary 是什么
7. 当前 primary success condition 是什么
8. 当前 residual risks 是什么
9. raw telemetry 在哪
10. 当前推荐下一步是什么

## Required Header Fields

manifest 头部至少包含：

1. `Run id`
2. `Date`
3. `Mode`
4. `Mode survivor`
5. `Evolved target`
6. `Current seed`
7. `Current checkpoint`
8. `Current scorecard summary`
9. `Current survivor or candidate`

## Required Sections

至少包含以下章节：

1. `Purpose`
2. `Primary Success Condition`
3. `Secondary Outputs`
4. `Reviewer Default Path`
5. `Current Residual Risks`
6. `Raw Telemetry Links`
7. `Next Move`

## Reviewer Default Path Contract

manifest 必须显式写出 reviewer 默认路径：

1. current checkpoint
2. current scorecard summary
3. current survivor / candidate
4. 仅在需要时进入 raw rounds

这条路径不允许隐含。

## Raw Telemetry Links Contract

manifest 不承载全部 lineage 正文。

manifest 只列链接：

1. seed
2. rounds/
3. checkpoints/
4. telemetry/
5. claims/
6. notes/

如果某层不存在，可以省略；但不能用 prose 替代目录边界。

## Residual Risk Contract

manifest 中的 residual risk 必须是 checkpoint 级压缩，不允许复制所有 round 的原始噪音。

要求：

1. 最多 `3-7` 条
2. 以当前 run 的 actionability 为中心
3. 指向谁来解决、何时解决

## Anti-Bloat Rule

manifest 明确禁止：

1. 复写 raw round 细节
2. 在 manifest 中继续做长篇 operator reflection
3. 把 scorecard 明细整份复制进 manifest
4. 用 manifest 取代 checkpoint

manifest 越像 index 和 dispatch layer，越对。

## Acceptance Bar

一个 run manifest 算合格，至少满足：

1. reviewer 用 manifest 就知道当前该先看哪三个文件
2. operator 用 manifest 就知道当前 seed / checkpoint / candidate 是什么
3. raw rounds 不再是默认首跳

## Residual Risk

1. `scorecard summary` 还需单独 schema 支撑
2. 正式执行面的 `.harness/evolution/runs/` 尚未落地

