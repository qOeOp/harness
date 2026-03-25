# Hosted Kernel Harness Spec v1.29

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-28.md`
- Round focus:
  - profiles and local overrides

## Why This Round

Hosted Kernel 默认低侵入，就必须明确哪些东西永远属于用户本地，不被 harness 接管。

## Changes In This Version

1. `.harness/local-overrides/` 明确只存：
   - provider-specific local settings
   - user preference fragments
2. `.harness/profile` 只定义 bootstrap/scaffold 预设，不定义运行时真相
3. `doctor` 不得把 local-overrides 视为 drift
4. `update` 不得触碰 local-overrides

## Locked Principle

profile 是预设，override 是本地保留；两者都不等于 kernel truth。

## Residual Risk

1. CI/audit integration 还未固定
2. dogfood rollout 还未写成 release cadence
3. final consolidated product boundary 还未落定

