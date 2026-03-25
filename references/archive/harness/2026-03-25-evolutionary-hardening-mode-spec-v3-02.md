# Evolutionary Hardening Mode v3.02

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-01.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-01.md)
- Round focus:
  - run root and run identity

## Why This Round

上一轮把 mode 拆成了执行对象，但 run 自己还没有身份边界。没有 run identity，lineage 很快会乱。

## Lane Signals

1. research lane：检查与 `run root and run identity` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `run root and run identity` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `run root and run identity` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `run root and run identity` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `run root and run identity` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 定义每次 true evolution 必须有唯一 `run_id`。
2. 定义 run root 至少包含 `seed / invariants / rubric / rounds / checkpoints / reflections`。
3. 规定任何 round artifact 都必须带 `run_id` 与 `round_id`。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

真正开始串行后，我更强烈地感觉：没有 run identity，就没有 evolution，只有一堆文件。

## Residual Risk

1. lane charter 还未定稿
2. candidate budget 还未固定