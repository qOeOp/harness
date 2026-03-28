# Memory Architecture

更新日期：`2026-03-28`

## 目的

定义 `harness` 在 v2 task-record runtime 下的记忆分层，避免把 task truth、恢复协议、治理投影和 source repo 文档混成一套叙事。

## 核心原则

1. source repo 与 consumer runtime 是两个不同的家。
2. 默认 runtime memory 是 `task-scoped`，不是 `workspace-scoped`。
3. `task.md` 既负责任务真相，也负责恢复协议。
4. task-local evidence 默认进入 `attachments/`，不是先落 governance workspace。
5. `archived` 是状态语义，不是默认物理目录。
6. provider conversation / response / thread state 是 transport handle，不是 canonical task truth。

## Layer 0: Source Repo Constitution

作用：定义 framework source 的长期边界与生成契约。

文件：

- [SKILL.md](/Users/vx/WebstormProjects/harness/SKILL.md)
- [docs/project-structure.md](/Users/vx/WebstormProjects/harness/docs/project-structure.md)
- [references/layering.md](/Users/vx/WebstormProjects/harness/references/layering.md)
- [references/runtime-workspace.md](/Users/vx/WebstormProjects/harness/references/runtime-workspace.md)
- [references/top-level-surface.md](/Users/vx/WebstormProjects/harness/references/top-level-surface.md)

说明：

1. 这一层属于 source repo，不属于 consumer runtime 的 live state。
2. `.harness/entrypoint.md` 只在 consumer runtime 被 materialize 后出现。

## Layer 1: Runtime Envelope

作用：给 materialized consumer runtime 提供最小、稳定、可审计的运行外壳。

文件：

- `.harness/entrypoint.md`
- `.harness/manifest.toml`
- `.harness/README.md`
- `.harness/tasks/<task-id>/task.md`

说明：

1. runtime envelope 只承载最小 task-record 外壳。
2. task routing 与恢复协议都从 `task.md` 派生。

## Layer 2: Task Record Truth

作用：让单个 `task.md` 成为任务的唯一重实体真相。

字段分组：

1. 身份与主状态
2. assignee / worktree / claim
3. stage owner / stage role / next gate
4. decision / review / QA / UAT / acceptance gate
5. blockers / handoff / linked attachments

说明：

1. `task.md` 是唯一任务 source of truth。
2. query、selector、audit、validation 都应从这里派生。
3. 不再靠目录位置表达任务状态。

## Layer 3: Recovery Memory

作用：把跨回合恢复信息从聊天上下文里剥离出来，但不再拆成第二个文件。

位置：

- `.harness/tasks/<task-id>/task.md`
  - `## Recovery`
  - `Current focus`
  - `Next command`
  - `Recovery notes`

说明：

1. `./scripts/upsert_work_item_recovery.sh` 写的是 `task.md` 的 `## Recovery`。
2. Recovery 只负责恢复协议，不承载决策正文或第二套状态。
3. 若任务仍绑定 in-flight provider execution，可记录 `response_id`、`thread id`、`stream cursor`、`trace id` 这类 execution handle，但它们只服务 reconnect / resume / trace correlation。

## Layer 4: Task-Scoped Evidence And Trace

作用：沉淀与某个 task 直接绑定的证据、产出和审计流水。

目录：

- `.harness/tasks/<task-id>/attachments/`
- `.harness/tasks/<task-id>/attachments/sources/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/tasks/<task-id>/history/transitions/`

说明：

1. decision / research / source / checkpoint 默认进入 `attachments/`。
2. transition ledger 是 append-only trace，不应用 narrative 文本替代。
3. accepted task 的 `Role Change Proposal` 默认属于 `closure/`。

## Layer 5: Optional Cross-Task Projection

作用：只在显式升级到 cross-task mode 后承载跨任务、跨节奏的派生材料。

目录示例：

- `.harness/workspace/decisions/log/`
- `.harness/workspace/research/`
- `.harness/workspace/status/`

说明：

1. 这一层是 projection，不是默认 truth。
2. 只有显式 `--promote-governance` 时，才值得把 task-local 材料升级到这里。

## Writeback Rules

1. 默认先写回 task 目录，再考虑是否 promote 到治理层。
2. task 状态变更必须通过正式脚本和 transition event，不手工 patch `task.md` 伪造状态。
3. Recovery 更新只写 `## Recovery`。
4. 需要跨任务治理时，再写治理层 projection。
5. 退出 active surface 时用 `Status: archived` 加 `Archived at` 表达。

## 禁止事项

1. 不要把 `.harness/workspace/*` 当成默认任务真相。
2. 不要把 query 结果或 board projection 当成 canonical ledger。
3. 不要把聊天上下文当成长期恢复机制。
4. 不要把 provider transport state 直接晋升为 canonical task state。
