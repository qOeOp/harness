# Self-Governing Agent Company Harness Spec v2.17

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-16.md`
- Round focus:
  - parallel slice windows

## Why This Round

并行不是默认全开，而是按 slice 窗口受控放行。

## Changes In This Version

1. 大任务默认分成 `analysis slice / implementation slice / verification slice`。
2. 仅当 owned_paths 与 expected_outputs 不冲突时才允许同窗并行。
3. integration slice 永远由主线程保留。

## Locked Principle

并行要按 slice 放行，不能把整个项目交给 swarm。

## Residual Risk

1. 还没定义 slice 规模 heuristics
2. 还没定义跨 slice rollback
