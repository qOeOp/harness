# Evolutionary Hardening Mode v3.06

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-05.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-05.md)
- Round focus:
  - mutation operator taxonomy

## Why This Round

invariant registry 有了，但 candidate 仍然可能以任意形式变异。要先限制“允许怎样变”。

## Lane Signals

1. research lane：检查与 `mutation operator taxonomy` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `mutation operator taxonomy` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `mutation operator taxonomy` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `mutation operator taxonomy` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `mutation operator taxonomy` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 冻结 6 类 mutation：tighten、split、add gate、simplify、add fixture、promote risk to invariant。
2. 禁止“整篇重写”作为普通 mutation。
3. 每个 candidate 必须声明自己使用的是哪类 operator。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

进化最危险的不是变异太少，而是变异没有名字。没有名字就无法比较。

## Residual Risk

1. crossover 规则仍未定
2. round 目录布局还未落地