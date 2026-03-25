# Hosted Kernel Harness Spec v1.1

- Date: 2026-03-24
- Owner: CTO / Workflow & Automation
- Status: founder-locked snapshot
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-24-hosted-kernel-harness-spec-v1.md`
- Purpose:
  1. 保留 `Hosted Kernel` 的低侵入方向，但补齐审计指出的 deterministic entrypoint、carrier shape、adoption lifecycle 与 provenance contract。
  2. 把 `v1` 从“概念成立”推进到“可产品化的 v1.1”。
  3. 明确 Hosted Kernel 的最小 repo-local dispatcher 和 machine-readable compatibility surface。

## Divergent Hypotheses

1. `Keep v1 as-is`
   - 保持单一全局 `harness` skill + bootstrap 自动 adoption + `lock.toml + doctor` 最小补偿。
   - 优点：变更最少。
   - 缺点：继续暴露 entrypoint drift、monolithic carrier、automatic adoption 风险。
2. `Switch to Vendored Kernel`
   - 把 kernel 正文和脚本重新落回 repo，直接放弃 Hosted Kernel。
   - 优点：最强 repo 自包含。
   - 缺点：违背当前 Founder 已锁定的 `少侵入`。
3. `Harden Hosted Kernel`
   - 保留 Hosted Kernel，但增加 repo-local dispatcher、focused skill collection、preview-first adoption 和 stronger provenance contract。
   - 优点：保住低侵入，同时把关键 operator risk 拉回可控。

## First Principles Deconstruction

1. 当前最高约束仍是 `少侵入`，所以不应直接退回 vendored kernel。
2. 但任何 Hosted Kernel 如果不能提供：
   - deterministic first hop
   - repo-reviewable compatibility surface
   - safe update boundary
   - conservative migration/adoption
   它就还不具备 best-practice 级 operator safety。
3. 因此真正要修的不是 Hosted Kernel 方向，而是它的：
   - carrier shape
   - entrypoint chain
   - provenance contract
   - migration policy

## Convergence To Excellence

采纳第 3 条路线，正式定义：

`Hosted Kernel Harness v1.1`

核心变化：

1. 不再用单一大 `harness` skill 承载全部职责
2. root overlay 不再直接要求“先去用已安装 harness skill”
3. bootstrap 不再默认自动做 section adoption
4. `lock.toml + doctor` 升级为 `dispatcher + provenance + compatibility + managed-files` 四件套

## Distribution Unit

`Hosted Kernel` 的 distribution unit 从：

`single monolithic harness skill`

改为：

`harness plugin / skill collection`

最小组件：

1. `harness-bootstrap`
2. `harness-adopt-entrypoints`
3. `harness-doctor`
4. `harness-update`
5. `harness-repair`

要求：

1. 每个 skill 只做一个 job
2. 对用户可继续以统一品牌 `harness` 暴露
3. provider-specific packaging 可以不同，但 repo-local contract 必须一致

## Repo-Local Dispatcher

consumer repo 不 vendoring kernel 正文，但必须有最小 repo-local dispatcher。

新增：

```text
.harness/
  entrypoint.md
  kernel-dispatch.toml
  install.toml
  lock.toml
  compatibility.toml
  managed-files.toml
