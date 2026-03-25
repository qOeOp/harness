# True Evolutionary Hardening Seed v3.00

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: seed-frozen
- Parent seed:
  - [Self-Governing Agent Company Harness Spec v2.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md)
- Purpose:
  1. 把 `v2.50` 从 `Fast Hardening` 产物导入为 `True Evolutionary Hardening` 的 round-00 seed。
  2. 冻结第一轮必须继承的 invariants、rubric、lane topology 和 termination contract。

## Seed Truth

`v2.50` 当前仍是已落盘的 integrated snapshot。  
`v3.00` 不替换它，而是把它视为：

1. imported survivor seed
2. baseline for pairwise comparison
3. starting point for true serial evolution

## Frozen Invariants

第一阶段不得破坏：

1. deterministic first hop
2. Hosted Kernel 低侵入方向
3. append-only history preference
4. source / projection / compounding 三层状态分离
5. single canonical survivor
6. fail-closed doctor / repair / stop-the-line
7. ownership / handoff / review lane separation
8. timely compounding as a first-class objective

## Initial Fitness Rubric

第一阶段按以下维度打分：

1. correctness
2. determinism
3. safety
4. operator usability
5. compounding value
6. rolloutability
7. complexity discipline

## Fixed Lane Topology

默认 5 条 lane：

1. `research lane`
2. `structure lane`
3. `evaluation lane`
4. `lineage lane`
5. `safety lane`

## Round Contract

从 `v3.01` 开始，每轮必须至少产出：

1. `survivor_n`
2. `scorecard_n`
3. `residual_risks_n`
4. `accepted_deltas_n`
5. `rejected_deltas_n`
6. `why_this_version_won_n`

## Candidate Budget

每轮默认只允许：

1. `1` 个 canonical survivor
2. `3-5` 个 candidate deltas

不允许无限扩张 candidate population。

## Checkpoint Rule

每 `5` 轮必须做一次 integrated checkpoint。  
checkpoint 的职责：

1. 压缩最近 5 轮 accepted deltas
2. 重写 survivor 为可读 integrated snapshot
3. 重新列出 invariants 与 residual risks

## Termination Rule

本轮 seed 先冻结 4 条终止条件：

1. `max_rounds = 50`
2. 连续 `3` 轮提升低于阈值则 plateau stop
3. 连续 oscillation 触发 stop
4. safety lane 判定 catastrophic drift 时立刻 stop

## Round-01 Objective

`v3.01` 的任务不是“再写一版更长的文档”，而是：

1. 检查 `v2.50` 作为 seed 是否过厚、过粗、过于 integrated
2. 从 invariants 出发提出有限 candidate deltas
3. 形成第一份真实 scorecard
4. 选出第一个真正的 `survivor_01`

## Locked Principle

`v3` 链不允许再用“预先写好 50 轮 agenda 然后批量落盘”的方式运行。  
它必须是真正的慢速串行进化链。

## Residual Risk

1. round artifact 的文件命名和目录结构还未定稿
2. pairwise comparison 的具体格式还未定稿
3. plateau 阈值还未量化
