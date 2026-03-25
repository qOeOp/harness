# Evolutionary Hardening Mode v3.03

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-02.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-02.md)
- Round focus:
  - lane charter freeze

## Why This Round

run 身份有了，但 5 条 lane 如果没有固定 charter，后面每轮的 critic 仍然会漂。

## Lane Signals

1. research lane：检查与 `lane charter freeze` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `lane charter freeze` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `lane charter freeze` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `lane charter freeze` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `lane charter freeze` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 把 5 条 lane 固定为 `research / structure / evaluation / lineage / safety`。
2. 每条 lane 只允许一种主要职责，不搞全能 reviewer。
3. lane 输出默认只接受结构化反馈，不接受纯散文意见。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

我越来越确定，强系统不是“更多聪明 agent”，而是“更少、更硬的 lane”。

## Residual Risk

1. candidate pool 还未收紧
2. mutation operator 还未限定