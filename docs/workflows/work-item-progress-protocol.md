# Work Item Progress Protocol

更新日期：`2026-03-23`

## 目的

把长回合任务的恢复信息从聊天上下文里剥出来，收敛到 repo-local、可更新、可审计的单独 artifact。

本文件是 progress artifact 的唯一完整协议说明。

`.harness/workspace/state/README.md` 只负责状态层总览。
`.harness/workspace/state/progress/README.md` 只负责目录局部约束。

## 核心原则

1. `progress artifact` 是恢复协议，不是决策本体。
2. `work item` 仍然是运行态 source of truth。
3. `progress artifact` 可以更新，但必须挂回对应 work item。
4. 恢复优先读取 `.harness/workspace/state/progress/WI-xxxx.md`，而不是回捞整段对话历史。
5. progress 只回答：
   - 当前在做什么
   - 下一条命令是什么
   - 从哪里继续
   - 这一刻对应的状态快照是什么

## 存储规则

1. 路径固定为 `.harness/workspace/state/progress/WI-xxxx.md`。
2. 一个 work item 最多一个 progress 文件。
3. 首次创建时，必须以 `progress-artifact|active` 链接到对应 work item。
4. 推荐统一通过 `./.agents/skills/harness/scripts/upsert_work_item_progress.sh` 写入。

## 何时必须创建或刷新

1. work item 进入 `in-progress` 后，如果不会在同一轮自然收口，应创建 progress artifact。
2. 当前会话准备结束、但任务仍处于 `in-progress` 时，应刷新 progress artifact。
3. work item 的状态、版本或最近操作已变化，导致 progress snapshot 落后时，应刷新 progress artifact。
4. 若 `./.agents/skills/harness/scripts/open_current_work_item.sh` 或 `./.agents/skills/harness/scripts/start_work_item.sh` 显示：
   - `Progress sync state: missing`
   - `Progress sync state: stale`
   - `Progress sync state: unlinked`
   则先修复 progress，再继续执行。

## 最小字段

progress artifact 至少记录：

1. `Current focus`
2. `Next command`
3. `Recovery notes`
4. `Status snapshot`
5. `State version snapshot`
6. `Last operation ID snapshot`
7. `Updated at`

## 推荐操作

首次创建或未链接时：

```bash
./.agents/skills/harness/scripts/upsert_work_item_progress.sh --expected-version <state-version> WI-xxxx "<current-focus>" "<next-command>" "[recovery-notes]"
```

已存在但需要刷新时：

```bash
./.agents/skills/harness/scripts/upsert_work_item_progress.sh WI-xxxx "<current-focus>" "<next-command>" "[recovery-notes]"
```

## 入口工作流

1. `./.agents/skills/harness/scripts/open_current_work_item.sh`
   - 展开当前 actionable work item
   - 同时显示 progress 路径、同步状态、当前 focus、下一条命令
2. `./.agents/skills/harness/scripts/start_work_item.sh`
   - 把 `ready` 项推进到 `in-progress`
   - 然后提示是否需要创建或刷新 progress artifact
3. `./.agents/skills/harness/scripts/sweep_state_drift.sh`
   - 报告 `in-progress` 项缺失、未链接或已过期的 progress artifact
4. `./.agents/skills/harness/scripts/run_state_validation_slice.sh`
   - 在 sandbox 里验证 progress protocol 是否真正能跑通

## 禁止事项

1. 不要把 progress artifact 当作正式 decision / research / snapshot artifact。
2. 不要把大量 narrative 塞回 progress 文件，导致它重新变成迷你日志。
3. 不要在 progress artifact 里偷偷维护与 work item 冲突的状态字段。
4. 不要因为有 progress artifact 就跳过正式 state transition。
