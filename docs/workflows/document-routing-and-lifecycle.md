# Document Routing And Lifecycle

更新日期：`2026-03-28`

## 目的

为 `/harness` 提供稳定入口，并把 task truth、恢复信息、task-local 附件与共享写回明确分层。

## Current Placement

默认产品入口仍然是：

1. `/harness`

repo-local runtime 只在需要持久化时出现：

1. `.harness/`

本文件描述的是 `task-record runtime v2` 的默认 routing / lifecycle，而不是 board-first 或 company-workspace-first 体验。

## 硬规则

1. 一个任务只有一个 canonical truth：`.harness/tasks/<task-id>/task.md`
2. 恢复信息写入 `task.md` 的 `## Recovery`
3. `archived` 通过状态字段表达
4. board 和 company / workstream projection 不属于默认 core routing
5. 一个线程一个 worktree，不共享同一工作目录并行编辑
6. 不允许没有 disposition 的 durable write 进入 active surface

## Write Disposition Rule

任何新增写回在落盘前，都必须先回答它属于哪一层：

1. `ephemeral`
   - 只服务当前 session 推理
   - 不落盘
2. `canonical task truth`
   - 直接更新 `.harness/tasks/<task-id>/task.md`
3. `task-local durable artifact`
   - 进入 `attachments/`、`closure/` 或 `history/transitions/`
4. `shared writeback`
   - 只有显式 promote 时，才进入 `.harness/workspace/*`
5. `cold archive`
   - 已退出默认 working set，只为 lineage / replay / audit 保留

没有第六种默认落点。

如果一个拟写文件只是：

1. 重复转述已有结论
2. 临时思考痕迹
3. 旧版本的平行重写
4. 未来没有明确默认读者

则默认不应新建 durable 文件，而应：

1. 更新现有 canonical surface
2. 压缩进现有 survivor doc
3. 或直接丢弃

## Routing Order

任何新开的 `/harness` 任务，都不应直接扫全仓库。

正确顺序是：

1. 若任务预计一轮内自然收口：
   - 保持 ephemeral session mode
   - 不创建 `.harness/`
2. 若任务需要跨回合追踪、恢复、review、decision 或 research writeback：
   - materialize 最小 runtime
   - 创建 `.harness/manifest.toml`
   - 创建 `.harness/tasks/<task-id>/task.md`
   - 按需创建 `attachments/`、`history/transitions/` 等 task-local 目录
3. 若 runtime 已存在：
   - 先读 `.harness/README.md`
   - 再读 `.harness/entrypoint.md`
   - 再通过 `./scripts/query_work_items.sh` 定位 task
   - 若当前状态为 `in-progress` 或 `paused`，继续读该 task 的 `## Recovery`
4. 若当前事项处于 `paused`：
   - 先读 `Interrupt marker` 与 `Resume target`
   - 再决定是否恢复，不要靠聊天记忆猜
5. 只在需要时读取：
   - `attachments/`
   - `history/transitions/`
   - 显式 promote 的 shared writeback

## Current Implementation Note

当前 source repo 的 task kernel 主要由脚本实现。

推荐的高层入口：

1. [work_item_ctl.sh](/Users/vx/WebstormProjects/harness/scripts/work_item_ctl.sh)
   - `status / start / pause / resume / close`
2. [query_work_items.sh](/Users/vx/WebstormProjects/harness/scripts/query_work_items.sh)
3. [open_work_item.sh](/Users/vx/WebstormProjects/harness/scripts/open_work_item.sh)
4. [upsert_work_item_recovery.sh](/Users/vx/WebstormProjects/harness/scripts/upsert_work_item_recovery.sh)

说明：

1. `status` 现在是 query surface，不再是“open 当前焦点”
2. `upsert_work_item_recovery.sh` 写的是 `task.md` 的 `## Recovery`

## Version Lifecycle

正确生命周期是：

1. `active task`
   - 当前 task 保持在 `.harness/tasks/<task-id>/task.md`
2. `active recovery`
   - 若任务仍在执行，用同一文件的 `## Recovery` 承担恢复信息
3. `attachment accumulation`
   - task 产物进入 `attachments/`、`closure/` 与 `history/transitions/`
4. `historical recall`
   - 需要回溯时优先读 archived task record 和 transition ledger
5. `close and compact`
   - 任务完成后可转为 `archived`
   - 用 `Archived at` 表达离开默认 active surface 的时间
   - 关闭前应确认 active reading order 已收敛到更小的 survivor set，而不是保留并行摘要链

## Validation

framework source repo：

```bash
./scripts/validate_source_repo.sh
./scripts/audit_role_schema.sh
./scripts/run_governance_surface_diagnostic.sh --mode source
```

materialized runtime：

```bash
./scripts/validate_workspace.sh --mode core
./scripts/audit_state_system.sh --mode core
./scripts/audit_document_system.sh
./scripts/validate_freshness_gate.sh --staged
./scripts/run_state_validation_slice.sh
```

shared-writeback runtime：

```bash
./scripts/validate_workspace.sh --mode governance
./scripts/audit_state_system.sh --mode governance
./scripts/audit_document_system.sh
./scripts/validate_freshness_gate.sh --staged
./scripts/run_governance_surface_diagnostic.sh --mode consumer
```

## 禁止事项

1. 不要让 agent 默认扫描全仓库 markdown 才理解当前任务
2. 不要让 company / workstream 投影反向定义默认 runtime
3. 不要把 query 结果或 board projection 当成 source of truth
4. 不要把额外文件或目录再次变成任务真相的并行平面
