# Evolutionary Hardening Mode v3.38

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-37.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-37.md)
- Round focus:
  - eval harness integration

## Why This Round

fixture mapping 有了，但还缺真正的 eval harness 入口。

## Lane Signals

1. research lane：检查与 `eval harness integration` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `eval harness integration` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `eval harness integration` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `eval harness integration` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `eval harness integration` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 定义 true mode 可接 eval harness。
2. eval 输出进入 scorecard，不单独漂浮。
3. trace grading 作为 evaluation lane 的补充输入。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

这一步把外部评测真正接进来了，mode 的可信度上了一个层级。

## Residual Risk

1. pairwise vs absolute score conflict 还未处理
2. survivor 可读性还未单独保护