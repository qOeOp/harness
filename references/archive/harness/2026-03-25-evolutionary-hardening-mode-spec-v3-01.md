# Evolutionary Hardening Mode v3.01

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-true-evolutionary-hardening-seed-v3-00.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-true-evolutionary-hardening-seed-v3-00.md)
- Round focus:
  - seed audit and decomposition

## Why This Round

seed v3.00 仍然过于抽象，第一轮必须先判断 imported seed 在执行面上哪里最粗、最不可操作。

## Lane Signals

1. research lane：检查与 `seed audit and decomposition` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `seed audit and decomposition` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `seed audit and decomposition` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `seed audit and decomposition` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `seed audit and decomposition` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 把 seed 明确拆成 `run / round / score / lineage / checkpoint / termination` 六个执行对象。
2. 禁止在 round-01 直接追求“更完整的最终 spec”，先追求“更可执行的 mode”。
3. 冻结 `v2.50 只是 parent seed，不是当前 survivor truth`。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

第一眼看 seed，最明显的问题不是方向错，而是过于像“宣言”。如果不先把它压成可操作对象，后面每轮都会滑回抽象写作。

## Residual Risk

1. run root 还未定义
2. lane 的职责还只停留在命名上