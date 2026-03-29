# Memory Architecture

更新日期：`2026-03-29`

## 目的

定义 `harness` 在 v2 task-record runtime 下的记忆分层，避免把 task truth、恢复协议、prompt-shape 配置、shared-writeback 投影和 source repo 文档混成一套叙事。

## 核心原则

1. source repo 与 consumer runtime 是两个不同的家。
2. 默认 runtime memory 是 `task-scoped`，不是 `workspace-scoped`。
3. `task.md` 既负责任务真相，也负责恢复协议。
4. task-local evidence 默认进入 `attachments/`，不是先落 shared writeback workspace。
5. `archived` 是状态语义，不是默认物理目录。
6. provider conversation / response / thread state 是 transport handle，不是 canonical task truth。
7. auto-injected `project memory / subagent memory`
   同时属于 instruction surface、
   persisted data 与 capability grant，
   不是 canonical task truth。
8. static instructions、tool descriptors、
   sandbox / cwd / approval metadata
   构成 prompt shape / runtime config surface；
   它不是 task truth，
   但长任务里要尽量保持 exact-prefix 稳定。

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

## Session / Project Memory Boundary

作用：把 transport continuity、persisted context 与 task truth 拆开，避免 memory surface 倒灌成第二本账。

说明：

1. provider background / pollable response 若依赖 provider-side stored state 才能轮询或恢复，这仍只是 transport continuity，不是 canonical task truth，也不应被误当成 zero-retention truth。
2. 这类 provider-owned stored state 可能带 retention / privacy / ZDR 边界；runtime 默认必须假设它可过期、不可取回，且仍能从 `task.md`、`attachments/` 与 `history/transitions/` 恢复。
3. serialized app / agent / session context、subagent memory directory、project memory 一旦会持久化或自动注入 prompt，就按 persisted data 治理，并带显式 scope、retention、schema / format version 与审计边界。
4. 若这些 memory surface 会隐式放宽工具能力或改变默认行为，它们还应同时视为 capability grant 与 instruction surface。
5. 真正影响 acceptance、恢复入口或外部承诺的 durable fact，仍必须回落到 `task.md`、task-local artifact 或 transition history。
6. static prefix、examples、tool descriptors、
   image descriptors、sandbox / cwd / approval metadata
   组成 prompt shape / runtime config surface；
   新的 task delta 与 tool observation
   默认追加在尾部，
   不静默回写前缀。
7. mid-run 改 model、tool 集合或枚举顺序、
   sandbox config、approval mode、cwd
   这类会破坏前缀稳定性的动作，
   默认应视为显式 boundary /
   transition，而不是隐式记忆延续。

## Layer 4: Task-Scoped Evidence And Trace

作用：沉淀与某个 task 直接绑定的证据、产出和审计流水。

目录：

- `.harness/tasks/<task-id>/attachments/`
- `.harness/tasks/<task-id>/attachments/sources/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/tasks/<task-id>/history/transitions/`

说明：

1. research brief / evidence ledger / acceptance ledger / decision / research / source / checkpoint 默认进入 `attachments/`。
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
2. 只有显式 `--promote-shared-writeback` 时，才值得把 task-local 材料升级到这里。
3. `--promote-governance` 只作为兼容别名保留。

## Writeback Rules

1. 默认先写回 task 目录，再考虑是否 promote 到 shared writeback surface。
2. task 状态变更必须通过正式脚本和 transition event，不手工 patch `task.md` 伪造状态。
3. Recovery 更新只写 `## Recovery`。
4. 需要跨任务共享记录时，再写 shared writeback projection。
5. 退出 active surface 时用 `Status: archived` 加 `Archived at` 表达。
6. observability 或 tracing 若默认开启，必须显式声明 capture / redaction / disable policy，不把 vendor default 当作 least-data 基线。

## 禁止事项

1. 不要把 `.harness/workspace/*` 当成默认任务真相。
2. 不要把 query 结果或 board projection 当成 canonical ledger。
3. 不要把聊天上下文当成长期恢复机制。
4. 不要把 provider transport state 直接晋升为 canonical task state。
