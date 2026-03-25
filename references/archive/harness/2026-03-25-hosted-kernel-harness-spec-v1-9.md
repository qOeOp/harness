# Hosted Kernel Harness Spec v1.9

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-8.md`
- Round focus:
  - doctor and repair

## Why This Round

如果 `doctor` 只是 advisory checker，  
那么前面的 provenance / compatibility / ownership contract 仍然只是漂亮文档。

## Changes In This Version

1. `doctor` 升级为 hard verifier
2. `doctor` 必须检查：
   - carrier presence
   - enabled state
   - exact version / commit / digest
   - root overlay integrity
   - `.harness/entrypoint.md` 与 dispatch 一致性
   - managed-files checksum
   - adoption coverage / redirect coverage
   - truth priority 可解析性
3. 核心条件不满足时：
   - fail-closed
   - 仅允许进入 `repair` 或 `update-plan`
4. 新增 `doctor --instruction-chain` 与 `doctor --strict`
5. 新增 minimal acceptance suite：
   - fresh repo
   - existing AGENTS repo
   - version mismatch
   - missing carrier but dispatch exists

## Locked Principle

Hosted Kernel 的安全阀必须是 `doctor`，  
而不是“希望用户环境碰巧正确”。

## Residual Risk

1. update lifecycle 还没拆
2. release channels 还没定义
3. provider parity 还没写成明确 contract

