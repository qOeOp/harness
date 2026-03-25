# Hosted Kernel Harness Spec v1.10

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-9.md`
- Round focus:
  - update lifecycle and release channels

## Why This Round

bootstrap 和 doctor 站住以后，剩下最大的产品化风险就是 update。  
Hosted Kernel 的真实复杂度，集中在升级链路。

## Changes In This Version

1. `update` 强制拆成：
   - `update-plan`
   - `update-apply`
2. `update-plan` 必须读取：
   - `kernel-dispatch.toml`
   - `lock.toml`
   - `compatibility.toml`
   - `managed-files.toml`
   - `adoption-index.toml`
3. `update-apply` 只允许在：
   - `doctor --strict` 通过
   - 或明确 repair 完成
   的前提下运行
4. release channels 定义为：
   - `stable`
   - `canary`
   - `dogfood`
5. `trading-agent` 默认吃 `dogfood/canary`
6. consumer repos 默认只吃 `stable`

## Locked Principle

Hosted Kernel 不是“随时升级的全局 skill”，  
而是“有 release identity、兼容性门和计划阶段的外部分发内核”。

## Residual Risk

1. 还缺 final consolidated wording
2. provider-specific naming 还没完全统一
3. 还缺最终产品化口径

