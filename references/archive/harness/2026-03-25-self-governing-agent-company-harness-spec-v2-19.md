# Self-Governing Agent Company Harness Spec v2.19

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-18.md`
- Round focus:
  - escalation matrix

## Why This Round

公司式运行需要升级路径，不是所有问题都让主线程拍脑袋。

## Changes In This Version

1. 定义 escalation 只有四类：`schema ambiguity / ownership conflict / unsafe mutation / missing evidence`。
2. 每类升级必须对应固定 receiver。
3. 不在矩阵内的问题默认 local resolve。

## Locked Principle

升级路径必须有限、明确、可追踪。

## Residual Risk

1. 还没定义 founder escalation 边界
2. 还没定义 unresolved escalation timeout
