# True Evolution Scorecard Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active

## Purpose

定义 `True Evolutionary Hardening` 每一轮的评分合同，避免“更好”只剩主观印象。

## Canonical Dimensions

最少 7 个维度：

1. `correctness`
2. `determinism`
3. `safety`
4. `operator_usability`
5. `compounding_value`
6. `rolloutability`
7. `complexity_discipline`

## Required Fields

每轮 scorecard 至少包含：

1. `run_id`
2. `round_id`
3. `parent_survivor`
4. `candidate_count`
5. `survivor_id`
6. `scores.<dimension>.previous`
7. `scores.<dimension>.current`
8. `scores.<dimension>.delta`
9. `weighted_total.previous`
10. `weighted_total.current`
11. `weighted_total.delta`
12. `invariant_violations`
13. `plateau_signal`
14. `oscillation_signal`
15. `promotion_decision`

## Pairwise Requirement

每轮都必须显式比较：

1. `survivor_n-1`
2. `survivor_n`

禁止：

1. 只看当前版本绝对分数
2. 不比较相对提升就晋升 survivor

## Gating Logic

晋升 survivor 必须满足：

1. 没有 fatal invariant violation
2. `weighted_total.current >= weighted_total.previous`
3. 关键维度不得出现不可接受倒退
4. safety lane 不得给出 catastrophic drift

## Plateau Logic

plateau 至少要检查：

1. 连续 `3` 轮总分提升低于阈值
2. 连续 `3` 轮关键维度无显著提升

## Oscillation Logic

至少要捕捉：

1. 某维度来回涨跌
2. 通过牺牲 determinism 换取短期 readability
3. 通过堆复杂度换取局部 correctness

## Weighting Rule

默认建议：

1. correctness
2. determinism
3. safety

是高权重维度。

`operator_usability / compounding_value / rolloutability / complexity_discipline`
为中高权重维度。

## Schema Evolvability Rule

scorecard schema 可以进化，但必须：

1. 通过 meta-round 或 checkpoint 升级
2. 说明新旧维度是否可比较
3. 不允许在半轮中换评分逻辑

## Locked Principle

没有 pairwise scorecard，就没有真实 selection pressure。

## Residual Risk

1. 具体分值区间与阈值还未量化
2. 不同任务类型是否共享同一套权重还未定稿
