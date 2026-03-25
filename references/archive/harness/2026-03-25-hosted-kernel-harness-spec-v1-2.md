# Hosted Kernel Harness Spec v1.2

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-24-hosted-kernel-harness-spec-v1-1.md`
- Round focus:
  - repo-local canonical first hop

## Why This Round

`v1.1` 最大问题是 root overlay 的第一跳仍然过度依赖全局 skill。  
这一轮只修一个核心缺口：

`repo 的第一跳必须先落到 repo-local shim，而不是先跳环境里的 harness carrier。`

## Changes In This Version

1. 新增 `.harness/entrypoint.md` 作为 repo-local canonical first hop
2. root `AGENTS.md / CLAUDE.md / GEMINI.md` 的 managed prelude 第一跳统一指向 `.harness/entrypoint.md`
3. `.harness/entrypoint.md` 负责：
   - 声明当前 repo 期望的 harness kernel
   - 指向 `.harness/kernel-dispatch.toml`
   - 在环境不满足要求时 fail-closed
4. root 不再直接写“先使用已安装 harness skill”

## Locked Principle

`Hosted Kernel` 允许 kernel 外置，  
但 canonical instruction chain 不能外置。

## Residual Risk

1. 还没有定义 `kernel-dispatch.toml`
2. 还没有定义 fail-closed 的具体条件
3. 还没有修 bootstrap 和 adoption 混在一起的问题

