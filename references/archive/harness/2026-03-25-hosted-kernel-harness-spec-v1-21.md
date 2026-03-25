# Hosted Kernel Harness Spec v1.21

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-20.md`
- Round focus:
  - `doctor` phases and exit codes

## Why This Round

前面的 contract 已经足够多，不把 `doctor` 做成硬 gate，它们仍然只是静态文档。

## Changes In This Version

1. `doctor` 输出固定 6 段：
   - `presence`
   - `instruction_chain`
   - `identity`
   - `compatibility`
   - `managed_surface_integrity`
   - `migration_integrity`
2. `doctor` 定义明确 exit code：
   - `0`: green
   - `10`: missing carrier
   - `20`: dispatch mismatch
   - `30`: compatibility mismatch
   - `40`: managed surface drift
   - `50`: migration integrity broken
3. `doctor --strict` 失败时必须 fail-closed

## Locked Principle

Hosted Kernel 的安全阀必须可脚本化，不可只靠人类解读输出。

## Residual Risk

1. repair mode 还未定义
2. update plan/apply 还没 gating
3. acceptance suite 还未成文

