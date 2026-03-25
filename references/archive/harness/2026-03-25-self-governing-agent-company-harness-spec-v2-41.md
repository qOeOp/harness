# Self-Governing Agent Company Harness Spec v2.41

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-40.md`
- Round focus:
  - bootstrap-state detection

## Why This Round

生命周期层第一步不是写文件，而是判断当前仓库处于哪种状态。

## Changes In This Version

1. 定义 bootstrap-state：`fresh / partial / adopted / drifted / broken / dogfood`。
2. 所有 lifecycle 命令先做 state detection。
3. 不同状态触发不同 allowed next actions。

## Locked Principle

先判断状态，再决定动作。

## Residual Risk

1. 还没定义 state detector 规则
2. 还没定义 partial 与 broken 的边界
