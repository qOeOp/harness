# True Evolution Lineage Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active

## Purpose

定义 `True Evolutionary Hardening` 的 lineage 合同，确保每轮进化可追溯、可解释、可回放。

## Canonical Lineage Fields

每轮至少记录：

1. `run_id`
2. `round_id`
3. `parent_survivor_id`
4. `current_survivor_id`
5. `candidate_ids`
6. `accepted_delta_ids`
7. `rejected_delta_ids`
8. `winning_rationale`
9. `lane_inputs`
10. `lane_outputs`
11. `checkpoint_parent`
12. `schema_versions`

## Provenance Rule

每条 accepted delta 必须能回答：

1. 来自哪个 candidate
2. 由哪条 lane 强烈支持
3. 为什么比其他 delta 更优

## Rejected Delta Rule

rejected delta 不是垃圾：

1. 必须记录拒绝原因
2. 可以被下一轮重新考虑
3. 但必须带前次 rejection history

## Winning Rationale

每轮都必须单独写：

1. 为什么当前 survivor 赢
2. 赢在什么维度
3. 付出了什么代价
4. 留下了哪些 residual risks

## Checkpoint Lineage

checkpoint 必须记录：

1. 由哪些 rounds 压缩而来
2. 压缩掉了哪些中间细节
3. 哪些 invariants 被提升或冻结

## Replayability

lineage 的目标不是“好看”，而是允许后续回答：

1. 为什么这个版本存在
2. 为什么不是另一个版本
3. 当前规则是怎么被选择出来的

## Schema Evolvability Rule

lineage schema 本身也允许进化，但：

1. 不允许破坏旧 lineage 的可读性
2. 必须给出 migration note
3. 必须说明旧 lineage 与新 lineage 如何兼容

## Locked Principle

没有 lineage，就没有进化，只有覆盖写。

## Residual Risk

1. lineage 文件与 round 文件是一体还是分离还未定稿
2. checkpoint 压缩后保留多少细节还未量化
