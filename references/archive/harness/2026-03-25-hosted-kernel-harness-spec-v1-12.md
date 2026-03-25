# Hosted Kernel Harness Spec v1.12

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-11.md`
- Round focus:
  - `.harness/entrypoint.md` template contract

## Why This Round

`v1.11` 已经确定 repo-local first hop，但还没定义 first hop 本身的最小 contract。

## Changes In This Version

1. `.harness/entrypoint.md` 必须包含 4 段：
   - `Current kernel identity`
   - `Dispatch source`
   - `Fail-closed conditions`
   - `Allowed next actions`
2. `entrypoint.md` 只描述调度与安全边界，不承载完整 kernel prose
3. `entrypoint.md` 的输出必须对三类工具同义：
   - Codex
   - Claude
   - Gemini
4. `entrypoint.md` 失败时只允许路由到：
   - `doctor`
   - `repair`

## Locked Principle

repo-local first hop 必须短、硬、可解析。

## Residual Risk

1. 还没定义 root mirror 的精确 prelude
2. 还没定义 dispatch manifest 字段
3. 还没定义 truth priority 机械校验

