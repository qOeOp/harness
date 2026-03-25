# Self-Governing Agent Company Harness Spec v2.28

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-27.md`
- Round focus:
  - self-review and external review lanes

## Why This Round

完全自治不等于不要 review，而是要把 self-review 与 external review 分道。

## Changes In This Version

1. 定义 `self-review lane` 与 `reviewer lane`。
2. self-review 负责检查完整性；reviewer lane 负责找 bug/risk/regression。
3. major task closure 默认需要 reviewer lane。

## Locked Principle

自评和审查不是一回事。

## Residual Risk

1. 还没定义 minor task 的豁免条件
2. 还没定义 review SLA
