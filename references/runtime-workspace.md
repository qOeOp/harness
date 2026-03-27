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

Minimum runtime contract:

1. `.harness/manifest.toml`
   - local runtime metadata
2. `.harness/tasks/`
   - task-scoped truth and artifacts
3. `.harness/archive/`
   - closed and compacted task history
4. `.harness/locks/`
   - runtime lock files during controlled state mutation

Canonical minimum-core tree:

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  tasks/
    <task-id>/
      task.md
      progress.md
      refs/
      working/
      outputs/
      closure/
      history/
        transitions/
  archive/
    tasks/
  locks/
```

Machine-readable contract:

1. `references/contracts/minimum-core-runtime-tree.toml`
   - source-repo contract for the generated consumer scaffold

Generation and verification:

1. `./scripts/materialize_runtime_fixture.sh`
   - materializes a consumer sandbox from the pure source repo
2. `./scripts/run_state_validation_slice.sh`
   - proves the generated runtime can execute one end-to-end state chain

This source repository does not own a live `.harness/` tree.
It only defines the minimum runtime contract that consumer repos may materialize on demand.

Heavier structures such as organization trees, cadence artifacts, department workspaces, or governance reports belong to `advanced governance mode`, not to the default task runtime.
