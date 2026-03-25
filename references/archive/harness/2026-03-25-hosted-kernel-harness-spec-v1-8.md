# Hosted Kernel Harness Spec v1.8

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-7.md`
- Round focus:
  - compatibility, ownership, migration contracts

## Why This Round

provenance 只回答“装的是谁”。  
它还不能回答：
- 这份 kernel 能不能解释这份 repo state
- 哪些路径由 harness 接管
- adoption 是否完整、可回放

## Changes In This Version

1. 新增 `.harness/compatibility.toml`
2. 新增 `.harness/managed-files.toml`
3. 新增 `.harness/migrations/adoption-index.toml`
4. `compatibility.toml` 记录：
   - `kernel_behavior_contract_version`
   - `state_schema_version`
   - `adoption_contract_version`
   - `minimum_doctor_version`
   - `supported_upgrade_paths`
   - `truth_priority_rules`
5. `managed-files.toml` 记录：
   - `path`
   - `owner`
   - `merge_policy`
   - `checksum`
   - `block_id`
   - `migration provenance`
6. `adoption-index.toml` 记录：
   - 每个 adopted section 的 source/target/hash/redirect metadata

## Locked Principle

`谁接管了什么`、`为什么可兼容`、`这段是怎么迁来的`  
都必须 machine-readable。

## Residual Risk

1. doctor 仍然没有 strict gate
2. update 还没有 plan/apply 分离
3. 还没有 acceptance suite