```

语义：

1. `.harness/entrypoint.md`
   - repo-local first hop
   - 只描述当前 repo 应如何解析 harness kernel
   - 若环境不满足要求，明确 fail-closed，并指向 `doctor`
2. `.harness/kernel-dispatch.toml`
   - 记录 distribution source、plugin/collection id、required skills、exact version 或 commit、digest、expected enabled state
3. `.harness/install.toml`
   - 记录安装模式、profile、bootstrap 时间
4. `.harness/lock.toml`
   - 记录 repo 锁定的 harness release identity
5. `.harness/compatibility.toml`
   - 记录 repo 当前兼容的 kernel behavior contract 与 migration level
6. `.harness/managed-files.toml`
   - 记录 harness 受管路径、ownership、merge policy、checksum

## Entrypoint Chain

新的 canonical first-hop 改为：

1. root `AGENTS.md / CLAUDE.md / GEMINI.md`
2. `.harness/entrypoint.md`
3. 根据 `.harness/kernel-dispatch.toml` 校验并解析 `harness` plugin / skill collection
4. 进入 hosted kernel routing
5. 再读取 `.harness/workspace/current/project-context.md` 与其他 repo-local runtime state

这意味着：

1. root overlay 仍然存在
2. 但它首跳不再直接依赖“环境里某个全局 skill 恰好存在”
3. repo 至少有一个可 review、可 pin、可 fail-closed 的 dispatcher

## Root Overlay

v1.1 的 root overlay 规则：

1. root 只插入 harness-managed prelude
2. prelude 第一跳指向 `.harness/entrypoint.md`
3. 若 `.harness/kernel-dispatch.toml` 不满足环境条件，必须 fail-closed，而不是继续尝试运行 hosted kernel
4. 未被 harness 接管的 root 正文仍可保留

## Runtime State

repo-local runtime state 仍保持轻量，不落 kernel 正文：

```text
.harness/
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
```

这部分继续是：

1. 项目语义
2. decision / brief / state / log
3. 本地组织投影
4. migration 和 override 记录

## Bootstrap Lifecycle

`bootstrap` 现在只做 deterministic scaffold：

1. 安装或解析 `harness` plugin / skill collection
2. 初始化 `.harness/` 目录结构
3. 写 `entrypoint.md`
4. 写 `kernel-dispatch.toml`
5. 写 `install.toml`
6. 写 `lock.toml`
7. 写 `compatibility.toml`
8. 写 `managed-files.toml`
9. 备份已有 root entry files
10. 写 root overlay / prelude
11. 使 repo 达到 `doctor-ready`

明确不做：

1. 默认自动迁移 root entry sections
2. 默认重排用户 root 正文
3. 默认接管 ambiguous content

## Adoption Lifecycle

`adopt-entrypoints` 从 bootstrap 中拆出，成为显式第二阶段动作。

规则：

1. `preview-first`
   - 先生成 adoption plan
   - 明确列出将迁移哪些 section
   - 未确认前不写入 `project-context`
2. 只允许 `heading/block-only`
3. mixed section 默认不迁
4. 每个 adopted section 必须写：
   - `stable section-id`
   - `source path`
   - `source heading`
   - `source checksum`
   - `adopted at`
5. root 原位置换 redirect block 时，必须带 `section-id`
6. `project-context` 与 root redirect coverage 必须可被 `doctor` 机械检查

## Truth Priority

v1.1 显式定义 adoption 后的优先级：

1. 已被 redirect block 覆盖的 adopted section：
   - `.harness/workspace/current/project-context.md` 为真相
2. 未被 adoption 的 root 正文：
   - root 文件原文继续有效
3. 冲突时：
   - adopted section 以 `project-context` 为准
   - 未 adopted section 以 root 为准

这个优先级必须写入 `compatibility.toml`，并由 `doctor` 验证 redirect coverage。

## Provenance And Compatibility Contract

Hosted Kernel v1.1 的最小约束面：

### `kernel-dispatch.toml`

必须记录：

1. `distribution_source`
2. `distribution_kind = plugin | skill-collection`
3. `collection_or_plugin_id`
4. `required_components`
5. `exact_version` 或 `commit`
6. `content_digest`
7. `expected_enabled_state`

### `lock.toml`

必须记录：

1. repo 当前锁定的 harness release identity
2. compatibility range
3. install mode = `hosted-kernel`

### `compatibility.toml`

必须记录：

1. kernel behavior contract version
2. migration level
3. adoption mode
4. truth priority rules
5. root overlay contract version

### `managed-files.toml`

必须记录：

1. 受管路径
2. ownership
3. merge policy
4. checksum
5. migration provenance

## Doctor

`doctor` 必须升级为 hard verifier，不再只是软检查。

至少验证：

1. required plugin / skill collection 存在
2. required components 存在且已启用
3. exact version / commit / digest 与 `kernel-dispatch.toml` 匹配
4. root overlay block 完整
5. `.harness/entrypoint.md` 与 dispatch metadata 一致
6. `managed-files.toml` 的 checksum 未漂移
7. adoption coverage 与 redirect coverage 一致
8. `project-context` 与 root adopted sections 的 truth priority 可解析

若核心条件不满足：

1. fail-closed
2. 给出明确 repair / update 指引

## Update

`update` 只能在 doctor-green 或明确 repair path 下运行。

流程：

1. 读取 `kernel-dispatch.toml`、`lock.toml`、`compatibility.toml`
2. 生成 update plan
3. 标出受管路径、兼容性变化、需要 review 的 adoption risk
4. 只更新 harness-managed 区域
5. 不触碰用户未接管正文和 repo-local instance assets

## Locked Principles

1. 继续采用 Hosted Kernel，不回退到默认 vendored kernel
2. `少侵入` 仍高于最大 repo 自包含
3. Hosted Kernel 必须有 repo-local deterministic dispatcher
4. bootstrap 默认不做语义 adoption
5. adoption 必须 preview-first、heading/block-only、可校验
6. `doctor` 必须成为 fail-closed verifier，而不是 advisory-only checker
7. distribution unit 应为 focused skill collection / plugin，而不是 monolithic single skill

## Explicit Non-Goals For v1.1

1. 仍不要求 consumer repo 在无 harness distribution 环境下完全独立运行
2. 仍不把完整 kernel docs/workflows/scripts 落到 repo
3. 不在 v1.1 引入 Vendored Kernel 作为默认模式
4. 不自动接管 provider-specific 或 ambiguous user settings

## Open Questions

1. `.harness/entrypoint.md` 的最简文案格式
2. `kernel-dispatch.toml` 与 `lock.toml` 的字段边界
3. plugin 与 skills.sh collection 的统一命名
4. `doctor` 失败时是否提供自动 repair

