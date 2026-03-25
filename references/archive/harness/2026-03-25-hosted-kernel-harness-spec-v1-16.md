# Hosted Kernel Harness Spec v1.16

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-15.md`
- Round focus:
  - `kernel-dispatch.toml` schema boundary

## Why This Round

entrypoint 已经稳定，但还没有足够清晰地区分：
- dispatch metadata
- install facts
- lock identity

## Changes In This Version

1. `kernel-dispatch.toml` 只负责当前 repo 如何解析 harness carrier
2. `kernel-dispatch.toml` 最少字段定为：
   - `provider_family`
   - `distribution_kind`
   - `distribution_source`
   - `carrier_id`
   - `required_components`
   - `exact_ref`
   - `content_digest`
   - `enabled_expectation`
3. dispatch 不再承载 compatibility 或 install history
4. dispatch 的解析结果必须可被 `doctor --instruction-chain` 单独验证

## Locked Principle

dispatch 只回答“去哪里、用什么、必须是什么版本”。

## Residual Risk

1. install/lock 边界还没写死
2. compatibility 仍未成文
3. managed-files 还未细化 owner/merge policy

