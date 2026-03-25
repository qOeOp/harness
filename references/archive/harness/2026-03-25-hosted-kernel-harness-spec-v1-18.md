# Hosted Kernel Harness Spec v1.18

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-17.md`
- Round focus:
  - `compatibility.toml` schema

## Why This Round

dispatch / install / lock 只能说明 identity，不能说明“这份 kernel 能否解释这份 repo state”。

## Changes In This Version

1. `compatibility.toml` 最少字段定为：
   - `kernel_behavior_contract_version`
   - `state_schema_version`
   - `adoption_contract_version`
   - `overlay_contract_version`
   - `minimum_doctor_version`
   - `supported_upgrade_paths`
   - `truth_priority_rules`
2. compatibility 负责解释 repo-local state，不负责分发来源
3. breaking change 必须先提升 compatibility contract，再允许 release promotion

## Locked Principle

identity contract 与 behavior contract 必须分离。

## Residual Risk

1. managed-files 仍未足够强
2. migration ledger 还缺 rollback 语义
3. doctor/repair 的执行模式还没定

