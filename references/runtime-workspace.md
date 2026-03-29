# Runtime Workspace

Canonical runtime root in any consumer repo:

`.harness/`

The runtime is lazily materialized.

It should appear only when a task needs:

1. cross-session recovery
2. explicit task tracking
3. reviewable artifacts
4. decision or evidence writeback
5. resumable local truth beyond the current chat

## Minimum runtime contract

1. `.harness/manifest.toml`
   - local runtime metadata
2. `.harness/tasks/`
   - flat task-record truth and task-local artifacts
3. `.harness/locks/`
   - runtime lock leases during controlled state mutation
   - lock dir metadata should carry `owner`、`claimed_at`、`lease_expires_at`、`lease_id` 与 `pid`
   - stale reclaim 以 `lease_expires_at` 过期或 pid 已死为准

Harness-owned surface in a consumer repo:

1. `.harness/`

Out of scope for the default runtime contract:

1. skill installation path
2. consumer `AGENTS.md / CLAUDE.md / GEMINI.md`
3. consumer `.claude/ / .codex/ / .gemini/`
4. company / workstream trees, boards, digests, or founder queues
5. provider background / pollable transport
   所依赖的 provider-side stored state
   仍属于 transport state，
   不是 canonical task truth，
   也不应被默认当成
   zero-retention / ZDR-safe 前提

Implementation-owned support state may still live under `.harness/` when needed.

Recommended non-canonical support root:

1. `.harness/runtime/`
   - caches, tool homes, isolated adapter environments, and other operational support state
   - not canonical task truth
   - not a default reading surface for normal task recovery
   - any durable serialized state there must carry explicit schema / format version
   - cross-version restore must migrate or fail closed

## Canonical task-record tree

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  runtime/
  tasks/
    <task-id>/
      task.md
      attachments/
      closure/
      history/
        transitions/
  locks/
```

关键点：

1. `task.md` 是唯一任务真相
2. `## Recovery` 在 `task.md` 内
3. task-local decision / research / review / source-note 默认进入 `attachments/`
4. `archived` 通过状态字段表达，不再默认要求物理 `archive/`
5. board、digest、org chart 不属于默认 runtime tree
6. slow human approval / review / feedback 默认应 materialize 为 `paused` + resume transition，而不是隐藏的 waiting state
7. `interrupt / resume` 默认是 checkpoint-relative re-entry，
   不是 instruction-pointer continuation；
   边界前的外部副作用应有 idempotency 或 effect fence
8. webhook、queue、async callback 这类外部 wakeup 默认按 at-least-once delivery 设计，恢复链路应带 dedupe / idempotency key，不把活着的 socket / stream 当成 contract
9. 跨 run wait 默认应记录 wakeup handle + deadline / expiry；审批、中断与 async callback 应带 stable operation id 与 version marker，resume 按 ID 配对
10. 若底层 protocol 已返回 task object / background handle，例如 `task_id`、poll interval、stream cursor 或 cancel handle，默认复用这些 receiver-generated handle，不另造 shadow polling state
11. `in-progress` / `paused` task 默认应带显式 claim lease：
   `Assignee`、`Worktree`、`Claimed at`、`Claim expires at`、`Lease version`
12. `.harness/locks/` 负责短生命周期 mutation guard；
    `task.md` 头部 claim 字段负责 task-level claim snapshot，
    两者不能互相替代

Machine-readable contract:

1. [task-record-runtime-tree-v2.toml](/Users/vx/WebstormProjects/harness/references/contracts/task-record-runtime-tree-v2.toml)

Generation and verification:

1. [materialize_runtime_fixture.sh](/Users/vx/WebstormProjects/harness/scripts/materialize_runtime_fixture.sh)
2. [run_state_validation_slice.sh](/Users/vx/WebstormProjects/harness/scripts/run_state_validation_slice.sh)
3. [validate_workspace.sh](/Users/vx/WebstormProjects/harness/scripts/validate_workspace.sh)
4. [audit_state_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_state_system.sh)

This source repository does not own a live `.harness/` tree.
It only defines the runtime contract that consumer repos may materialize on demand.

Shared writeback surfaces such as `research/dispatches/`, `research/sources/`, `decisions/log/`, or `status/snapshots/` are secondary surfaces, not the default task runtime.
