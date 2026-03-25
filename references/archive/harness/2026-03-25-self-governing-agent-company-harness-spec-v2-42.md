# Self-Governing Agent Company Harness Spec v2.42

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-41.md`
- Round focus:
  - survey-plan-apply lifecycle

## Why This Round

安装和接管都不该一步到位，必须先 survey、再 plan、再 apply。

## Changes In This Version

1. bootstrap、adopt、update、repair 全部采用 `survey -> plan -> apply`。
2. survey 输出只读报告。
3. apply 只能消费当前 survey/plan 的产物。

## Locked Principle

没有 survey 的 apply，一律不可信。

## Residual Risk

1. 还没定义 plan artifact schema
2. 还没定义 apply staleness
