# Self-Governing Agent Company Harness Spec v2.1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-31.md`
- Round focus:
  - state root taxonomy

## Why This Round

v1.31 已把 Hosted Kernel 的分发与入口压硬，但要让 agent 像公司一样长期独立完成大任务，首先必须把 `.harness/workspace` 的状态根分类再压实。

## Changes In This Version

1. 把 repo-local runtime state 固定拆成 `command-journal / work-items / boards / progress / decisions / briefs / source-notes / incidents` 八类。
2. 明确只有 `command-journal` 与 `work-items` 能作为原始执行状态源；其他目录默认是 projection 或 compounding asset。
3. 禁止把“讨论草稿”直接当成任务状态真相。

## Locked Principle

状态根先分型，再谈自动化；没有类型，后续所有 agent 自治都会漂。

## Residual Risk

1. 还没定义 command-journal 的字段
2. 还没定义 work-item 的 canonical schema
3. 还没定义 projection rebuild contract
