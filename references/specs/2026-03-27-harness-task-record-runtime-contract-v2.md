# Harness Task-Record Runtime Contract v2

- Status: accepted
- Date: 2026-03-27
- Scope: define the active minimum runtime as a flat task-record system with header-driven workflow, routing, and signoff
- Related:
  - [references/layering.md](../../references/layering.md)
  - [references/runtime-workspace.md](../../references/runtime-workspace.md)
  - [references/top-level-surface.md](../../references/top-level-surface.md)
  - [references/contracts/task-record-runtime-tree-v2.toml](../../references/contracts/task-record-runtime-tree-v2.toml)

## Contract Summary

`harness` 的默认 minimum runtime 采用 `task-record` 模型。

核心要求只有四条：

1. `.harness/tasks/<task-id>/task.md` 是唯一任务真相
2. Recovery 与主状态同文件共存
3. task-local 正式材料默认进入 `attachments/`
4. `archived` 用状态字段表达，而不是目录迁移

## Target Tree

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  runtime/
  tasks/
    WI-0001/
      task.md
      attachments/
      closure/
      history/
        transitions/
  locks/
```

规则：

1. `runtime/` 是按需出现的 non-canonical support root，用于 cache、tool home、isolated env 等 operational state
2. `attachments/`、`closure/`、`history/transitions/` 按需创建
3. 默认 query 直接从 `task.md` header 派生
4. board 不属于默认 runtime contract

## Canonical Task Record

### Required Header Fields

1. `Schema version`
2. `State authority`
3. `State version`
4. `Last operation ID`
5. `ID`
6. `Title`
7. `Type`
8. `Status`
9. `Priority`
10. `Owner`
11. `Sponsor`
12. `Assignee`
13. `Worktree`
14. `Claimed at`
15. `Claim expires at`
16. `Lease version`
17. `Objective`
18. `Ready criteria`
19. `Done criteria`
20. `Current stage owner`
21. `Current stage role`
22. `Next gate`
23. `Founder escalation`
24. `Decision status`
25. `Review status`
26. `QA status`
27. `UAT status`
28. `Acceptance status`
29. `Blocked by`
30. `Current blocker`
31. `Next handoff`
32. `Linked attachments`
33. `Created at`
34. `Updated at`
35. `Archived at`

### Recommended Sections

1. `## Summary`
2. `## Recovery`
3. `## Workflow Notes`
4. `## Signoff Notes`
5. `## Attachment Notes`
6. `## Transition Log`
7. `## Notes`

### Recovery Fields

`## Recovery` 至少应包含：

1. `Current focus`
2. `Next command`
3. `Recovery notes`

## State Model

### Primary Statuses

1. `backlog`
2. `planning`
3. `ready`
4. `in-progress`
5. `review`
6. `paused`
7. `done`
8. `killed`
9. `archived`

### Gate Fields

以下能力通过 gate 字段承载，而不是主状态：

1. `Decision status`
2. `Review status`
3. `QA status`
4. `UAT status`
5. `Acceptance status`

## Workflow Routing

task record 同时承载状态与路由。

当前处理链路至少通过这些字段表达：

1. `Current stage owner`
2. `Current stage role`
3. `Next gate`
4. `Founder escalation`

## Attachment Routing

默认 task-local 路径：

1. `Research Dispatch`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md`
2. `Source Note`
   - `.harness/tasks/<task-id>/attachments/sources/<date>-<slug>.md`
3. `Research Memo`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-memo.md`
4. `Decision Pack`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-decision-pack.md`
5. `Checkpoint`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-checkpoint.md`
6. `Role Change Proposal`
   - `.harness/tasks/<task-id>/closure/<date>-<slug>-role-change-proposal.md`

## Query Surface

默认 query 行为：

1. shell 动态查询
2. 默认排除 `archived`
3. 通过 header 过滤 `status / assignee / role / next gate / gate status`
4. 不依赖 persisted board

## Validation Surface

source repo：

1. [validate_source_repo.sh](/Users/vx/WebstormProjects/harness/scripts/validate_source_repo.sh)
2. [run_governance_surface_diagnostic.sh](/Users/vx/WebstormProjects/harness/scripts/run_governance_surface_diagnostic.sh)

materialized runtime：

1. [validate_workspace.sh](/Users/vx/WebstormProjects/harness/scripts/validate_workspace.sh)
2. [audit_document_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_document_system.sh)
3. [audit_state_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_state_system.sh)
4. [run_state_validation_slice.sh](/Users/vx/WebstormProjects/harness/scripts/run_state_validation_slice.sh)

## Non-Goals

1. 不把目录位置当成业务状态
2. 不把 board 当成账本
3. 不把聊天上下文当成长期恢复机制
4. 不把治理投影当成默认 task truth
