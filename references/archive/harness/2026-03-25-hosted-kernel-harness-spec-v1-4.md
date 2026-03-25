# Hosted Kernel Harness Spec v1.4

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-3.md`
- Round focus:
  - carrier shape

## Why This Round

审计一致指出，单一大 `harness` skill 不符合官方和社区的 skill/plugin 设计习惯。

## Changes In This Version

1. canonical carrier 从：
   - `single global harness skill`
   改为：
   - `provider-native harness distribution`
2. distribution unit 定义为：
   - Claude: plugin
   - Codex / skills.sh: skill collection
3. 对用户仍保留统一品牌 `harness`
4. 内部能力拆成 focused components：
   - `bootstrap`
   - `adopt-entrypoints`
   - `doctor`
   - `update-plan`
   - `update-apply`
   - `repair`

## Locked Principle

`carrier` 应该贴合 provider-native distribution surface，  
而不是强行把生命周期塞进一个 skill。

## Residual Risk

1. 还没有 dispatch manifest
2. 还没有 exact source pinning
3. 还没有 bootstrap / adoption lifecycle 拆分

