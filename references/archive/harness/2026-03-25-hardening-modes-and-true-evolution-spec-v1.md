# Hardening Modes And True Evolution Spec v1

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready
- Purpose:
  1. 把 `Fast Hardening` 与 `True Evolutionary Hardening` 两种模式正式拆开。
  2. 纠正“批量生成多轮版本链”与“高保真串行进化”之间的混淆。
  3. 锁定：现有 [v2.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md) 只能作为 `Fast Hardening` 的产物，而不是已经完成的 `True Evolutionary` 结果。

## Divergent Hypotheses

1. `只保留一种 hardening mode`
   - 简单，但会持续把“快版多轮改稿”和“真进化”混在一起。
2. `把所有多轮都叫 evolutionary`
   - 听起来高级，实际上会稀释 mode 的含义。
3. `明确分成两种模式`
   - `Fast Hardening`
   - `True Evolutionary Hardening`
   - 各自有不同目标、不同合同、不同速度、不同可信度

## First Principles Deconstruction

1. 多轮 ≠ 进化
2. 只有当：
   - 每轮真的以上一轮 survivor 为输入
   - 每轮有明确 critic/research/eval 结果
   - 每轮有 selection
   - 每轮有 lineage
   - 每轮不能提前写死 agenda
   才能叫 `True Evolutionary Hardening`
3. 如果是：
   - 先铺好 20/50 个 hardening 主题
   - 再连续落盘
   - 最后做 integrated snapshot
   那它是高质量 hardening sprint，不是高保真 evolution

## Convergence To Excellence

正式采纳：

1. `Fast Hardening Mode`
2. `True Evolutionary Hardening Mode`

以后 harness 内所有“多轮迭代”都必须显式声明自己属于哪一种。

## Mode A: Fast Hardening

### Objective

快速探索问题空间，形成连续增强链和最终整合版。

### Best Fit

1. spec hardening
2. workflow hardening
3. governance surface audit
4. early-stage architecture exploration
5. 大范围主题铺陈

### Core Characteristics

1. agenda-driven
2. 可以提前定义 20/50 轮主题
3. 每轮是局部 delta，不要求严格评分
4. 最终通过 integrated snapshot 收束
5. 速度快，成本低

### Round Protocol

1. 设定 round focus
2. 生成局部强化点
3. 写 `Changes / Locked Principle / Residual Risk`
4. 串到下一版
5. 最终 compaction 成 integrated snapshot

### What It Produces

1. delta chain
2. hardening history
3. integrated snapshot

### What It Does Not Prove

1. 不证明每轮真的通过了独立 fitness
2. 不证明下一轮真由上一轮 scorecard 驱动
3. 不证明存在真实 selection pressure

### Truth Semantics

1. 它产生的是 `high-quality hardening chain`
2. 不是 `high-fidelity evolutionary survivor chain`

## Mode B: True Evolutionary Hardening

### Objective

让单一 canonical survivor 在真实研究、真实批评、真实评分、真实选择的压力下逐轮变强。

### Best Fit

1. high-value canonical spec
2. review rubric
3. workflow kernel
4. schema design
5. migration contract
6. researcher capability evolution

### Canonical Model

`single canonical survivor + bounded candidate population + structured mutation + rubric-driven selection`

### Non-Negotiable Properties

1. 任何时刻只有一个 canonical survivor
2. 每轮输入必须包含：
   - `survivor_n`
   - `invariants`
   - `rubric`
   - `scorecard_n`
   - `residual_risks_n`
   - `rejected_deltas_n`
3. 每轮必须经过：
   - research
   - critique
   - scoring
   - selection
   - lineage writeback
4. 不允许预写 50 轮 agenda
5. 不允许全文自由交配
6. 不允许跳过 scorecard 直接晋升新 survivor

### Five Fixed Lanes

True mode 默认至少开 5 条 lane：

1. `research lane`
   - 找外部证据、反例、冲突 source
2. `structure lane`
   - 检查定义、边界、分层和 SRP
3. `evaluation lane`
   - 维护 rubric、pairwise comparison、fitness
