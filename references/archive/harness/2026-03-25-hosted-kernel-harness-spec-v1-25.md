# Hosted Kernel Harness Spec v1.25

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-24.md`
- Round focus:
  - release channels

## Why This Round

Hosted Kernel 的真正危险不只是 update 本身，而是错误的 release 被 consumer repo 吸收。

## Changes In This Version

1. release channels 固定为：
   - `dogfood`
   - `canary`
   - `stable`
2. `trading-agent` 默认只消费：
   - `dogfood`
   - `canary`
3. consumer repo 默认只允许：
   - `stable`
4. `latest`、分支名、浮动 ref 在生产 consumer repo 默认禁用

## Locked Principle

少侵入不等于随便漂移，Hosted Kernel 仍需要保守 release discipline。

## Residual Risk

1. provider-native distribution 结构仍未定
2. bootstrap UX 还未定
3. local-overrides/profile 还未收紧

