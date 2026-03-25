# Hosted Kernel Harness Spec v1

- Date: 2026-03-24
- Owner: CTO / Workflow & Automation
- Status: founder-locked snapshot
- Purpose:
  1. 锁定 `Hosted Kernel Harness v1`，把“少侵入”正式定为 consumer repo 默认架构。
  2. 明确 global `harness` skill 与 repo-local `.harness/` 的职责边界。
  3. 记录本轮关于 overlay、section adoption、version lock 和 update surface 的讨论结论。

## Divergent Hypotheses

1. `Vendored Kernel`
   - 把 harness kernel 文档、脚本和控制面完整安装进 repo。
   - 优点是 repo 最强自包含；缺点是侵入更重。
2. `Hosted Kernel`
   - kernel 常驻全局 `harness` skill；repo 只保存 `.harness/` 运行态和 root overlay。
   - 优点是侵入最小；缺点是行为依赖已安装 skill 版本。
3. `Hybrid Optional`
   - 默认 Hosted，后续允许需要更强确定性的团队切到 Vendored。
   - 优点是未来兼容面更广；缺点是 v1 复杂度过高。

## First Principles Deconstruction

1. Founder 当前最明确的优先级是 `少侵入`，不是“把 framework 尽可能塞进 repo”。
2. 只要 root entry 能稳定把 agent 路由到 harness，再把项目语义和运行态资产稳定挂回 repo，本轮目标就成立。
3. 用户 repo 真正必须本地持有的是：
   - 项目相关长期语义
   - decision / brief / state / log
   - migration 记录
   - 版本锁与兼容性声明
4. 用户 repo 当前不必本地持有的是：
   - harness kernel 文档
   - bootstrap / doctor / update 执行引擎
   - adoption 规则本体
5. 如果 kernel 不落 repo，就必须用 `lock + doctor` 约束行为漂移；否则同一 repo 在不同机器上可能被不同 skill 版本解释。

## Convergence To Excellence

采纳第 2 条路线，正式定义：

`Hosted Kernel Harness v1`

默认 consumer repo 采用：

1. global `harness` skill 持有 kernel
2. repo-local `.harness/` 持有运行态资产
3. root `AGENTS.md / CLAUDE.md / GEMINI.md` 只做 overlay/shim
4. 用 `.harness/lock.toml` 与 `harness doctor` 约束 skill 版本与兼容性

## Kernel Placement

global `harness` skill 持有：

1. `SKILL.md`
2. `docs/workflows/document-routing-and-lifecycle.md`
3. code review / operator / routing / adoption / update 规则
4. bootstrap / adopt-entrypoints / update / doctor / repair 脚本
5. overlay block 模板
6. section classification 与 migration 逻辑

这部分是 `kernel source + execution engine`。

## Repo-Local Runtime State

consumer repo 只落最小 `.harness/` 运行态：

```text
.harness/
  install.toml
  lock.toml
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

语义边界：

1. `.harness/workspace/current/project-context.md`
   - 项目自己的 canonical context
2. `.harness/workspace/briefs`
   - 当前轮或当前对象的 brief
3. `.harness/workspace/decisions`
   - append-only decision history
4. `.harness/workspace/state`
   - task / status / transition 等运行态
5. `.harness/workspace/logs`
   - 执行日志或治理日志
6. `.harness/departments` 与 `.harness/agents`
   - repo-local 组织与角色投影
7. `.harness/local-overrides`
   - 未被 harness 接管的本地 user/provider 设置
8. `.harness/migrations`
   - 原入口备份、adoption report、redirect metadata

## Root Overlay

root entry files 只承担 discovery，不承载 harness kernel 正文。

v1 规则：

1. 在 root `AGENTS.md / CLAUDE.md / GEMINI.md` 顶部插入 harness-managed prelude
2. prelude 负责提示：
   - 先使用已安装的 `harness` skill
   - 再读取 repo-local `.harness/` 状态
3. root 原有正文默认保留
4. harness update 只允许改 managed prelude 和 redirect blocks

## Section Adoption

对于已有项目的 root entry：

1. 自动 adoption 只做 `section-level`
2. 高置信 `project-related` 内容迁入 `.harness/workspace/current/project-context.md`
3. 原位置换为 managed redirect block
4. provider-specific / local preference / ambiguous 内容原地保留
5. 原文件完整备份进入 `.harness/migrations/original-entrypoints/<timestamp>/`

高置信 project context 包括：

1. 产品边界
2. domain 约束
3. 架构约束
4. 仓库结构说明
5. build / test / run 约束
6. integration / interface 规则

## Version Control And Drift Management

既然 consumer repo 不 vendoring kernel，就必须显式锁版本。

最小要求：

1. `.harness/install.toml`
   - 记录安装模式、时间、profile、adoption mode
2. `.harness/lock.toml`
   - 记录当前 repo 期望的 `harness` skill 版本与兼容区间
3. `harness doctor`
   - 检查 skill 是否安装
   - 检查 skill 版本是否满足 `lock.toml`
   - 检查 `.harness/` 结构和 root overlay 是否完整

## Lifecycle

### Bootstrap

1. 安装或检测 global `harness` skill
2. 初始化 `.harness/` 最小结构
3. 写 `install.toml` 与 `lock.toml`
4. overlay root entry files
5. 对高置信 project sections 做 section adoption

### Doctor

1. 检查 skill presence
2. 检查 version compatibility
3. 检查 overlay integrity
4. 检查 `.harness/` required paths

### Update

1. 比较当前 skill 版本与目标版本
2. 生成 update plan
3. 只更新 harness-managed 区域与 repo-local state schema
4. 不触碰用户未受管内容

## Locked Principles

1. `少侵入` 高于 `最大 repo 自包含`
2. repo-local `.harness/` 只承载状态、语义和本地组织投影
3. harness kernel 默认常驻 global skill，而不是 vendoring 到 repo
4. 任何行为一致性问题优先用 `lock + doctor` 解决
5. update 必须是受管区域更新，不得顺手接管用户未授权内容

## Explicit Non-Goals For v1

1. 不要求 consumer repo 在无 `harness` skill 环境下完全独立运行
2. 不把 `document-routing-and-lifecycle.md` 等 kernel 文件落到 repo
3. 不做 root entry 全量接管
4. 不默认把 provider-specific 本地设置迁入 project context
5. 不在普通 consumer repo 中保留 framework source checkout

## Open Questions

1. `install.toml / lock.toml` 的最终 schema 细节
2. `doctor` 的错误等级与修复建议格式
3. `.harness/departments` 与 `.harness/agents` 应由 bootstrap 生成多少默认骨架
4. 是否在 `v2` 支持可选 `Vendored Kernel` 模式

