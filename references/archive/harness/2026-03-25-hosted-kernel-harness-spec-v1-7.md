# Hosted Kernel Harness Spec v1.7

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-6.md`
- Round focus:
  - provenance and dispatch contract

## Why This Round

Hosted Kernel 最大弱点不是“kernel 在外面”，而是“外面那份 kernel 究竟是哪一份”说不清。

## Changes In This Version

1. 新增 `.harness/kernel-dispatch.toml`
2. 新增 `.harness/install.toml`
3. 新增 `.harness/lock.toml`
4. `kernel-dispatch.toml` 最少记录：
   - `distribution_source`
   - `distribution_kind`
   - `collection_or_plugin_id`
   - `required_components`
   - `exact_version_or_commit`
   - `content_digest`
   - `expected_enabled_state`
5. `install.toml` 记录：
   - 实际安装来源
   - 安装时间
   - profile
   - install mode
6. `lock.toml` 记录：
   - repo 当前锁定的 harness identity
   - compatibility range

## Locked Principle

Hosted Kernel 必须从 trust-based 变成 provenance-based。

## Residual Risk

1. 还没有 compatibility contract
2. 还没有 managed-files ownership
3. doctor 仍然没有被提升成 hard verifier

