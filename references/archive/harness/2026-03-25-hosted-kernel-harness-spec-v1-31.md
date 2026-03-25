# Hosted Kernel Harness Spec v1.31

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-locked snapshot
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-11.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-12.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-13.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-14.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-15.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-16.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-17.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-18.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-19.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-20.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-21.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-22.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-23.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-24.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-25.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-26.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-27.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-28.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-29.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-30.md`
- Purpose:
  1. 在保留 Hosted Kernel 低侵入方向的前提下，把 `v1.11` 后 20 轮 hardening 的结果整合成当前最高确定性的 consumer-repo 方案。
  2. 为下一步 schema 落地、distribution 仓组织、dogfood rollout 提供稳定基线。

## Divergent Hypotheses

1. `停在 v1.11`
   - 已经修掉最明显的问题，但 schema、UX、CI、profile、dogfood cadence 还偏粗。
2. `退回 Vendored Kernel`
   - 自包含更强，但仍然违反 Founder 当前锁定的低侵入优先级。
3. `继续保留 Hosted Kernel，并把它完全产品化为 contract-first system`
   - repo-local first hop
   - provider-native carrier
   - deterministic scaffold
   - preview-first semantic adoption
   - strict provenance/compatibility/ownership contracts
   - CI/audit-backed determinism

## First Principles Deconstruction

1. 当前最高约束仍然是 `少侵入`
2. 但少侵入不能用以下四件事交换：
   - repo-local deterministic first hop
   - machine-readable ownership and compatibility
   - conservative migration semantics
   - hard-gated upgrade lifecycle
3. 因此最终方案不是“更少文件”，而是“更少侵入 + 更强合同”

## Convergence To Excellence

采纳第 3 条路线，正式定义：

`Hosted Kernel Harness v1.31`

## Canonical Model

Hosted Kernel Harness v1.31 的定义是：

1. kernel source 不默认 vendoring 到 consumer repo
2. consumer repo 保留 repo-local deterministic dispatcher
3. carrier 必须按 provider-native distribution 形式分发
4. repo-local `.harness/` 只承载：
   - dispatcher / metadata contracts
   - project context
   - append-only runtime assets
   - local overrides
   - migration ledgers

## Carrier

canonical distribution model：

1. `harness` 是统一产品品牌
2. provider-native carrier：
   - Claude plugin
   - Codex / skills.sh skill collection
3. 内部 focused components：
   - `harness-bootstrap`
   - `harness-adopt-entrypoints`
   - `harness-doctor`
   - `harness-update-plan`
   - `harness-update-apply`
   - `harness-repair`

carrier 原则：

1. provider-native packaging 可以不同
2. shared core source 不能分叉
3. consumer repo 默认只锁 immutable release identity

## Repo-Local First Hop

canonical instruction chain：

1. root `AGENTS.md / CLAUDE.md / GEMINI.md`
2. `.harness/entrypoint.md`
3. `.harness/kernel-dispatch.toml`
4. provider-native `harness` carrier
5. `.harness/workspace/current/project-context.md`
6. `.harness/workspace/briefs|decisions|state|logs`

root overlay contract：

1. root 只插入 harness-managed prelude
2. prelude 必须带：
   - `block_id`
   - `contract_version`
   - `generated_from`
3. root 只负责 discovery，不负责 kernel semantics
4. root 未被接管正文默认保留为 `unmanaged body`

`.harness/entrypoint.md` contract：

1. 必须包含：
   - `Current kernel identity`
   - `Dispatch source`
   - `Fail-closed conditions`
   - `Allowed next actions`
2. 只描述 dispatch 与安全边界
3. 不承载完整 kernel prose

## Repo-Local `.harness/` Layout

```text
.harness/
  entrypoint.md
  kernel-dispatch.toml
  install.toml
  lock.toml
  compatibility.toml
  managed-files.toml
  workspace/
    current/project-context.md
    briefs/
    decisions/
    state/
    logs/
  .harness/workspace/departments/
  agents/
  local-overrides/
  migrations/
    adoption-index.toml