4. `lineage lane`
   - 维护 provenance、accepted/rejected deltas、checkpoint
5. `safety lane`
   - 检查 drift、budget、stop conditions、termination

### Round Protocol

每一轮固定为：

1. `Load`
   - 读取 `survivor_n`
   - 读取 `scorecard_n`
   - 读取 `residual_risks_n`
2. `Research`
   - 5 条 lane 分别做针对性研究或批评
3. `Propose`
   - 生成 `3-5` 个结构化 candidate deltas
4. `Critique`
   - 每条 lane 对 candidate 打结构化反馈
5. `Score`
   - 形成多维 scorecard
6. `Select`
   - 选出 `survivor_n+1`
7. `Writeback`
   - 记录 accepted deltas / rejected deltas / why this version won
8. `Checkpoint`
   - 每 5 或 10 轮做 integrated checkpoint

### Mutation Operators

只允许有限变异：

1. tighten constraint
2. split overloaded concept
3. add missing gate
4. simplify conflicting rule
5. add fixture or eval surface
6. upgrade residual risk into invariant

### Crossover Operators

只允许 section-level / contract-level crossover：

1. merge stronger section from candidate A
2. merge stronger gate definition from candidate B
3. merge stronger rubric language from candidate C

禁止：

1. 全文自由拼接
2. 无 lineage 的整篇重写

### Fitness Rubric

至少按以下维度打分：

1. correctness
2. determinism
3. safety
4. operator usability
5. compounding value
6. rolloutability
7. cost / complexity discipline

### Selection Rule

1. 先满足 invariants
2. 再比较 weighted score
3. 再比较 residual risk
4. 再看是否引入新 drift
5. 最终只晋升一个 canonical survivor

### Termination Rule

必须至少包含：

1. `max_rounds`
2. `plateau detection`
3. `oscillation detection`
4. `budget stop`
5. `catastrophic drift stop`

### Truth Semantics

True mode 的版本链才可以宣称：

`每一轮真的以旧 survivor 为输入，在选择压力下串行进化。`

## Comparison

### Fast Hardening

1. 快
2. 可大批量
3. 适合铺问题空间
4. 最终一定要 compaction
5. 不能冒充高保真进化

### True Evolutionary Hardening

1. 慢
2. 串行
3. 每轮都要真实批评和评分
4. 对 lineage 和 rubric 要求极高
5. 成本高，但可信度也高

## Redo Policy For The Current Task

当前已存在的 [v2.50](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-self-governing-agent-company-harness-spec-v2-50.md) 定位调整如下：

1. 它是 `Fast Hardening Mode` 的 integrated snapshot
2. 它不是已经完成的 `True Evolutionary Hardening` 最终版
3. 它可以作为 `True Evolutionary` 的种子
4. 后续真正重做时，必须开启新的 lineage，而不是复用 `v2.xx` 的 truth semantics

## Required Redo Rule

如果要用 `True Evolutionary Hardening` 重做刚才那项任务，必须遵守：

1. 从新的 seed 版本起跑
2. round 01 真的读取 seed
3. round 02 真的读取 round 01 的 survivor 和 scorecard
4. 后续每轮都串行推进
5. 不允许先写好 50 轮 agenda 再批量落盘

## Naming Rule

建议命名：

1. `Fast Hardening` 继续沿现有 `v2.xx` 语义
2. `True Evolutionary` 开新 lineage，例如：
   - `v3.00 seed`
   - `v3.01`
   - `v3.02`
   - ...

## Immediate Next Move

下一步不再继续生成抽象讨论，而是：

1. 创建 `True Evolutionary Hardening Seed`
2. 固定 invariants
3. 固定 rubric
4. 固定 5 条研究/批评 lane
5. 再开始真正的慢速串行进化

## Locked Principle

`Fast Hardening` 可以快，  
`True Evolutionary Hardening` 必须真。

## Residual Risk

1. `True Evolutionary` 的 round schema 还未独立落盘
2. scorecard / lineage / rejected delta 的具体格式还未定稿
3. plateau rule 与 budget rule 还未写成 machine-readable contract
