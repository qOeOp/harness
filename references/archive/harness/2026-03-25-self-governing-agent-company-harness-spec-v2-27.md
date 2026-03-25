# Self-Governing Agent Company Harness Spec v2.27

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-26.md`
- Round focus:
  - repair scope and limits

## Why This Round

repair 是自治系统里最危险的按钮之一。

## Changes In This Version

1. repair 仅允许修复 generated metadata、managed blocks、projection rebuild。
2. repair 默认不得改 append-only assets 与用户正文。
3. 超出 repair scope 一律 escalate。

## Locked Principle

修复不能变成越权重写。

## Residual Risk

1. 还没定义 repair preview
2. 还没定义 repair 之后的 doctor gating
