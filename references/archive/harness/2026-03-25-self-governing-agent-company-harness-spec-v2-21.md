# Self-Governing Agent Company Harness Spec v2.21

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-20.md`
- Round focus:
  - autonomy gate ladder

## Why This Round

独立完成大任务的前提不是放权，而是门禁阶梯。

## Changes In This Version

1. 定义四级 autonomy gate：`safe-read / planned-write / reviewed-apply / escalated-stop`。
2. 不同动作必须落在不同 gate。
3. 默认禁止 agent 跳级执行。

## Locked Principle

自治的正确形式不是自由，而是分级授权。

## Residual Risk

1. 还没定义每类命令对应 gate
2. 还没定义 gate 失败日志
