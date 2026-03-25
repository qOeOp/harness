# Evolutionary Hardening Round Telemetry Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Depends on:
  - [2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md)
  - [2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-run-manifest-schema-v1.md)
  - [2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-scorecard-summary-schema-v1.md)

## Divergent Hypotheses

1. 继续让 raw rounds 只以 prose markdown 存在。
2. 直接删除 raw rounds，只保留 checkpoint。
3. 保留 raw rounds，但新增一个结构化 `round telemetry` 作为 canonical raw carrier。

## First Principles Deconstruction

1. lineage 必须保留，但不需要靠 reviewer 直接阅读所有 prose 才能成立。
2. operator 有时需要回放 round 级变化，因此 raw carrier 不能消失。
3. raw carrier 的最佳形态应该是：
   - 结构化
   - 可 diff
   - 可聚合
   - 可被后续工具消费
4. 只要 round 原始信息仍全部躺在 prose 里，系统就还没有真正完成 carrier demotion。

## Convergence To Excellence

采纳第 `3` 条路线。

`Round Telemetry` 被定义为：

`run 级的结构化 raw lineage carrier`

## Canonical Objective

round telemetry 负责：

1. 给 operator 提供无需阅读 prose 的 round 回放面
2. 给未来脚本和 UI 提供 machine-readable lineage 素材
3. 让 raw round prose 退化成可选附注，而不是 canonical raw source

## Placement Rule

正式执行面建议位置：

1. `.harness/evolution/runs/<run-id>/telemetry/rounds.toml`

dogfood 期允许：

1. `.harness/workspace/runs/<run-id>/telemetry/rounds.toml`

## Required Top-Level Fields

至少包含：

1. `run_id`
2. `mode_survivor`
3. `target`
4. `seed_ref`
5. `current_checkpoint_ref`
6. `current_scorecard_summary_ref`
7. `current_candidate_ref`
8. `round_count`
9. `telemetry_status`

## Required Per-Round Fields

每轮至少记录：

1. `parent_ref`
2. `focus`
3. `candidate_count`
4. `selected_candidate`
5. `selected_operator`
6. `exploit_present`
7. `exploration_present`
8. `pairwise_verdict`
9. `accepted_delta_summary`
10. `rejected_delta_summary`
11. `residual_risk_summary`
12. `output_refs`

## Canonical Semantics

### `selected_operator`

只记录 mutation/crossover 的高层归类，例如：

1. `tighten-constraint`
2. `split-concept`
3. `add-gate`
4. `simplify-conflict`
5. `add-eval-surface`
6. `reframe-object-model`

### `exploit_present` / `exploration_present`

必须明确：

1. 该轮是否真的存在 exploit 候选
2. 该轮是否真的存在 exploration 候选

否则后续无法判断系统是在优化还是在探索。

### `pairwise_verdict`

只允许：

1. `local-improvement`
2. `structural-improvement`
3. `hold`
4. `regression`

## Anti-Bloat Rule

telemetry 不允许复制：

1. 全量 operator reflection prose
2. 全量 lane notes
3. checkpoint 正文
4. candidate 正文

telemetry 应该是：

`结构化索引`

不是第二份叙述文档。

## Relationship To Prose Rounds

从本 schema 生效起：

1. `telemetry/rounds.toml` 是 canonical raw carrier
2. `rounds/*.md` 退化为：
   - `legacy round notes`
   - 或 `human-readable supplements`

如果两者冲突：

1. 先看 checkpoint
2. 再看 scorecard summary
3. 再看 telemetry
4. 最后才回放 prose notes

## Acceptance Bar

一份 round telemetry 算合格，至少满足：

1. operator 不读 prose 也能回放每轮主要变化
2. reviewer 不会把 prose round 误当默认入口
3. exploration 与 exploit 都能被结构化追踪

## Residual Risk

1. 与未来真正的 `scorecard.toml` / `lineage.toml` 如何映射还需继续工程化
2. 部分任务可能需要更细的 per-lane telemetry

