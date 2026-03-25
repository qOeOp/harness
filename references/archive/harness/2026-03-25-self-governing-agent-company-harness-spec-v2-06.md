# Self-Governing Agent Company Harness Spec v2.6

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-05.md`
- Round focus:
  - idempotency and mutation tokens

## Why This Round

多 agent 并行时，同一动作重复执行是常态，不是例外。

## Changes In This Version

1. 每个 mutating command 必须带 `idempotency_key`。
2. 引入 `mutation_token` 防止同一 work item 被重复完成。
3. 重复 journal apply 必须得到同一结果或明确 no-op。

## Locked Principle

幂等是并行自治的底板，不是优化项。

## Residual Risk

1. 还没定义 token 生命周期
2. 还没定义跨 provider 的 token format
