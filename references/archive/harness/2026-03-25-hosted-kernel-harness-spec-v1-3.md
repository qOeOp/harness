# Hosted Kernel Harness Spec v1.3

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-2.md`
- Round focus:
  - two-stage root overlay and fail-closed entry

## Why This Round

有了 repo-local first hop 还不够。  
如果 `.harness/entrypoint.md` 只是继续“温和提醒去找 skill”，那 determinism 仍然不够。

## Changes In This Version

1. root overlay 改成两段式：
   - 第一段：声明 canonical entry 在 `.harness/entrypoint.md`
   - 第二段：只有 entrypoint 校验通过后，才允许进一步调用 hosted kernel
2. `.harness/entrypoint.md` 明确：
   - 缺 carrier / 版本不符 / digest 不符时，必须 fail-closed
   - 失败时只允许进入 `doctor` 或 `repair`
3. root overlay 不再承担 kernel 解释逻辑，只承担 discovery

## Locked Principle

`发现入口` 与 `调用外部 kernel` 必须拆开。

## Residual Risk

1. 还没有 machine-readable dispatch metadata
2. 还没有 version/provenance contract
3. 还没有限制 monolithic carrier

