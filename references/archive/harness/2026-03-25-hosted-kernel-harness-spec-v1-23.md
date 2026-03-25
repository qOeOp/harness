# Hosted Kernel Harness Spec v1.23

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-22.md`
- Round focus:
  - `update-plan` contract

## Why This Round

repair 站住之后，剩下最大危险动作就是 update。

## Changes In This Version

1. `update-plan` 必须读取：
   - `kernel-dispatch.toml`
   - `lock.toml`
   - `compatibility.toml`
   - `managed-files.toml`
   - `adoption-index.toml`
2. `update-plan` 必须输出：
   - `identity changes`
   - `compatibility changes`
   - `managed surface diff`
   - `manual review points`
3. `update-plan` 不允许直接写 repo

## Locked Principle

update 的第一步必须是解释变化，不是应用变化。

## Residual Risk

1. `update-apply` 还未 gated
2. release channels 仍未接入
3. provider parity 仍未固定

