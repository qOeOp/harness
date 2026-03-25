# Self-Governing Agent Company Harness Spec v2.10

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-09.md`
- Round focus:
  - state acceptance suite

## Why This Round

前 9 轮只是结构约束，本轮要把状态系统接进机械验收。

## Changes In This Version

1. 新增 state acceptance suite：fresh state、duplicate command、lease conflict、replay rebuild、projection drift。
2. 任何 state schema 变更都必须通过 suite。
3. suite 失败时禁止进入更高层 agent orchestration。

## Locked Principle

没有状态验收，组织化 agent 只是表演。

## Residual Risk

1. 还没定义组织模型
2. 还没定义 work package handoff
