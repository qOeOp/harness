# Hosted Kernel Harness Spec v1.30

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-29.md`
- Round focus:
  - CI / audit / acceptance suite

## Why This Round

前面所有 contract 如果不进 CI 和 acceptance suite，仍然有很大概率在产品化时回退成 trust-based。

## Changes In This Version

1. Hosted Kernel 最小 acceptance suite 固定为 6 类夹具：
   - fresh repo
   - existing pure-project AGENTS
   - mixed-section AGENTS
   - provider-heavy AGENTS
   - version mismatch
   - missing carrier with dispatch
2. CI 必须至少跑：
   - `doctor --instruction-chain`
   - `doctor --strict`
   - bootstrap replay
   - update-plan smoke
3. audit 必须检查：
   - root mirror parity
   - redirect coverage
   - managed-files integrity

## Locked Principle

Hosted Kernel 的 determinism 必须通过夹具和 gate 持续自证。

## Residual Risk

1. final productization boundary 还未收敛
2. dogfood/stable cadence 还需最终定稿
3. 还缺最终综合版

