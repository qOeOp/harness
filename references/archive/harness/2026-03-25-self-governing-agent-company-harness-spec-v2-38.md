# Self-Governing Agent Company Harness Spec v2.38

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-37.md`
- Round focus:
  - archive and prune policy

## Why This Round

复利不是无限增长，过量积累会反噬可用性。

## Changes In This Version

1. 定义 archive policy：active、warm、cold 三层。
2. 只有 current truth 与近期高价值资产保留在热层。
3. prune 只允许 archive，不允许静默删除 append-only history。

## Locked Principle

保留历史，不保留热噪音。

## Residual Risk

1. 还没定义各层 retention
2. 还没定义 archive retrieval UX
