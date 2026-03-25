# Hosted Kernel Harness Spec v1.19

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-18.md`
- Round focus:
  - `managed-files.toml` ownership and merge policy

## Why This Round

Hosted Kernel 能否安全 update，核心不在 version，而在“哪些路径归 harness 管、哪些不归”。

## Changes In This Version

1. `managed-files.toml` 最少字段定为：
   - `path`
   - `owner`
   - `source_kind`
   - `source_ref`
   - `merge_policy`
   - `checksum`
   - `block_id`
2. merge policy taxonomy 收敛为：
   - `replace_if_clean`
   - `plan_if_modified`
   - `never_touch`
   - `append_only`
3. root managed prelude / redirect blocks 必须在 managed-files 中登记
4. `workspace` 下 append-only 资产必须默认 `never_touch` 或 `append_only`

## Locked Principle

没有 ownership contract，就没有安全 update。

## Residual Risk

1. migration rollback 仍未定义
2. doctor strictness 还没落到 exit code
3. update plan/apply 还没展开

