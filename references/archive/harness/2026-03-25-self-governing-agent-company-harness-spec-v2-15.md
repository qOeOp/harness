# Self-Governing Agent Company Harness Spec v2.15

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-14.md`
- Round focus:
  - handoff artifact routing

## Why This Round

多 agent 组织的失败点常在 handoff，而不是执行。

## Changes In This Version

1. 定义 handoff artifact 只有三类：`finding / patch / decision-request`。
2. 每次 handoff 必须落到固定路径或固定 work item 字段。
3. 禁止纯聊天 handoff 作为 canonical output。

## Locked Principle

handoff 必须落 artifact，不能只落对话。

## Residual Risk

1. 还没定义 artifact retention policy
2. 还没定义跨轮次 handoff 合并
