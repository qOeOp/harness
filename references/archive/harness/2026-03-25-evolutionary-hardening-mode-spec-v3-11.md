# Evolutionary Hardening Mode v3.11

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-10.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-10.md)
- Round focus:
  - pairwise scorecard baseline

## Why This Round

completeness gate 有了，但“更好”仍然没有被具体量化。

## Lane Signals

1. research lane：检查与 `pairwise scorecard baseline` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `pairwise scorecard baseline` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `pairwise scorecard baseline` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `pairwise scorecard baseline` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `pairwise scorecard baseline` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 规定每轮必须比较 `survivor_n-1` vs `survivor_n`。
2. 禁止只看当前绝对分。
3. scorecard 必须记录 previous/current/delta。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

我很确定，没有 pairwise，进化就只是自我感觉良好。

## Residual Risk

1. rubric 权重还未定
2. fatal violation severity 还未分层