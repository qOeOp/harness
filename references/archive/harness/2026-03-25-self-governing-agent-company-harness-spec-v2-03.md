# Self-Governing Agent Company Harness Spec v2.3

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-02.md`
- Round focus:
  - work-item canonical schema

## Why This Round

如果 work item 只是松散 markdown，组织化多 agent 无法稳定 handoff。

## Changes In This Version

1. 把 work item 固定为 `intent / owner / delegated_to / status / acceptance / evidence / blockers / next_action` 八段。
2. 要求每个大任务必须能拆成可委派 work package。
3. 禁止没有 acceptance 的 work item 进入执行。

## Locked Principle

任务不是备忘录，而是带验收合同的执行对象。

## Residual Risk

1. 还没定义 work package 与 parent task 的约束
2. 还没定义 acceptance 证据形态
