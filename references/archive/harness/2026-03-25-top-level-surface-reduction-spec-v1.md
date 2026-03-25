# Top-Level Surface Reduction Spec v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready
- Depends on:
  - [Current Harness Repo Layering](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/harness-repo-layering.md)
  - [Harness Framework And Dogfood Layering Spec v2](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-harness-framework-and-dogfood-layering-spec-v2.md)
- Machine-readable contract:
  - [top-level-surface.toml](/Users/vx/WebstormProjects/trading-agent/.harness/top-level-surface.toml)

## Divergent Hypotheses

1. 保留当前顶层结构，只在文档里解释哪些目录以后会收敛。
2. 允许第三种去向，例如 `legacy/`、`archive/`、`compat/` 作为过渡层。
3. 强制三选一：
   - 并入 `.agents/skills/harness/`
   - 并入 `.harness/`
   - 删除

## First Principles Deconstruction

1. 只要顶层还存在多个“看起来像 canonical”的目录，reviewer 就一定会迷路。
2. `legacy/archive` 不是架构答案，只是拖延决策。
3. 当前 repo 的功能性 surface 必须收敛成：
   - `clean framework source`
   - `repo-local runtime workspace`
4. 所有顶层功能目录都必须被问一个问题：

`它回答的是“所有 repo 通用的 harness source”还是“这个 repo 运行时生成的实例态”？`

如果两者都不是，它就应该被删除。

## Convergence To Excellence

采纳第 `3` 条。

## Non-Negotiable Rule

从本版本起，功能性顶层目录只允许三种命运：

1. `move-to-skill-source`
   - 并入 `.agents/skills/harness/`
2. `move-to-runtime`
   - 并入 `.harness/`
3. `delete`
   - 直接删除，不再创造第三缓冲层

不再接受：

1. `legacy/`
2. `archive/`
3. `compat/`
4. `temp canonical`
5. `先放这里以后再说`

## Functional Surface Inventory

以下判断针对“repo 功能性顶层目录”，不包含：

1. `.git`
2. `.github`
3. `.idea`
4. `.githooks`

这些属于仓库基础设施，不在本轮产品面收口范围内。

## Destination Decisions

### Move Into `.agents/skills/harness/`

这些目录回答的是：

`harness framework source 应该长什么样`

#### 1. `docs/`

去向：

`move-to-skill-source`

原因：

1. workflows
2. templates
3. charter
4. provider deltas
5. research on framework practice

本质上都属于 reusable harness source。

#### 2. `scripts/`

去向：

`move-to-skill-source`

原因：

bootstrap / update / doctor / audit / projection / state helper 都是 harness carrier 的一部分。

#### 3. `codex/`

去向：

`move-to-skill-source`

原因：

它是 provider-specific rules，不是实例态。

#### 4. `.agents/roles/`

去向：

`move-to-skill-source`

原因：

这是 reusable role/source contract，不是当前 repo runtime state。

#### 5. `.claude/`

去向：

`move-to-skill-source`

原因：

这是 provider adapter projection，不是实例态。

#### 6. `.codex/`

去向：

`move-to-skill-source`

原因：

这是 provider adapter projection，不是实例态。

#### 7. `.gemini/`

去向：

`move-to-skill-source`

原因：

这是 provider adapter projection，不是实例态。

#### 8. `.agents/skills/`

去向：

`compress-to-single-skill-source`

规则：

1. 当前多个 skill 目录不是最终形态
2. 最终只保留 `.agents/skills/harness/`
3. 现有 skill 应成为 `harness` 内部模块/子能力，而不是继续并列顶层 skill

### Move Into `.harness/`

这些目录回答的是：

`这个 repo 在实际运行中产生了什么`

#### 1. `workspace/`

去向：

`move-to-runtime`

规则：

1. 全量并入 `.harness/workspace/`
2. 不再保留平级 `workspace/`

#### 2. `.harness/workspace/departments/`

去向：

`move-to-runtime`

原因：

当前这些部门不是 framework 通用 source，而是这个 dogfood repo 的组织运行形态。

建议目标：

`.harness/workspace/departments/`

### Delete

如果某个目录既不是 clean harness source，也不是 repo-local runtime，就应删除。

当前本轮没有额外第四类功能目录被允许保留。

## Skill Uniqueness Rule

最终物理目标不是：

1. `.agents/skills/*` 一排并列 skill
2. `.claude/skills/*` 再来一排 projection

而是：

1. `.agents/skills/harness/` 作为唯一 clean skill source
2. provider-specific projections 要么内嵌在 `harness` source 内，要么由 build/sync 生成
3. reviewer 不应再看到一堆并列业务 skill 目录作为一级 surface

## Current Implementation Reality

当前仍是过渡态：

1. `.claude/skills/` 是物理 projection 副本，不是软链接
2. `.codex/` 当前没有等价 skills projection
3. `docs/`、`scripts/`、`workspace/`、`.harness/workspace/departments/` 仍是旧 canonical surface

这说明：

`当前仓的结构仍未收口`

而不是说明最终目标应该如此。

## Acceptance Bar

本轮 surface reduction 只有满足以下条件才算完成：

1. 功能性顶层目录都被判入三选一
2. `legacy/archive` 被正式禁止
3. `harness` 成为唯一 clean skill source 目标
4. `workspace/` 与 `.harness/workspace/departments/` 明确归入 `.harness/`
5. provider adapters 明确归入 skill source，而不是独立真相

## Residual Risk

1. 当前只是收敛了去向，还未执行真正的目录搬迁
2. `.claude/skills/` 仍是物理 projection 副本
3. `harness` 虽已建立为唯一目标 carrier，但现有并列 skill 目录尚未压缩进去
