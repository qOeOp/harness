# Self-Governing Agent Company Harness Spec v2.32

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-31.md`
- Round focus:
  - decision log quality contract

## Why This Round

决策日志是复利核心，但低质量决策日志只会制造噪音。

## Changes In This Version

1. decision entry 最少必须包含 `decision / why / alternatives rejected / implications / next check date`。
2. 缺少 why 的 decision 不允许进入 canonical memory。
3. 决策必须可回指到 work item 与 evidence。

## Locked Principle

决策必须解释因果，不只是记结论。

## Residual Risk

1. 还没定义 revisit cadence
2. 还没定义 stale decision handling
