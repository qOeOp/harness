# Hosted Kernel Harness Spec v1.11

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-locked snapshot
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-24-hosted-kernel-harness-spec-v1-1.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-2.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-3.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-4.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-5.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-6.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-7.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-8.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-9.md`
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-10.md`
- Purpose:
  1. 在保留 `Hosted Kernel` 低侵入方向的前提下，把 entrypoint determinism、carrier 形态、bootstrap/adoption 生命周期、provenance/compatibility/ownership contract 和 update gate 一次收敛。
  2. 给 `harness-framework` 产品化和 `trading-agent` dogfood 提供可执行的 v1.11 基线。

## Divergent Hypotheses

1. `继续维持 v1.1`
   - 少侵入成立，但 deterministic entrypoint、automatic adoption、monolithic skill 与 drift control 仍然偏弱。
2. `回退到 Vendored Kernel`
   - 能获得更强 repo 自包含，但违背当前 Founder 已锁定的低侵入优先级。
3. `保留 Hosted Kernel，并把它从 trust-based 改成 contract-based`
   - repo-local first hop
   - provider-native distribution
   - preview-first adoption
   - fail-closed doctor
   - provenance/compatibility/ownership contracts

## First Principles Deconstruction

1. 当前最高约束仍是：
   - `少侵入`
2. 但少侵入不能通过牺牲以下四件事换取：
   - deterministic instruction chain
   - repo-reviewable compatibility surface
   - safe migration/adoption
   - controlled update lifecycle
3. 因此 Hosted Kernel 不该被推翻，但必须补偿：
   - repo-local dispatcher
   - provider-native carrier
   - conservative migration
   - machine-readable contracts

## Convergence To Excellence

采纳第 3 条路线，正式定义：

`Hosted Kernel Harness v1.11`

## Carrier Shape

canonical distribution unit 不再是单一大 `harness` skill。

改为：

1. `harness` 作为统一产品品牌
2. 对外按 provider 投影为：
   - Claude plugin
   - Codex / skills.sh skill collection
3. 内部最小 focused components：
   - `harness-bootstrap`
   - `harness-adopt-entrypoints`
   - `harness-doctor`
   - `harness-update-plan`
   - `harness-update-apply`
   - `harness-repair`

## Repo-Local First Hop

consumer repo 的 canonical entry chain：

1. root `AGENTS.md / CLAUDE.md / GEMINI.md`
2. `.harness/entrypoint.md`
3. `.harness/kernel-dispatch.toml`
4. provider-native `harness` carrier
5. `.harness/workspace/current/project-context.md`
6. `.harness/workspace/briefs|decisions|state|logs`

root overlay 规则：

1. root 只插入 harness-managed prelude
2. 第一跳只指向 `.harness/entrypoint.md`
3. 不再直接要求“先使用已安装 harness skill”
4. 若 entrypoint 发现环境不满足 dispatch contract，必须 fail-closed

## Repo-Local Runtime State

`.harness/` 最小结构：

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

语义：

1. `entrypoint.md`
   - repo-local dispatcher
2. `kernel-dispatch.toml`
   - 当前 repo 期望调用哪一个 harness carrier
3. `install.toml`
   - 实际安装事实
4. `lock.toml`
   - repo 锁定的 harness release identity
5. `compatibility.toml`
   - kernel behavior contract 与 truth priority
6. `managed-files.toml`
   - 受管路径和 merge policy
7. `workspace/*`
   - 项目语义与 append-only 运行态资产
8. `migrations/adoption-index.toml`
   - adoption ledger

## Bootstrap Lifecycle

`bootstrap` 只做 deterministic scaffold：

1. 解析并安装匹配的 provider-native harness carrier
2. 初始化 `.harness/`
3. 写 `entrypoint.md`
4. 写 `kernel-dispatch.toml`
5. 写 `install.toml`
6. 写 `lock.toml`
7. 写 `compatibility.toml`
8. 写 `managed-files.toml`
9. 备份 root entry files
10. 插入 root overlay / managed prelude
11. 使 repo 达到 `doctor-ready`

bootstrap 明确不做：

1. 自动 adoption root sections
2. 自动接管 ambiguous 内容
3. 自动重排用户 provider-specific 正文

## Adoption Lifecycle

`adopt-entrypoints` 是显式第二阶段。

规则：

1. `preview-first`
2. `heading/block-only`
3. mixed section 默认不迁
4. 每个 adopted section 必须有：
   - `section-id`
   - `source path`
   - `source heading`
   - `source checksum`
   - `adopted target`
   - `adopted_at`
5. root 原位置换 redirect block 时必须带 `section-id`

