# Hosted Kernel Harness Spec v1.5

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-4.md`
- Round focus:
  - bootstrap vs adoption

## Why This Round

`v1.1` 最大产品化风险之一是：bootstrap 默认就做 section adoption。  
这会把 deterministic scaffold 和语义迁移混成一个高风险动作。

## Changes In This Version

1. `bootstrap` 现在只负责：
   - 初始化 `.harness/`
   - 写 dispatcher / metadata
   - 备份 root entry
   - 插入 root overlay
   - 使 repo 达到 doctor-ready
2. `adopt-entrypoints` 从 bootstrap 中拆出
3. adoption 成为显式第二阶段
4. install 完成不再意味着 project context 已被迁移

## Locked Principle

`bootstrap = deterministic scaffold`
`adoption = semantic migration`

两者不能再混。

## Residual Risk

1. adoption 仍然缺 preview-first 机制
2. truth priority 还没写死
3. section-level classifier 仍然太语义化

