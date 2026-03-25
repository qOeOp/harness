# Self-Governing Agent Company Harness Spec v2.14

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-13.md`
- Round focus:
  - work package contract

## Why This Round

分解之后，如果交给 worker 的包仍然模糊，组织不会真正提效。

## Changes In This Version

1. 定义 work package 最小字段：`scope / owned_paths / expected_output / verification / stop_conditions`。
2. 没有 owned_paths 的包不允许并行委派。
3. 主线程必须保留 integration ownership。

## Locked Principle

委派必须带 ownership，不允许“你去看一下”。

## Residual Risk

1. 还没定义 exploration-only package
2. 还没定义 work package 模板库
