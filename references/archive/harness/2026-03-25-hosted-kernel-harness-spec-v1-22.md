# Hosted Kernel Harness Spec v1.22

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-21.md`
- Round focus:
  - repair boundaries

## Why This Round

`doctor` fail-closed 以后，如果没有 repair 边界，系统就只会报错，不会恢复。

## Changes In This Version

1. `repair` 只允许自动修复：
   - 缺失的 generated prelude
   - 缺失的 `.harness/entrypoint.md`
   - 可重建的 dispatch/lock/install metadata
2. `repair` 不允许自动修复：
   - adoption misclassification
   - user-modified unmanaged body
   - append-only state corruption
3. `repair` 所有写入必须先输出 repair plan

## Locked Principle

repair 只能修 deterministic shell，不能替用户重写语义。

## Residual Risk

1. update workflow 还未完成
2. acceptance suite 还未指定夹具
3. release channels 还未接入

