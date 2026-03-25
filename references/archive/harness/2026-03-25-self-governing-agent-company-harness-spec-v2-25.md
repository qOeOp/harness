# Self-Governing Agent Company Harness Spec v2.25

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-24.md`
- Round focus:
  - stop-the-line triggers

## Why This Round

真正的自我约束不是多做，而是知道何时必须停。

## Changes In This Version

1. 定义 stop triggers：schema ambiguity、unsafe overwrite、conflicting source of truth、verification failure、provider mismatch。
2. 触发 stop 后只能 doctor/repair/escalate。
3. 任何绕过 stop 的 apply 都视为 contract break。

## Locked Principle

知道何时停，比知道如何快更重要。

## Residual Risk

1. 还没定义 stop trigger severity
2. 还没定义恢复后 reopen 条件
