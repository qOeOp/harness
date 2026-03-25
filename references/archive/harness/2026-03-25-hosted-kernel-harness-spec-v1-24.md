# Hosted Kernel Harness Spec v1.24

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-23.md`
- Round focus:
  - `update-apply` gate

## Why This Round

有 plan 还不够，如果 `apply` 仍然不受 gate 约束，Hosted Kernel 还是会在升级时越权。

## Changes In This Version

1. `update-apply` 只允许在：
   - `doctor --strict` green
   - 或显式 repair 完成
   时运行
2. `update-apply` 只能修改：
   - `managed-files.toml` 声明的受管区域
   - declared runtime schema scaffolds
3. `update-apply` 必须在写入前复核 digest 和 compatibility

## Locked Principle

apply 不是能力，是被 gate 住的受限动作。

## Residual Risk

1. release channels 仍未锁定
2. provider-native distribution 仍未细化
3. UX 仍未收敛

