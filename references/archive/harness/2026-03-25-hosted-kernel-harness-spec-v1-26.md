# Hosted Kernel Harness Spec v1.26

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-25.md`
- Round focus:
  - distribution repo shape

## Why This Round

release channels 有了，但 distribution 本身还只是抽象名词。

## Changes In This Version

1. `harness` 产品层应收敛为：
   - shared core source
   - provider-native packaging
2. Codex/skills.sh 路线：
   - skill collection
3. Claude 路线：
   - plugin
4. 共享内核必须来自同一 source tree，而不是每个 provider 各写一套

## Locked Principle

provider-native packaging 可以不同，kernel source 不能分叉。

## Residual Risk

1. bootstrap UX 还未指定
2. adoption preview UX 还未指定
3. local-overrides/profile 还未定边界

