# Self-Governing Agent Company Harness Spec v2.22

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-21.md`
- Round focus:
  - plan/apply split for mutating work

## Why This Round

只对 update 做 plan/apply 不够，所有高风险写动作都要分相。

## Changes In This Version

1. 把所有 mutating actions 分成 `plan` 与 `apply`。
2. plan 必须描述 intended files、state targets、evidence、rollback hooks。
3. apply 只能消费已接受的 plan。

## Locked Principle

危险动作不允许一步到位。

## Residual Risk

1. 还没定义 lightweight/no-plan exemptions
2. 还没定义 apply 过期条件
