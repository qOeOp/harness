# Hosted Kernel Harness Spec v1.28

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-27.md`
- Round focus:
  - adoption preview UX

## Why This Round

adoption 已经不是默认 bootstrap 了，但如果 preview UX 模糊，仍然难以安全落地。

## Changes In This Version

1. adoption preview 必须输出 4 段：
   - `sections to adopt`
   - `sections left in root`
   - `ambiguous sections requiring manual review`
   - `resulting truth-priority changes`
2. adoption apply 前必须明确给出 redirect coverage diff
3. manual-review-required section 默认不进入 apply

## Locked Principle

对 adoption 来说，最重要的不是“自动化多强”，而是“用户能否看懂将发生什么”。

## Residual Risk

1. local-overrides/profile 还未写成 contract
2. CI/audit integration 还没固定
3. dogfood rollout 还未明示

