# Board Refresh Ledger

更新日期：`2026-03-28`

## 目的

把 board 派生写入从 item-scoped transition chain 里剥离出来，收敛到单独的 board-level append-only ledger。

本文件只处理 `refresh_boards.sh`。
它不定义 runtime/session trace，也不改写 `task.md` 作为 source of truth 的地位。

## 核心原则

1. `.harness/tasks/*/task.md` 是默认运行态 source of truth。
2. `boards/` 仍然是 generated-only 视图。
3. legacy `.harness/workspace/state/items/*.md` 只作为迁移期 fallback 读取面。
4. board refresh event 记录的是派生视图写入，不是业务状态迁移。
5. board refresh event 必须独立于 work item transition ledger。
6. 只有发生实际 board 文件变化时才写 board refresh event。
7. board surface 只在 shared writeback runtime 下 materialize。

## 存储位置

1. 目录固定为 `.harness/workspace/state/board-refreshes/`。
2. 文件名格式为 `BR-<timestamp>.md`。
3. ledger 使用全局 append-only hash chain。

## 最小字段

1. `At`
2. `Actor`
3. `Invoker`
4. `Targets`
5. `Prev event`
6. `Prev event hash`
7. `Event hash`

## 生成规则

1. `./scripts/refresh_boards.sh --check`
   - 只验证 board 是否和 `task.md` 派生结果同步
   - 不写 event
2. `./scripts/refresh_boards.sh`
   - 若无 board 内容变化，不写 event
   - 若有变化，写一条 board refresh event
3. write mode 必须带显式非 `system` 的 `STATE_ACTOR`

## Targets 边界

`Targets` 只允许包含：

1. `.harness/workspace/state/boards/company.md`
2. `.harness/workspace/state/boards/founder.md`

## 与 trace taxonomy 的关系

1. `docs/workflows/work-item-trace-taxonomy.md` 里的 `board-refresh` 仍然保留。
2. 但它不写进 item-scoped `.harness/tasks/<task-id>/history/transitions/`。
3. 它在这里作为独立 ledger 落地。

## 审计边界

1. `./scripts/audit_state_system.sh` 校验：
   - board refresh event hash chain 完整
   - target 路径合法且存在
   - actor 非空且非 `system`
   - minimum-core runtime 不强制要求 board surface
2. `./scripts/run_state_validation_slice.sh` 在 sandbox 里证明 board refresh ledger 会被实际写出。

## 非目标

1. 不把 board refresh event 绑定到单个 work item。
2. 不设计 runtime trace/span/session store。
3. 不引入额外外部 tracing framework。
4. 不在本轮文档里引入新的 shared board path 或组织投影分层。
