# Worktree-First Parallelism

更新日期：`2026-03-28`

## 收敛结论

本仓库采用：

`task-owned worktrees + one-thread-one-worktree`

而不是：

- 多线程共享同一个工作目录
- 用组织投影子树表达 ownership
- 用一个共享日志文件承接所有并行写入

## 基本规则

1. 一个 thread 对应一个 `git worktree`
2. 一个活跃任务主写一个 worktree
3. canonical docs 和 shared records 需要显式 owner
4. 跨任务协作通过 artifact handoff，不通过随意互改目录

## Branch 命名

推荐：

`codex/<task>-<slug>`

例如：

- `codex/WI-0421-research-routing`
- `codex/WI-0428-runtime-audit`

## Worktree 路径

推荐放在仓库外层：

`../harness-worktrees/<task>-<slug>`

原因：

1. 不污染主仓库
2. 并行线程更容易隔离
3. 便于清理

## Owned Paths

### Canonical source

- `docs/`
- `SKILL.md`
- `roles/`
- `references/contracts/`

这些只能由被明确授权的线程修改。

### Task-local runtime

- `.harness/tasks/<task-id>/`

任务线程默认只写自己的 task record、attachments、closure 与 transitions。

### Shared append-only

- `.harness/workspace/research/sources/`
- `.harness/workspace/research/dispatches/`
- `.harness/workspace/decisions/log/`
- `.harness/workspace/status/snapshots/`

这些目录允许多个线程同时新增文件，但不鼓励频繁改同一个已有文件。

## 跨任务流程

1. 在自己的 task-local 目录完成研究或产出
2. 输出写成 memo / proposal / handoff note
3. 如需进入共享记录面，则新增一条 append-only entry
4. 如需他人响应，则在目标 task 或明确的 shared intake surface 中留痕

## 禁止事项

1. 不要多个 thread 共享同一 worktree
2. 不要让临时执行线程直接重写 canonical docs
3. 不要让多个线程并行编辑同一份总表
