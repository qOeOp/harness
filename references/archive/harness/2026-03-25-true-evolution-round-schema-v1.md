# True Evolution Round Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Scope:
  1. 定义 `True Evolutionary Hardening` 每一轮的最小 artifact 集。
  2. 让 `v3.01+` 不再退化成“写一版新稿”，而是变成真正的 round machine。

## Divergent Hypotheses

1. 每轮只保留一个 survivor 文件。
2. 每轮自由生成任意数量的辅助文件。
3. 每轮固定一组最小 artifact，其他内容只能作为补充。

## First Principles Deconstruction

1. 真进化不是“下一稿更好看”，而是“下一轮更可解释”。
2. 如果每轮没有固定 artifact，50 轮之后只会剩下一堆版本文件，无法证明进化是怎么发生的。
3. round schema 的职责是把“读什么、比什么、写什么、留什么”钉死。

## Convergence To Excellence

采纳第 3 条路线。

## Canonical Round Layout

每一轮至少必须产出 8 类 artifact：

1. `survivor_n.md`
2. `candidates_n.md`
3. `scorecard_n.toml`
4. `accepted-deltas_n.md`
5. `rejected-deltas_n.md`
6. `residual-risks_n.md`
7. `why-this-version-won_n.md`
8. `lane-outputs_n/`

可选补充：

1. `pairwise-comparison_n.md`
2. `checkpoint-note_n.md`
3. `plateau-check_n.md`

## Required Round Inputs

每一轮输入固定为：

1. `survivor_n-1`
2. `scorecard_n-1`
3. `residual-risks_n-1`
4. `accepted-deltas_n-1`
5. `rejected-deltas_n-1`
6. 当前 `invariants`
7. 当前 `rubric`

禁止：

1. 只读上一轮 survivor，不读 scorecard
2. 不读 residual risk 就直接改
3. 跳过 rejected delta 的复盘

## Canonical Round Protocol

一轮固定 8 步：

1. `Load`
2. `Research`
3. `Propose`
4. `Critique`
5. `Score`
6. `Select`
7. `Writeback`
8. `Checkpoint`

每一步都必须在 artifact 中留下痕迹。

## Artifact Semantics

### `survivor_n.md`

职责：

1. 当前唯一 canonical survivor
2. 下一轮唯一正文输入

禁止：

1. 同轮出现多个 survivor
2. 用 candidate 冒充 survivor

### `candidates_n.md`

职责：

1. 记录本轮 `3-5` 个 candidate deltas
2. 每个 candidate 必须有唯一 id
3. 必须指向 mutation operator

### `scorecard_n.toml`

职责：

1. 记录多维 fitness
2. 记录 invariant violations
3. 记录 pairwise comparison against prior survivor

### `accepted-deltas_n.md`

职责：

1. 列出哪些 mutation 被吸收进 survivor
2. 说明每条 delta 为什么通过

### `rejected-deltas_n.md`

职责：

1. 列出哪些 mutation 被拒绝
2. 说明拒绝原因
3. 供下一轮继续复用或永久淘汰

### `residual-risks_n.md`

职责：

1. 记录仍未解决的问题
2. 记录下一轮应优先处理的风险

### `why-this-version-won_n.md`

职责：

1. 解释为什么 survivor_n 优于 survivor_n-1
2. 指出是否只是局部提升，还是结构性提升

### `lane-outputs_n/`

职责：

1. 保存 5 条 lane 的结构化输出
2. 禁止 lane 只在聊天里给意见、不落盘

## Minimum Naming Rule

推荐目录：

`/.harness/evolution/runs/<run-id>/rounds/<round-id>/`

最小文件：

1. `survivor.md`
2. `candidates.md`
3. `scorecard.toml`
4. `accepted-deltas.md`
5. `rejected-deltas.md`
6. `residual-risks.md`
7. `why-this-version-won.md`
8. `lane-outputs/`

## Checkpoint Rule

每 `5` 轮必须生成一次 integrated checkpoint。

checkpoint 的职责：

1. 压缩最近 5 轮 accepted deltas
2. 重写当前 survivor 为高可读 integrated snapshot
3. 重新列出 invariants 和 residual risks

## Truth Hierarchy

一轮内的优先级固定为：

1. `survivor_n`
2. `scorecard_n`
3. `accepted/rejected deltas_n`
4. `lane outputs_n`
5. 其他补充说明

## Schema Evolvability Rule

这个 schema 本身也允许进化，但必须遵守：

1. 不能在同一轮中途静默改 schema
2. schema 升级只能发生在：
   - checkpoint 边界
   - 或显式 meta-round
3. 升级必须带：
   - `supersedes`
   - compatibility note
   - migration note

## Locked Principle

没有固定 round artifact，就没有真正的 serial evolution。

## Residual Risk

1. `scorecard.toml` 的具体字段还未单独定稿
2. `lineage` 结构还未单独定稿
3. round 目录与 repo artifact 的映射还未落地
