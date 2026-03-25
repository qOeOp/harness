# Hosted Kernel Harness Spec v1.14

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-13.md`
- Round focus:
  - truth priority contract

## Why This Round

Hosted Kernel 只要保留 root 未接管正文，就必须把谁是最终真相写成 machine-readable contract。

## Changes In This Version

1. 新增 `truth_priority_rules` 为一等 contract
2. adopted section 的优先级固定为：
   - `project-context > root redirect block`
3. 未 adopted section 的优先级固定为：
   - `root original body > no-op redirect`
4. append-only `decision / brief / state / log` 的优先级不得被 root entry 覆盖

## Locked Principle

只要允许多处承载语义，就必须显式写出单向优先级链。

## Residual Risk

1. 还没定义 adopted section ledger
2. 还没定义 redirect coverage 校验
3. adoption 仍缺 preview UX

