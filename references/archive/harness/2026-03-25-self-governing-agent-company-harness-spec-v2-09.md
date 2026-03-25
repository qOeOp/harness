# Self-Governing Agent Company Harness Spec v2.9

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-08.md`
- Round focus:
  - snapshot and replay contract

## Why This Round

要验证 agent 是否真的能独立完成大任务，必须能从 journal 重建状态。

## Changes In This Version

1. 定义 `snapshot` 为 source state 的 point-in-time materialization。
2. 定义 `replay` 为 journal 重演到目标版本。
3. 任何 projection 差异都必须能通过 replay 解释。

## Locked Principle

不能 replay 的状态，不算真实状态。

## Residual Risk

1. 还没定义 snapshot cadence
2. 还没定义 replay failure diagnostics
