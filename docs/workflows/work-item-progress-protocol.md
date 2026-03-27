# Work Item Progress Protocol

更新日期：`2026-03-26`

## 目的

把长回合任务的恢复信息从聊天上下文里剥出来，收敛到 repo-local、可更新、可审计的单独 artifact。

本文件是 progress artifact 的唯一完整协议说明。

默认最小 runtime 下，progress artifact 属于：

1. `.harness/tasks/<task-id>/progress.md`

## 核心原则

1. `progress artifact` 是恢复协议，不是决策本体。
2. `task` 仍然是运行态 source of truth。
3. `progress artifact` 可以更新，但必须挂回对应 work item。
4. 恢复优先读取 `.harness/tasks/<task-id>/progress.md`，而不是回捞整段对话历史。
5. progress 只回答：
   - 当前在做什么
   - 下一条命令是什么
   - 从哪里继续
   - 这一刻对应的状态快照是什么
6. progress writeback 不能因为“补恢复信息”就重定向一个别的、已在执行中的 `.harness/current-task`。

## 存储规则

1. 路径固定为 `.harness/tasks/<task-id>/progress.md`。
2. 一个 task 最多一个 progress 文件。
3. 首次创建时，必须可回链到对应 `.harness/tasks/<task-id>/task.md`。
4. 当前实现仍推荐通过 `./scripts/upsert_work_item_progress.sh` 写入。

## 何时必须创建或刷新

1. task 进入 `in-progress` 后，如果不会在同一轮自然收口，应创建 progress artifact。
2. 当前会话准备结束、但任务仍处于 `in-progress` 时，应刷新 progress artifact。
3. task 的状态、版本或最近操作已变化，导致 progress snapshot 落后时，应刷新 progress artifact。
4. 若当前实现里的 opener 或 starter 显示：
   - `Progress sync state: missing`
   - `Progress sync state: stale`
   - `Progress sync state: unlinked`
   则先修复 progress，再继续执行。

## 最小字段

progress artifact 至少记录：

1. `Task ID`
2. `Current focus`
3. `Next command`
4. `Recovery notes`
5. `Status snapshot`
6. `Updated at`

扩展字段只有在当前实现确实需要时才保留，例如：

1. `State version snapshot`
2. `Last operation ID snapshot`

## 推荐操作

当前实现里，首次创建或未链接时：

```bash
./scripts/upsert_work_item_progress.sh --expected-version <state-version> <task-id> "<current-focus>" "<next-command>" "[recovery-notes]"
```

已存在但需要刷新时：

```bash
./scripts/upsert_work_item_progress.sh <task-id> "<current-focus>" "<next-command>" "[recovery-notes]"
```

## 入口工作流

1. `/harness`
   - 若判断任务会跨回合，则 materialize `.harness/tasks/<task-id>/progress.md`
2. `harness status`
   - 应显示是否存在 progress、是否 stale、当前 focus、下一条命令
3. `harness resume`
   - 恢复时优先展开 progress 文件，而不是去聊天历史里“捞上下文”
4. 当前内部实现仍可通过以下脚本支撑：
   - `./scripts/open_current_work_item.sh`
   - `./scripts/start_work_item.sh`
   - `./scripts/sweep_state_drift.sh`
   - `./scripts/run_state_validation_slice.sh`

## 与 Task 文件的边界

1. `.harness/tasks/<task-id>/task.md`
   - 负责任务身份、状态、目标、约束与 artifact links
2. `.harness/tasks/<task-id>/progress.md`
   - 只负责恢复协议

progress 文件不得偷偷变成：

1. 第二个 task source of truth
2. research memo
3. decision log
4. narrative diary

## 禁止事项

1. 不要把 progress artifact 当作正式 decision / research / snapshot artifact。
2. 不要把大量 narrative 塞回 progress 文件，导致它重新变成迷你日志。
3. 不要在 progress artifact 里偷偷维护与 task 冲突的状态字段。
4. 不要因为有 progress artifact 就跳过正式 state transition。
5. 不要把 `ready` / `review` task 的 progress writeback 当成“抢占当前执行焦点”的手段。
