# True Evolutionary Hardening v3.01 Kickoff

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: kickoff-only
- Parent:
  - [True Evolutionary Hardening Seed v3.00](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolutionary-hardening-seed-v3-00.md)
- Scope:
  1. 启动 `v3.01` 的真实进化回合
  2. 明确它不是 survivor_01，而只是 round-01 的执行框架

## Round-01 Objective

本轮只做 4 件事：

1. 审计 [v2.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md) 是否过厚、过粗、过于 integrated
2. 从 frozen invariants 出发生成有限 candidate deltas
3. 形成第一份真实 pairwise scorecard
4. 选出第一个真正的 `survivor_01`

## Fixed Inputs

1. [v3.00 seed](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolutionary-hardening-seed-v3-00.md)
2. [round schema v1](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolution-round-schema-v1.md)
3. [scorecard schema v1](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolution-scorecard-schema-v1.md)
4. [lineage schema v1](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolution-lineage-schema-v1.md)

## Required Outputs

本轮执行完后，至少必须出现：

1. `survivor_01`
2. `scorecard_01`
3. `accepted_deltas_01`
4. `rejected_deltas_01`
5. `residual_risks_01`
6. `why_this_version_won_01`

## Locked Principle

`v3.01 kickoff` 不是结果宣言。  
它只是宣告：现在已经有条件开始真实进化。

## Residual Risk

1. `v3.01` 还未真正执行
2. 第一轮的 candidate budget 还未落成具体文件
