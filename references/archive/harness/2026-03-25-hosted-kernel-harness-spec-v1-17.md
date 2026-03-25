# Hosted Kernel Harness Spec v1.17

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-16.md`
- Round focus:
  - `install.toml` vs `lock.toml`

## Why This Round

dispatch 解决了“如何解析”，但 Hosted Kernel 还需要把“实际装了什么”和“repo 锁定什么”分开。

## Changes In This Version

1. `install.toml` 固定记录实际安装事实：
   - `installed_from`
   - `installed_at`
   - `installed_identity`
   - `profile`
   - `mode`
2. `lock.toml` 固定记录 repo 期望锁：
   - `source_repo_or_url`
   - `carrier_type`
   - `release_tag`
   - `exact_version_or_commit`
   - `artifact_hash`
   - `required_component_ids`
3. `install.toml` 与 `lock.toml` 差异必须由 `doctor` 报告

## Locked Principle

`实际装了什么` 和 `repo 应该依赖什么` 不能混成一个文件。

## Residual Risk

1. compatibility contract 仍未细化
2. managed-files 仍未定义 merge policy taxonomy
3. repair path 还没明确

