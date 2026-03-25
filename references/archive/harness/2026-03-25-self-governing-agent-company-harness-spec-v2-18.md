# Self-Governing Agent Company Harness Spec v2.18

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-17.md`
- Round focus:
  - interrupt and resume contract

## Why This Round

长任务一定会被打断；没有中断协议，多 agent 会失去上下文。

## Changes In This Version

1. 为每个 active work item 强制维护 `resume point`。
2. interrupt 必须写明 `what changed / what remains / safe next action`。
3. resume 不允许靠回忆，必须靠 artifact。

## Locked Principle

恢复必须读 artifact，不读记忆。

## Residual Risk

1. 还没定义 interrupt 优先级
2. 还没定义抢占式中断的租约处理
