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
   - runtime lock files during controlled state mutation

Harness-owned surface in a consumer repo:

1. `.harness/`

Out of scope for the default runtime contract:

1. skill installation path
2. consumer `AGENTS.md / CLAUDE.md / GEMINI.md`
3. consumer `.claude/ / .codex/ / .gemini/`
4. advanced governance role trees such as `.harness/workspace/roles/`

## Canonical task-record tree

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
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
5. board 不是默认 runtime tree 的一部分

Machine-readable contract:

1. [task-record-runtime-tree-v2.toml](/Users/vx/WebstormProjects/harness/references/contracts/task-record-runtime-tree-v2.toml)

Generation and verification:

1. [materialize_runtime_fixture.sh](/Users/vx/WebstormProjects/harness/scripts/materialize_runtime_fixture.sh)
2. [run_state_validation_slice.sh](/Users/vx/WebstormProjects/harness/scripts/run_state_validation_slice.sh)
3. [validate_workspace.sh](/Users/vx/WebstormProjects/harness/scripts/validate_workspace.sh)
4. [audit_state_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_state_system.sh)

This source repository does not own a live `.harness/` tree.
It only defines the runtime contract that consumer repos may materialize on demand.

Heavier structures such as department workspaces, cadence artifacts, governance reports, or organization role projections belong to `advanced governance mode`, not to the default task runtime.
