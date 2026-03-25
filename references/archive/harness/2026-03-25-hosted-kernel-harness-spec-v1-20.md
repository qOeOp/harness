# Hosted Kernel Harness Spec v1.20

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-19.md`
- Round focus:
  - migration rollback metadata

## Why This Round

adoption-index 现在能记录“迁过什么”，但还不能记录“如何回滚”和“何时需要人工复核”。

## Changes In This Version

1. `adoption-index.toml` 新增：
   - `rollback_source_snapshot`
   - `manual_review_required`
   - `adoption_mode`
   - `coverage_state`
2. 所有 ambiguous section 默认：
   - `manual_review_required = true`
   - 不进入 apply 阶段
3. rollback 只允许回到 migration snapshot，不允许凭空重建 root 原文

## Locked Principle

迁移不是一次性动作，它必须可回放、可解释、可回滚。

## Residual Risk

1. doctor 还没有 phases / exit code
2. repair 还未界定自动化边界
3. update lifecycle 还未细化

