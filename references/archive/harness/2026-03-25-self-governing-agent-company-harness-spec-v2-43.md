# Self-Governing Agent Company Harness Spec v2.43

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-42.md`
- Round focus:
  - profile system and inheritance

## Why This Round

不同仓库需要不同组织强度，但 profile 不能演变成复制粘贴模板。

## Changes In This Version

1. 把 profile 定义成 first-class object。
2. profile 支持 `base + overlays` 继承。
3. profile 只影响 seed/threshold/cadence，不改变核心 contracts。

## Locked Principle

profile 可以改变形态，不能改变物理定律。

## Residual Risk

1. 还没定义 profile registry
2. 还没定义 profile diff UX
