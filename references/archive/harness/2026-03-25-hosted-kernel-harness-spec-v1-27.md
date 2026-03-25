# Hosted Kernel Harness Spec v1.27

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-26.md`
- Round focus:
  - bootstrap UX

## Why This Round

到这一步，技术 contract 已较完整，但用户安装体验还没定义。

## Changes In This Version

1. `bootstrap` UX 必须支持两种模式：
   - guided
   - non-interactive
2. guided 模式只问最少信息：
   - provider family
   - profile
   - install mode
3. non-interactive 模式必须可完全重放
4. bootstrap 完成后必须输出：
   - current carrier identity
   - doctor command
   - optional adoption next step

## Locked Principle

bootstrap 体验要轻，但不能牺牲可重放性。

## Residual Risk

1. adoption preview UX 仍未细化
2. local-overrides/profile 还未定界
3. acceptance suite 还未落具体夹具

