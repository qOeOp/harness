# Self-Governing Agent Company Harness Spec v2.49

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-48.md`
- Round focus:
  - framework vs instance boundary

## Why This Round

如果 framework 与 instance 边界不硬，所有前面的合同最终都会泄漏。

## Changes In This Version

1. 正式锁定 `harness-framework = distribution product repo`。
2. `consumer repo = runtime state + root overlay + repo-local projections`。
3. `trading-agent = dogfood/canary consumer`，不是 framework source of truth。

## Locked Principle

框架与实例必须分仓、分责、分生命周期。

## Residual Risk

1. 还没给出拆仓执行顺序
2. 还没定义 migration checklist
