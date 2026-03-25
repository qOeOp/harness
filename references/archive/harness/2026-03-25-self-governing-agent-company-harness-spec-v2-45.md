# Self-Governing Agent Company Harness Spec v2.45

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-44.md`
- Round focus:
  - repo entrypoint and mirror parity

## Why This Round

低侵入模型下，root mirror 是唯一直接侵入面，必须压到极硬。

## Changes In This Version

1. root `AGENTS / CLAUDE / GEMINI` 镜像必须保持 parity。
2. overlay prelude 必须带 contract version 与 generated_from。
3. mirror drift 直接触发 doctor failure。

## Locked Principle

侵入面越小，越必须零漂移。

## Residual Risk

1. 还没定义 mirror regeneration command
2. 还没定义 mixed provider repo 的例外
