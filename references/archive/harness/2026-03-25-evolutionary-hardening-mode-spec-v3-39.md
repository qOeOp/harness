# Evolutionary Hardening Mode v3.39

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-38.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-38.md)
- Round focus:
  - pairwise vs absolute score conflict resolution

## Why This Round

现在既有 absolute rubric，又有 pairwise compare，冲突时谁优先还不清楚。

## Lane Signals

1. research lane：检查与 `pairwise vs absolute score conflict resolution` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `pairwise vs absolute score conflict resolution` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `pairwise vs absolute score conflict resolution` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `pairwise vs absolute score conflict resolution` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `pairwise vs absolute score conflict resolution` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 默认 pairwise 决定晋升，absolute 决定健康度。
2. 若 pairwise 胜但 absolute 健康度恶化，必须触发 review。
3. 把冲突写进 why-won。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

系统越复杂，冲突越多。关键不是消灭冲突，而是别偷偷忽略它。

## Residual Risk

1. survivor readability 还未守护
2. no-fork truth 还未写明