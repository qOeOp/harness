# Self-Governing Agent Company Harness Spec v2.44

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-43.md`
- Round focus:
  - local-overrides stratification

## Why This Round

定制必须有出口，但 overrides 不能变成第二套世界。

## Changes In This Version

1. 把 local-overrides 拆成 `provider-overrides / project-local-not-adopted / operator-local` 三层。
2. 每层定义不同 truth priority。
3. overrides 不得直接覆盖 kernel contracts。

## Locked Principle

定制要分层，不能一股脑塞 overrides。

## Residual Risk

1. 还没定义 override conflict resolution
2. 还没定义 stale override detection