```

语义边界：

1. `entrypoint.md`
   - repo-local first hop
2. `kernel-dispatch.toml`
   - 当前 repo 应如何解析 harness carrier
3. `install.toml`
   - 实际安装事实
4. `lock.toml`
   - repo 当前锁定的 harness identity
5. `compatibility.toml`
   - behavior/schema/truth-priority contract
6. `managed-files.toml`
   - ownership 与 merge policy
7. `.harness/workspace/current/project-context.md`
   - adopted project truth
8. `.harness/workspace/briefs|decisions|state|logs`
   - append-only runtime assets
9. `local-overrides`
   - provider/user-local fragments
10. `migrations/adoption-index.toml`
   - adoption ledger and rollback metadata

## Schema Contracts

### `kernel-dispatch.toml`

必须记录：

1. `provider_family`
2. `distribution_kind`
3. `distribution_source`
4. `carrier_id`
5. `required_components`
6. `exact_ref`
7. `content_digest`
8. `enabled_expectation`

### `install.toml`

必须记录：

1. `installed_from`
2. `installed_at`
3. `installed_identity`
4. `profile`
5. `mode = hosted-kernel`

### `lock.toml`

必须记录：

1. `source_repo_or_url`
2. `carrier_type`
3. `release_tag`
4. `exact_version_or_commit`
5. `artifact_hash`
6. `required_component_ids`
7. `compatibility_range`

### `compatibility.toml`

必须记录：

1. `kernel_behavior_contract_version`
2. `state_schema_version`
3. `adoption_contract_version`
4. `overlay_contract_version`
5. `minimum_doctor_version`
6. `supported_upgrade_paths`
7. `truth_priority_rules`

### `managed-files.toml`

必须记录：

1. `path`
2. `owner`
3. `source_kind`
4. `source_ref`
5. `merge_policy`
6. `checksum`
7. `block_id`

merge policy taxonomy 固定为：

1. `replace_if_clean`
2. `plan_if_modified`
3. `never_touch`
4. `append_only`

### `adoption-index.toml`

必须记录：

1. `section_id`
2. `source_path`
3. `source_heading`
4. `source_checksum`
5. `target_path`
6. `redirect_block_id`
7. `rollback_source_snapshot`
8. `manual_review_required`
9. `coverage_state`

## Bootstrap

`bootstrap` 只做 deterministic scaffold：

1. 解析并安装匹配的 provider-native carrier
2. 初始化 `.harness/`
3. 写 `entrypoint.md`
4. 写 `kernel-dispatch.toml`
5. 写 `install.toml`
6. 写 `lock.toml`
7. 写 `compatibility.toml`
8. 写 `managed-files.toml`
9. 备份 root entry files
10. 插入 root overlay
11. 使 repo 达到 `doctor-ready`

bootstrap 明确不做：

1. 自动 adoption root sections
2. 自动接管 ambiguous 内容
3. 自动改写 local-overrides

UX 要求：

1. guided
2. non-interactive
3. 可重放

bootstrap 完成后必须输出：

1. 当前 carrier identity
2. doctor command
3. optional adoption next step

## Adoption

`adopt-entrypoints` 是显式第二阶段。

规则：

1. `preview-first`
2. `heading/block-only`
3. mixed section 默认不迁
4. ambiguous section 默认：
   - `manual_review_required = true`
   - 不进入 apply
5. apply 前必须给出：
   - adopted sections
   - left-in-root sections
   - manual-review sections
   - truth-priority changes
   - redirect coverage diff

## Truth Priority

truth priority 固定为：

1. adopted section:
   - `project-context.md` 为真相
2. root redirect block:
   - 只承担指针，不承担正文真相
3. unadopted root body:
   - 继续有效
4. append-only `decision / brief / state / log`:
   - 继续按各自 contract 承担运行态与历史真相

`doctor` 必须可机械验证：

1. adoption coverage
2. redirect coverage
3. truth priority consistency

## Doctor

`doctor` 是 hard gate。

固定 phases：

1. `presence`
2. `instruction_chain`
3. `identity`
4. `compatibility`
5. `managed_surface_integrity`
6. `migration_integrity`

必要模式：

1. `doctor --instruction-chain`
2. `doctor --strict`

exit code：

1. `0` green
2. `10` missing carrier
3. `20` dispatch mismatch
4. `30` compatibility mismatch
5. `40` managed surface drift
6. `50` migration integrity broken

失败时只允许：

1. `repair`
2. `update-plan`

## Repair

`repair` 只允许自动修 deterministic shell：

1. generated prelude
2. `.harness/entrypoint.md`
3. dispatch/lock/install metadata

不允许自动修：

1. adoption misclassification
2. user unmanaged body
3. append-only state corruption

repair 必须先输出 repair plan。

## Update

`update` 固定为两阶段：

1. `update-plan`
2. `update-apply`

`update-plan` 必须读取：

1. `kernel-dispatch.toml`
2. `lock.toml`
3. `compatibility.toml`
4. `managed-files.toml`
5. `adoption-index.toml`

`update-plan` 必须输出：

1. `identity changes`
2. `compatibility changes`
3. `managed surface diff`
4. `manual review points`

`update-apply` 只允许在：

1. `doctor --strict` green
   或
2. 明确 repair 完成

时运行。

## Profiles And Local Overrides

1. profile 只定义 scaffold preset，不定义 runtime truth
2. `.harness/local-overrides/` 只存：
   - provider-specific fragments
   - user-local preferences
3. `doctor` 不得把 local-overrides 当 drift
4. `update` 不得触碰 local-overrides

## Release And Rollout

release channels：

1. `dogfood`
2. `canary`
3. `stable`

规则：

1. `trading-agent` 默认消费 `dogfood/canary`
2. consumer repo 默认只允许 `stable`
3. 生产 consumer repo 默认禁用：
   - `latest`
   - 分支名
   - 浮动 ref

## CI / Audit / Acceptance Suite

最小 acceptance suite：

1. fresh repo
2. existing pure-project AGENTS repo
3. mixed-section AGENTS repo
4. provider-heavy AGENTS repo
5. version mismatch repo
6. missing carrier with dispatch repo

CI 必须至少跑：

1. `doctor --instruction-chain`
2. `doctor --strict`
3. bootstrap replay
4. update-plan smoke

audit 必须检查：

1. root mirror parity
2. redirect coverage
3. managed-files integrity

## Locked Principles

1. Hosted Kernel 继续成立
2. deterministic first hop 必须 repo-local
3. carrier 必须 provider-native 且 focused
4. bootstrap 默认不做语义 adoption
5. adoption 必须 preview-first、heading/block-only、可回放
6. drift control 必须 contract-first
7. doctor 必须 fail-closed
8. profiles 是预设，local-overrides 是保留，不得混成 kernel truth

## Explicit Non-Goals

1. 不要求 consumer repo 在无 harness carrier 环境下完全独立运行
2. 不把完整 kernel docs/workflows/scripts vendoring 到 consumer repo
3. 不自动接管 provider-specific 或 ambiguous root 内容
4. 不在 v1.31 默认启用 Vendored Kernel

## Open Questions

1. `entrypoint.md` 最终文案模板
2. provider-native distribution 仓的目录结构
3. repair 的自动化上限
4. `harness-framework` 与 `trading-agent` 的正式拆仓顺序

