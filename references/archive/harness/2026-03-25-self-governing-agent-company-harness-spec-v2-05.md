# Self-Governing Agent Company Harness Spec v2.5

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-04.md`
- Round focus:
  - append-only mutation protocol

## Why This Round

公司式多 agent 组织一旦允许任意覆盖写，状态系统会快速失真。

## Changes In This Version

1. 所有 journal、decision、brief、incident 默认 append-only。
2. 允许 replace 的仅限 managed metadata 与 explicitly ephemeral projections。
3. 引入 `supersedes` 字段替代原文覆盖。

## Locked Principle

先写新事实，不改旧事实。

## Residual Risk

1. 还没定义 supersedes 链的清理规则
2. 还没定义 append-only 资产的 prune policy
