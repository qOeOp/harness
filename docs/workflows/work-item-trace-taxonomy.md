# Work Item Trace Taxonomy

更新日期：`2026-03-23`

## 目的

给 `.harness/tasks/<task-id>/history/transitions/` 里的 item-scoped transition event 增加显式、可审计、可脚本消费的最小分类。

本文件只定义 work item state layer 的 trace taxonomy。
它不引入新的全局 trace ledger，也不提前设计 product runtime span model。

## 核心原则

1. `Event type` 分类的是 transition event，不是 work item。
2. `task.md` 仍然是运行态 source of truth；taxonomy 只是让 transition ledger 更可解释。
3. v1 只覆盖 state harness 当前已经稳定存在的受控 mutation。
4. 旧 event 可以没有 `Event type`；新写入 event 必须带类型。
5. `board-refresh` 在 v1 里只保留为 reserved class，不进入当前 item-scoped ledger。

## 字段与落点

1. 新协议 transition event 应包含 `Event type`。
2. `Event type` 由受控写脚本生成，不靠手工补写。
3. `./.agents/skills/harness/scripts/audit_state_system.sh` 负责验证 `Event type` 属于 allowlist。

## Allowlist

1. `state-transition`
   - 普通状态迁移。
   - 包含 create、ready/in-progress/review/done/killed 等常规推进。
2. `artifact-link`
   - `Linked artifacts` 发生变化，但 `From == To`。
3. `approval-pause`
   - 进入 `paused` 的中断事件。
   - 必须伴随合法 `Interrupt marker` 和 `Resume target`。
4. `resume`
   - 从 `paused` 恢复到预先声明的 `Resume target`。
5. `field-update`
   - 结构化头字段变更，但 `From == To`。
6. `terminal-cleanup`
   - terminal item 在 finalize 后清理 blocker / handoff / interrupt 残留，但 `From == To`。
7. `blocker-release`
   - 上游 terminal cleanup 释放下游依赖项的 `Blocked by`，但下游 `From == To`。
8. `schema-migration`
   - 受控 schema backfill / migration，且 `From == To`。
9. `board-refresh`
   - reserved for separate board-level ledger。
   - 正式落点见 `docs/workflows/board-refresh-ledger.md`，不写进当前 item-scoped transition ledger。

## 一致性规则

1. `approval-pause` 只能用于 `To: paused`。
2. `resume` 只能用于 `From: paused` 且 `To` 不是 `paused / killed`。
3. `artifact-link`、`field-update`、`terminal-cleanup`、`blocker-release`、`schema-migration`、`board-refresh` 都必须满足 `From == To`。
4. taxonomy 是 allowlist，不是自由标签系统。

## 当前脚本映射

1. `./.agents/skills/harness/scripts/new_work_item.sh` -> `state-transition`
2. `./.agents/skills/harness/scripts/transition_work_item.sh`
   - 普通迁移 -> `state-transition`
   - 进入 `paused` -> `approval-pause`
   - 从 `paused` 恢复 -> `resume`
3. `./.agents/skills/harness/scripts/link_work_item_artifact.sh` -> `artifact-link`
4. `./.agents/skills/harness/scripts/update_work_item_fields.sh` -> `field-update`
5. `./.agents/skills/harness/scripts/cleanup_terminal_work_item.sh`
   - root cleanup -> `terminal-cleanup`
   - downstream release -> `blocker-release`
6. `./.agents/skills/harness/scripts/backfill_interrupt_fields.sh` -> `schema-migration`

## 校验边界

1. `./.agents/skills/harness/scripts/audit_state_system.sh`
   - 校验 typed event 属于 allowlist
   - 校验 pause/resume 与 `Event type` 的基本一致性
2. `./.agents/skills/harness/scripts/run_state_validation_slice.sh`
   - 在 sandbox 里证明至少一个 item chain 同时出现：
     - `state-transition`
     - `artifact-link`
     - `approval-pause`
     - `resume`

## 非目标

1. 不把 board refresh 强行塞进 work item transition chain。
2. 不在本轮设计 runtime trace storage。
3. 不引入 provider-specific tracing SDK 作为 state harness 前置依赖。
