# Evolutionary Hardening Mode v3.50

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready integrated survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-49.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-49.md)
- Purpose:
  1. 把 `v3.00 -> v3.49` 的串行进化结果收束成单一 canonical survivor。
  2. 正式定义 harness 内的 `True Evolutionary Hardening` 高级工作模式。
  3. 让该模式本身具备：可启动、可评分、可追溯、可终止、可复利、可被下一轮继续进化。

## Divergent Hypotheses

1. `Evolutionary Hardening` 只是更慢的多轮改稿。
2. `Evolutionary Hardening` 应该像自由基因算法一样大规模候选乱交配。
3. `Evolutionary Hardening` 应该是：
   - 单 survivor
   - 有限 candidate population
   - 结构化 mutation / crossover
   - pairwise scorecard
   - lineage-first writeback
   - checkpoint compaction
   - fail-closed termination

## First Principles Deconstruction

1. 复杂任务之所以难，不是因为没有更多想法，而是因为：
   - 没有统一 survivor
   - 没有稳定评分
   - 没有失败记忆
   - 没有终止条件
   - 没有把“上一轮为什么赢”写下来
2. 如果 mode 不能解释：
   - 为什么当前版本是 canonical
   - 为什么不是另一个候选
   - 为什么此时应该继续还是停止
   那它就不是进化系统，只是多轮改稿系统。
3. 因此最优解不是“更多 agent 聊更多轮”，而是“让每一轮在选择压力下留下足够硬的痕迹”。

## Convergence To Excellence

采纳第 3 条路线，正式定义：

`Evolutionary Hardening Mode v3.50`

## Canonical Objective

该 mode 的目标不是生成很多版本，而是：

1. 让单一 canonical survivor 在多轮选择压力下变强
2. 让每轮输出真正成为下一轮输入
3. 让复杂任务在受控 research、critique、score、selection 中持续逼近更优解
4. 让整个过程可回放、可审计、可压缩、可终止

## Relation To Other Modes

### Fast Hardening

1. agenda-driven
2. 可以提前定义轮次主题
3. 更适合快速铺问题空间
4. 产出的是高质量 hardening chain

### True Evolutionary Hardening

1. survivor-driven
2. 不允许预写长轮 agenda
3. 每轮都必须有真实 round artifacts
4. 产出的是高保真 survivor chain

## Canonical Model

`single canonical survivor + bounded candidate population + structured mutation + eval-driven selection + lineage-first writeback`

## Non-Negotiable Properties

1. 任何时刻只有一个 canonical survivor
2. 每轮必须同时存在：
   - `survivor_n`
   - `scorecard_n`
   - `accepted_deltas_n`
   - `rejected_deltas_n`
   - `residual_risks_n`
   - `why_this_version_won_n`
3. 不允许预写 50 轮 agenda 后批量落盘冒充真进化
4. 不允许全文自由交配
5. 不允许跳过 scorecard 与 selection 直接晋升新 survivor
6. schema 升级只能在 checkpoint 或 meta-round 发生

## Frozen Invariants

当前 mode 运行时默认不得破坏：

1. single canonical survivor
2. deterministic round inputs
3. lineage-first writeback
4. fail-closed safety gates
5. append-only historical memory
6. checkpoint compaction instead of silent overwrite
7. explicit termination rules

## Five Fixed Lanes

### 1. Research Lane

职责：

1. source discovery
2. contradiction detection
3. freshness discipline
4. claim extraction

不负责：

1. 直接决定 survivor

### 2. Structure Lane

职责：

1. 检查边界
2. 检查分层
3. 检查概念过载
4. 提供结构化 mutation target

### 3. Evaluation Lane

职责：

1. 维护 rubric
2. 维护 pairwise comparison
3. 生成 scorecard
4. 检测 plateau / oscillation

### 4. Lineage Lane

职责：

1. 维护 accepted/rejected deltas
2. 维护 provenance
3. 维护 checkpoint lineage
4. 保证进化可回放

### 5. Safety Lane

职责：

1. 检查 drift
2. 检查 budget
3. 检查 termination
4. 执行 catastrophic stop veto

## Round Machine

每轮固定 8 步：

1. `Load`
2. `Research`
3. `Propose`
4. `Critique`
5. `Score`
6. `Select`
7. `Writeback`
8. `Checkpoint`

## Round Inputs

每轮至少读取：

1. `survivor_n-1`
2. `scorecard_n-1`
3. `residual_risks_n-1`
4. `accepted_deltas_n-1`
5. `rejected_deltas_n-1`
6. current invariants
7. current rubric

禁止：

1. 只看上一轮 survivor
2. 忽略 rejected delta 历史
3. 忽略 residual risk 直接重写

