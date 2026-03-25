# Self-Governing Agent Company Harness Spec v2.16

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-15.md`
- Round focus:
  - manager-worker review loop

## Why This Round

组织化不是 manager 发号施令，而是 manager 负责收敛与门禁。

## Changes In This Version

1. manager 必须在 worker 产出后执行收敛 review。
2. worker 不得自批准 major task closure。
3. review loop 输出固定为 `accept / revise / split-further / stop`。

## Locked Principle

manager 的价值在收敛与阻断，不在代做。

## Residual Risk

1. 还没定义 lead 与 manager 的分工
2. 还没定义 revise 的次数上限
