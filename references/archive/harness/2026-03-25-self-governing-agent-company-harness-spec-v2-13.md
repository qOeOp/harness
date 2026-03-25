# Self-Governing Agent Company Harness Spec v2.13

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-12.md`
- Round focus:
  - task decomposition tree

## Why This Round

agent 要独立完成大任务，必须把“大任务”变成可递归分解的树，而不是长 TODO。

## Changes In This Version

1. 每个 major task 必须生成 decomposition tree。
2. 父任务只能在子任务 acceptance 满足后推进。
3. 树节点必须区分 `analysis / implementation / verification / integration` 四类。

## Locked Principle

大任务不分解，就不可能稳定自治。

## Residual Risk

1. 还没定义 tree depth 限制
2. 还没定义跨树依赖
