# Self-Governing Agent Company Harness Spec v2.2

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-01.md`
- Round focus:
  - command journal schema

## Why This Round

多 agent 独立完成大任务的第一硬约束不是更多角色，而是每次状态变更都能被重放和解释。

## Changes In This Version

1. 新增 `command-journal` 作为 append-only mutation ledger。
2. 每条 journal 必须记录 `actor / command / target / idempotency_key / intent / timestamp / result_state`。
3. 任何 agent 发起的状态变化都先写 journal，再更新 projection。

## Locked Principle

没有 mutation ledger，就没有可审计自治。

## Residual Risk

1. 还没定义失败命令的回放语义
2. 还没定义 journal 与 progress 的对应关系
