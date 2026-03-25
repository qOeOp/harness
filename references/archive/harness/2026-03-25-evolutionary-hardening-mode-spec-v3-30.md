# Evolutionary Hardening Mode v3.30

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: checkpoint-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-29.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-29.md)
- Round focus:
  - red-team insertion rule

## Why This Round

没有对抗轮次，系统容易自我陶醉。

## Lane Signals

1. research lane：检查与 `red-team insertion rule` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `red-team insertion rule` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `red-team insertion rule` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `red-team insertion rule` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `red-team insertion rule` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 每 5 轮或出现 oscillation 时插入 red-team。
2. red-team 专门找结构性漏洞和盲区。
3. red-team 不负责定稿，只负责破坏性测试。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

红队的价值不在反对，而在阻止我们对当前 survivor 产生幻觉。

## Checkpoint Note

本轮作为 intermediate checkpoint，职责是：

1. 压缩最近若干轮 accepted deltas
2. 提升当前 survivor 的可读性
3. 重新列出 invariants 与 residual risks

## Residual Risk

1. evidence/source integration 还未细化
2. research freshness 还未与 round 相连