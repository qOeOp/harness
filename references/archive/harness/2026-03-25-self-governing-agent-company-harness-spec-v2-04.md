# Self-Governing Agent Company Harness Spec v2.4

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-03.md`
- Round focus:
  - source vs projection split

## Why This Round

大任务自治容易失败的一个根因，是 source of truth 与视图文件混写。

## Changes In This Version

1. 显式区分 `source state` 与 `projection state`。
2. boards/progress/status snapshot 只能由 source rebuild 或 controlled append 产生。
3. 禁止 agent 直接把 board 当作 primary mutation target。

## Locked Principle

只能改 source，不能改 view。

## Residual Risk

1. 还没定义 rebuild 命令
2. 还没定义 projection drift gate
