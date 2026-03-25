# Evolutionary Hardening Mode v3.08

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-07.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-07.md)
- Round focus:
  - round directory layout

## Why This Round

operators 冻结后，round artifact 仍然没有具体承载路径。

## Lane Signals

1. research lane：检查与 `round directory layout` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `round directory layout` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `round directory layout` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `round directory layout` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `round directory layout` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 定义 round root 至少包含 `survivor / candidates / scorecard / accepted / rejected / residual / why-won / lane-outputs`。
2. round 目录禁止存放未分类临时草稿。
3. checkpoint artifact 与普通 round artifact 分层。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

一旦目录明确，模式开始从“思维框架”变成“文件系统里的机器”。

## Residual Risk

1. 输入加载顺序还未固定
2. 输出最小集还未说明缺失处理