## Truth Priority

v1.11 明确采用：

1. 已被 redirect block 覆盖的 adopted section：
   - `project-context.md` 为真相
2. 未被 adoption 的 root 正文：
   - root 原文继续有效
3. append-only state / decision / brief / log artifacts：
   - 仍按其各自 contract 承担运行态或历史真相

truth priority 必须写入 `compatibility.toml` 并由 `doctor` 验证。

## Provenance And Compatibility Contracts

### `kernel-dispatch.toml`

必须记录：

1. `distribution_source`
2. `distribution_kind`
3. `collection_or_plugin_id`
4. `required_components`
5. `exact_version_or_commit`
6. `content_digest`
7. `expected_enabled_state`

### `install.toml`

必须记录：

1. `installed_from`
2. `installed_at`
3. `profile`
4. `install_mode = hosted-kernel`
5. `installed_release_identity`

### `lock.toml`

必须记录：

1. `provider`
2. `carrier_type`
3. `source_repo_or_url`
4. `release_tag`
5. `exact_version_or_commit`
6. `artifact_hash`
7. `required_component_ids`
8. `compatibility_range`

### `compatibility.toml`

必须记录：

1. `kernel_behavior_contract_version`
2. `state_schema_version`
3. `adoption_contract_version`
4. `minimum_doctor_version`
5. `supported_upgrade_paths`
6. `truth_priority_rules`
7. `overlay_contract_version`

### `managed-files.toml`

必须记录：

1. `path`
2. `owner`
3. `merge_policy`
4. `checksum`
5. `block_id`
6. `migration_provenance`

### `migrations/adoption-index.toml`

必须记录：

1. 每个 adopted section 的 source/target/hash/redirect metadata

## Doctor

`doctor` 是 fail-closed hard verifier。

至少检查：

1. carrier presence
2. component enabled state
3. exact version / commit / digest 匹配
4. root overlay integrity
5. `.harness/entrypoint.md` 与 `kernel-dispatch.toml` 一致
6. `managed-files.toml` checksum integrity
7. adoption coverage 与 redirect coverage
8. truth priority 可解析

必要子模式：

1. `doctor --instruction-chain`
2. `doctor --strict`

失败时只允许：

1. `repair`
2. `update-plan`

## Update

`update` 必须拆为：

1. `update-plan`
2. `update-apply`

`update-plan` 读取：

1. `kernel-dispatch.toml`
2. `lock.toml`
3. `compatibility.toml`
4. `managed-files.toml`
5. `adoption-index.toml`

`update-apply` 只允许在：

1. `doctor --strict` 通过
   或
2. 明确 repair 完成

后运行。

更新只能触碰：

1. harness-managed 区域
2. declared repo-local runtime schema

不能触碰：

1. 用户未接管 root 正文
2. ambiguous / provider-specific 保留内容
3. instance-local append-only assets

## Release Channels

定义三层：

1. `stable`
2. `canary`
3. `dogfood`

要求：

1. `trading-agent` 默认先吃 `dogfood/canary`
2. 普通 consumer repo 默认只吃 `stable`
3. 任何 release 至少要过：
   - bootstrap
   - doctor
   - update-plan/apply
   - adoption preview
   - instruction-chain acceptance suite

## Acceptance Suite

最小夹具集：

1. fresh repo
2. existing pure-project AGENTS repo
3. mixed-section AGENTS repo
4. provider-heavy AGENTS repo
5. version mismatch repo
6. missing carrier but dispatch exists repo

验收目标：

1. 首跳稳定
2. adoption 保守
3. truth priority 无歧义
4. doctor 能 fail-closed

## Locked Principles

1. Hosted Kernel 继续成立，不回退到默认 vendored kernel
2. `少侵入` 继续高于最大 repo 自包含
3. deterministic instruction chain 必须 repo-local
4. distribution unit 必须 focused，而不是 monolithic
5. bootstrap 默认不做语义 adoption
6. adoption 必须 preview-first、heading/block-only、可回放
7. drift control 必须 contract-based，不再 trust-based
8. doctor 必须成为硬 gate

## Explicit Non-Goals

1. 不要求 repo 在无 harness carrier 环境下完全独立运行
2. 不把完整 kernel docs/workflows/scripts vendoring 到 consumer repo
3. 不自动接管 provider-specific 或 ambiguous root 内容
4. 不在 v1.11 默认启用 Vendored Kernel 模式

## Open Questions

1. `entrypoint.md` 文案最简模板
2. `kernel-dispatch.toml` 与 `lock.toml` 的字段切分
3. provider-native `harness` 分发仓结构
4. `repair` 的自动修复边界

