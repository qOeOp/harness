# Evolutionary Hardening Scorecard Summary Schema v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: active
- Depends on:
  - [2026-03-25-true-evolution-scorecard-schema-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolution-scorecard-schema-v1.md)
  - [2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-entropy-compression-spec-v1.md)

## Divergent Hypotheses

1. reviewer 直接读完整 `scorecard.toml`。
2. checkpoint 已经足够，不需要单独 scorecard summary。
3. 在完整 scorecard 与 checkpoint 之间增加一个薄的 reviewer-facing `scorecard summary`。

## First Principles Deconstruction

1. 完整 scorecard 是 machine-readable 和 operator-facing 的，不适合 reviewer 首跳。
2. checkpoint 负责压缩 lineage，不专门负责表达本轮评分与晋升判断。
3. 如果没有薄 summary，reviewer 要么去读 TOML，要么去读长 prose，都不优雅。
4. scorecard summary 的职责是回答：
   - 这版为什么赢
   - 赢在哪
   - 付出了什么代价
   - exploration 有没有产生价值

## Convergence To Excellence

采纳第 `3` 条路线。

`Scorecard Summary` 被定义为：

`checkpoint 与完整 scorecard 之间的 reviewer-facing bridge`

## Canonical Objective

scorecard summary 不是为了替代完整分数，而是为了让 reviewer 快速理解：

1. pairwise 结果
2. 晋升理由
3. 关键倒退和代价
4. exploration / exploit 的结果
5. 当前是否应继续、checkpoint、还是停止

## Placement Rule

正式执行面建议放在：

1. `.harness/evolution/runs/<run-id>/checkpoints/scorecard-summary-<checkpoint-id>.md`

dogfood 期允许：

1. `.harness/workspace/runs/<run-id>/checkpoints/<date>-<target>-scorecard-summary-<checkpoint-id>.md`

## Required Header Fields

1. `Run id`
2. `Checkpoint id`
3. `Parent survivor`
4. `Current survivor or candidate`
5. `Decision`
6. `Comparison basis`

## Required Sections

至少包含：

1. `Pairwise Verdict`
2. `Dimension Summary`
3. `Exploit vs Exploration Outcome`
4. `Promotion Decision`
5. `Key Costs And Tradeoffs`
6. `Residual Risks`
7. `Recommended Next Move`

## Pairwise Verdict Contract

必须明确回答：

1. 当前 survivor / candidate 是否优于 parent
2. 是局部提升还是结构性提升
3. 哪几个维度最关键

不允许只写“整体更好”。

## Dimension Summary Contract

不要求重复所有数值，但至少要压缩：

1. `correctness`
2. `determinism`
3. `safety`
4. `operator usability`
5. `compounding value`
6. `rolloutability`
7. `complexity discipline`

每个维度只需说明：

1. improved
2. stable
3. regressed

必要时再解释原因。

## Exploit vs Exploration Outcome

这是新加入的强制段落。

每个 summary 都必须回答：

1. 本 checkpoint 的 exploit 候选贡献了什么
2. 本 checkpoint 的 exploration 候选贡献了什么
3. exploration 是否真正产生增益，还是被 reject

如果没有这段，这套机制就还只是高约束优化器。

## Promotion Decision Contract

必须明确写出以下之一：

1. `promote`
2. `hold`
3. `checkpoint-and-continue`
4. `stop`

并说明原因。

## Key Costs And Tradeoffs

必须明确当前版本的代价，例如：

1. 可读性提升但复杂度上升
2. correctness 提升但 rolloutability 暂时下降
3. exploration 带来新 framing 但确定性暂时变弱

没有代价说明的 summary，不可信。

## Anti-Bloat Rule

scorecard summary 禁止：

1. 复制 checkpoint 全文
2. 复制完整 TOML
3. 再次叙述全部 round history

summary 越像：

`结构化晋升判决书`

越对。

## Acceptance Bar

一份 scorecard summary 算合格，至少满足：

1. reviewer 读完后知道为什么当前版本赢
2. reviewer 能看见 exploration 是否有价值
3. reviewer 不需要打开完整 scorecard 就能决定是否继续读 candidate

## Residual Risk

1. 具体与 TOML 的字段映射仍待后续工程化
2. 不同任务类型是否需要不同维度摘要模板还未定稿

