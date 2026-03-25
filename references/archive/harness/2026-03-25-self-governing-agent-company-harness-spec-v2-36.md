# Self-Governing Agent Company Harness Spec v2.36

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-35.md`
- Round focus:
  - incident and learning replay

## Why This Round

真正的复利不只是记录成功，还要把失败变成可重放教训。

## Changes In This Version

1. 新增 incident asset，记录 failure mode、blast radius、recovery path。
2. incident 必须生成 replayable lesson。
3. 重复 incident 触发 process-audit。

## Locked Principle

失败只有被 replay，才会变成资产。

## Residual Risk

1. 还没定义 incident severity
2. 还没定义 replayable lesson 模板
