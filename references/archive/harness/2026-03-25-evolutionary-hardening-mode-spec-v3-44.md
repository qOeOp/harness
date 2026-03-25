# Evolutionary Hardening Mode v3.44

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-43.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-43.md)
- Round focus:
  - dogfood mode for evolutionary runs

## Why This Round

如果这个模式以后真成大杀器，它自己也需要 dogfood 轨道。

## Lane Signals

1. research lane：检查与 `dogfood mode for evolutionary runs` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `dogfood mode for evolutionary runs` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `dogfood mode for evolutionary runs` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `dogfood mode for evolutionary runs` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `dogfood mode for evolutionary runs` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 定义 evolutionary runs 的 dogfood mode。
2. dogfood 允许更多 telemetry，但不改变核心 truth semantics。
3. dogfood learnings 必须回流 mode spec。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

我开始把这个 mode 当产品看了。产品就要先被自己用坏。

## Residual Risk

1. release criteria 还未清
2. archive/prune 还未处理