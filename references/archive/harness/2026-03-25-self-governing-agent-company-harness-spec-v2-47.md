# Self-Governing Agent Company Harness Spec v2.47

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-46.md`
- Round focus:
  - fixture repos matrix

## Why This Round

工作流是否成立，最后不是看 spec，而是看 fixture。

## Changes In This Version

1. 定义最小 fixture matrix：fresh repo、legacy agent repo、mixed sections、provider-heavy repo、monorepo、drifted repo、broken repo。
2. 每个 lifecycle command 都要在 matrix 上跑 smoke。
3. fixture matrix 成为发布 gate。

## Locked Principle

没有 fixture matrix，就没有产品化 confidence。

## Residual Risk

1. 还没定义 fixture ownership
2. 还没定义 CI runtime budget
