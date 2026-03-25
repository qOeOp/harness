# Hosted Kernel Harness Spec v1.13

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-12.md`
- Round focus:
  - root mirror overlay contract

## Why This Round

entrypoint 有了，但 root `AGENTS.md / CLAUDE.md / GEMINI.md` 仍然缺少 machine-checkable overlay contract。

## Changes In This Version

1. root mirror 的 managed prelude 必须带：
   - `block_id`
   - `contract_version`
   - `generated_from`
2. 三份 root mirror 必须保持语义同义，只允许 provider label 不同
3. overlay 的唯一职责是把工具引到 `.harness/entrypoint.md`
4. root prelude 后方的未接管正文必须被明确视为 `unmanaged body`

## Locked Principle

root overlay 只能承担 discovery，不承担 kernel semantics。

## Residual Risk

1. 还没把 truth priority 写成合同
2. 还没定义 redirect block 的格式
3. 还没纳入 parity audit

