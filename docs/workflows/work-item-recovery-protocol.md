# Work Item Recovery Protocol

更新日期：`2026-03-27`

## 目的

把长回合任务的恢复信息从聊天上下文里剥出来，收敛到 repo-local、可更新、可审计的单一 task record。

说明：

1. 正式命令是 `upsert_work_item_recovery.sh`
2. 它写的是 `task.md` 的 `## Recovery`
3. Recovery 是默认 runtime contract 的一部分

## 核心原则

1. Recovery 是恢复协议，不是决策本体。
2. `task.md` 仍然是运行态 source of truth。
3. Recovery 可以更新，但不能制造第二套状态。
4. 恢复优先读取 `task.md` 的 `## Recovery`，而不是回捞整段聊天历史。
5. Recovery 只回答：
   - 当前在做什么
   - 下一条命令是什么
   - 从哪里继续
6. 等待 human approval / review / feedback 跨 session 时，先 pause 再写 Recovery，不要把恢复协议伪装成隐藏等待态

## 存储规则

1. 路径固定为 `.harness/tasks/<task-id>/task.md`
2. section 固定为 `## Recovery`
3. 一个 task 最多一组当前 Recovery 字段
4. 当前实现推荐通过 [upsert_work_item_recovery.sh](/Users/vx/WebstormProjects/harness/scripts/upsert_work_item_recovery.sh) 写入

## 最小字段

Recovery 至少记录：

1. `Current focus`
2. `Next command`
3. `Recovery notes`

这些字段应是短、硬、可执行的恢复信息，而不是 narrative 日志。

## 何时必须创建或刷新

1. task 进入 `in-progress` 后，如果不会在同一轮自然收口，应写 Recovery
2. 当前会话准备结束、但任务仍处于 `in-progress` 或 `paused` 时，应刷新 Recovery
3. 当前 focus 或下一条命令已变化时，应刷新 Recovery
4. opener / starter 若显示 `Recovery sync state: missing`，应先补 Recovery 再继续
5. 任务因 Founder / manual / risk review 进入 `paused` 后，应把 resume 命令和恢复条件刷进 `## Recovery`

## 推荐操作

```bash
./scripts/upsert_work_item_recovery.sh <task-id> "<current-focus>" "<next-command>" "[recovery-notes]"
```

若调用方想做并发保护，也可以继续传：

```bash
./scripts/upsert_work_item_recovery.sh --expected-version <state-version> <task-id> "<current-focus>" "<next-command>" "[recovery-notes]"
```

## 与 Task 文件的边界

同一个 `task.md` 内：

1. header
   - 负责任务身份、状态、claim、route、gate、attachment links
2. `## Recovery`
   - 只负责恢复协议

Recovery 不得偷偷变成：

1. 第二个 task source of truth
2. research memo
3. decision log
4. 长篇 narrative diary

## 禁止事项

1. 不要在 Recovery 里维护与 header 冲突的状态字段
2. 不要因为写 Recovery 就跳过正式 state transition
