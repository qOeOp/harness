# Hosted Kernel Harness Spec v1.15

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-14.md`
- Round focus:
  - adoption ledger and redirect coverage

## Why This Round

truth priority 站住后，仍缺“哪些 section 已被接管”的账本与校验机制。

## Changes In This Version

1. `.harness/migrations/adoption-index.toml` 升级为强制文件
2. 每个 adopted section 必须记录：
   - `section_id`
   - `source_path`
   - `source_heading`
   - `source_checksum`
   - `target_path`
   - `redirect_block_id`
3. `doctor` 必须校验：
   - adoption-index 与 root redirect blocks 一一对应
4. 未进 adoption-index 的 root 正文自动视为 `still-root-canonical`

## Locked Principle

adoption 不是“感觉已经迁了”，而是有 ledger 的结构化事实。

## Residual Risk

1. dispatch metadata 仍未细化
2. provenance lock 仍不足
3. compatibility contract 还没独立定义

