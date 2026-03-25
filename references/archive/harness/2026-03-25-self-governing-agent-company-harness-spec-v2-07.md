# Self-Governing Agent Company Harness Spec v2.7

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-06.md`
- Round focus:
  - ownership stamps on state changes

## Why This Round

像公司一样组织活动，关键不是角色名字，而是每次变更都知道谁拥有、谁批准、谁执行。

## Changes In This Version

1. 每条状态变更必须写入 `requested_by / executed_by / reviewed_by / approved_by` 中的适用字段。
2. 默认禁止“匿名状态推进”。
3. owner 变更必须单独记账。

## Locked Principle

没有 ownership stamp 的状态推进，一律视为不可信。

## Residual Risk

1. 还没定义谁有权担任 reviewer/approver
2. 还没定义 owner 缺失时的 fail path
