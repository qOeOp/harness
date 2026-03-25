# Self-Governing Agent Company Harness Spec v2.26

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-25.md`
- Round focus:
  - recovery tree

## Why This Round

门禁有了以后，还需要让 agent 知道失败后如何有序恢复。

## Changes In This Version

1. 定义 recovery tree：`doctor -> repair -> replay -> escalate`。
2. 每类 failure 必须映射到一条恢复路径。
3. 禁止失败后直接人工乱改 `.harness`。

## Locked Principle

恢复必须是树，不是即兴操作。

## Residual Risk

1. 还没定义 repair 权限
2. 还没定义 replay 失败后的手册
