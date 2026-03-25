# Harness Framework Migration Inventory v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Scope:
  - 当前仓内与 `harness-framework` / dogfood layering 直接相关的高价值 artifact

## Framework-Owned Candidates

1. [2026-03-25-hosted-kernel-harness-spec-v1-31.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-31.md)
2. [2026-03-25-self-governing-agent-company-harness-spec-v2-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md)
3. [2026-03-25-evolutionary-hardening-mode-spec-v3-50.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-50.md)
4. [2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md)
5. [2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md)
6. [2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md)
7. [2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-round-telemetry-schema-v1.md)

## Dogfood-Owned Runtime Truth

1. [product-vision.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/product-vision.md)
2. [repo-trust-mode.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/repo-trust-mode.md)
3. future repo-local `.harness/*`
4. `.harness/workspace/state/*`
5. `.harness/workspace/decisions/log/*`
6. `.harness/workspace/status/snapshots/*`
7. trading-specific research / briefs

## Bridge Artifacts

1. [product-vision-refresh-2026-03-25 run](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/runs/product-vision-refresh-2026-03-25/README.md)
2. future dogfood scorecard summaries
3. future dogfood telemetry

## Rule

bridge artifacts 留在 dogfood repo；  
只有其中被提炼出来的 schema、carrier、contract 才迁到 future framework repo。