## Candidate Population

### Budget

每轮默认只允许：

1. `1` 个 canonical survivor
2. `3-5` 个 candidate deltas

### Mutation Operators

只允许：

1. tighten constraint
2. split overloaded concept
3. add missing gate
4. simplify conflicting rule
5. add fixture / eval surface
6. promote residual risk into invariant

### Crossover Operators

只允许：

1. section-level merge
2. contract-level merge

禁止：

1. 全文自由拼接
2. 无 provenance 的 donor 片段注入

## Scorecard

### Required Dimensions

至少包含：

1. correctness
2. determinism
3. safety
4. operator usability
5. compounding value
6. rolloutability
7. complexity discipline

### Pairwise Rule

每轮必须显式比较：

1. `survivor_n-1`
2. `survivor_n`

### Weighting Rule

高权重：

1. correctness
2. determinism
3. safety

中高权重：

1. operator usability
2. compounding value
3. rolloutability
4. complexity discipline

### Conflict Rule

当 pairwise 与 absolute score 冲突时：

1. pairwise 决定是否晋升
2. absolute health 决定是否必须插入 review / red-team / checkpoint

## Selection Rule

晋升 survivor 的顺序固定为：

1. 先过 invariants
2. 再看 weighted score
3. 再看 residual risk
4. 再看 drift / complexity penalty
5. 最终只选 top-1

## Writeback Contract

每轮必须写：

1. accepted deltas
2. rejected deltas
3. residual risks
4. why this version won
5. operator reflection

### Operator Reflection

负责人的感想是合法 artifact，但必须：

1. 只表达观察、偏好变化、疑虑
2. 不得冒充 scorecard
3. 不得覆盖 invariants

## Checkpoint Contract

每 `5` 或 `10` 轮必须 checkpoint。

checkpoint 的职责：

1. 压缩最近若干轮 accepted deltas
2. 提升当前 survivor 的可读性
3. 重新列出 invariants
4. 重新列出 residual risks
5. 记录 schema versions 与 migration notes

## Lineage Contract

lineage 必须回答：

1. 当前 survivor 从谁进化而来
2. 为什么它赢
3. 哪些 candidate 被拒绝
4. 当前风险是什么
5. 如果回放，应该怎么重建

没有 lineage，就没有进化，只有覆盖写。

## Safety And Termination

### Plateau

连续若干轮提升低于阈值时触发 plateau。

### Oscillation

关键维度来回摆动时触发 oscillation。

### Budget Stop

超预算后只能：

1. split
2. checkpoint
3. stop

### Catastrophic Drift

一旦破坏：

1. single survivor
2. replayability
3. fatal invariants

则立刻 stop。

## Dogfood And Promotion

### Dogfood

mode 自己也必须先被 dogfood：

1. 允许更多 telemetry
2. 不改变 truth semantics
3. learnings 回流 mode spec

### Promotion

进入主 harness 流程至少满足：

1. fixtures green
2. plateau stable
3. no fatal drift
4. promotion rationale 已记录

## Real Run Activation

真实运行目录最小结构：

1. `.harness/evolution/runs/<run-id>/seed/`
2. `.harness/evolution/runs/<run-id>/rounds/<round-id>/`
3. `.harness/evolution/runs/<run-id>/checkpoints/`
4. `.harness/evolution/runs/<run-id>/archive/`
5. `.harness/evolution/runs/<run-id>/reflections/`

run activation 先决条件：

1. bootstrap-state detection
2. doctor green
3. seed freeze
4. run-id allocation

## What This Mode Is Good For

1. high-value canonical spec
2. review rubric
3. workflow kernel
4. schema design
5. migration contract
6. researcher capability evolution

## What This Mode Is Not For

1. 简单 bugfix
2. 紧急事故
3. 无 rubric 的主观小任务
4. 没有 fixture 或 eval 的高风险 production code 自由改写

## Operator Reflection After 50 Rounds

这 50 轮里，我最明显的感受有三条：

1. 真进化最难的不是提出更好的候选，而是让“为什么这个候选赢”变得可解释。
2. 一旦把 rejected delta、residual risk、checkpoint、lineage 都钉死，模式的气质会从“聪明的讨论”变成“可信的系统”。
3. 你说得对，researcher 不只是外部辅助，它本身就是这套 mode 以后最值得继续进化的器官。

## Immediate Next Move

下一步不是继续写 mode 文档，而是：

1. 启动第一个真实 run directory
2. 选择一个真实高价值对象作为 evolved target
3. 让 `v3.50` 从“mode 规范”进入“mode 执行”

## Residual Risk

1. 真实 run directory 还未启用
2. 第一个实际 evolved target 还未指定
3. fixture/eval 的执行面仍需继续工程化
