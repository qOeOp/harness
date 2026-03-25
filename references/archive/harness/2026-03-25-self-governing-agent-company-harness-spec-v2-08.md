# Self-Governing Agent Company Harness Spec v2.8

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-07.md`
- Round focus:
  - concurrency windows and leases

## Why This Round

大任务往往需要并行，但并行必须有租约边界。

## Changes In This Version

1. 为 work item 引入 `lease` 概念，限定 agent 在某时间窗内拥有写权限。
2. 跨 agent 并行默认只能共享读，不能共享写。
3. lease 过期必须显式 renew 或 relinquish。

## Locked Principle

并行不是共享写；并行是受控租约。

## Residual Risk

1. 还没定义 lease renewal 机制
2. 还没定义冲突 lease 的仲裁
