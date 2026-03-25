# Self-Governing Agent Company Harness Spec v2.48

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-47.md`
- Round focus:
  - dogfood operating model

## Why This Round

trading-agent 作为 dogfood 仓，不能只是“先用一下”，而要成为正式发布轨的一环。

## Changes In This Version

1. 把 dogfood mode 定义成显式 install mode。
2. dogfood 允许更多 telemetry 与 audit，但不改变 core contracts。
3. dogfood release notes 必须回流 release learning loop。

## Locked Principle

dogfood 是提前暴露问题，不是长第二套架构。

## Residual Risk

1. 还没定义 framework-dev mode
2. 还没定义 dogfood rollback drills
