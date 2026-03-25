# Self-Governing Agent Company Harness Spec v2.46

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-45.md`
- Round focus:
  - update channels and rollout guard

## Why This Round

Hosted Kernel 最终一定是持续更新系统，不是一次性安装包。

## Changes In This Version

1. 固定 `dogfood / canary / stable` 三轨。
2. consumer repo 默认只允许 stable。
3. 跨轨升级必须经过 update-plan + doctor strict。

## Locked Principle

更新必须分轨，不允许全员跟浮动头。

## Residual Risk

1. 还没定义 downgrade contract
2. 还没定义 channel promotion criteria
