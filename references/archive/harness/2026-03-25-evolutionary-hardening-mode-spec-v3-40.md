# Evolutionary Hardening Mode v3.40

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: checkpoint-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-39.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-39.md)
- Round focus:
  - survivor readability and anti-bloat

## Why This Round

50 轮进化很容易把 survivor 变成不可读巨物，必须反向约束。

## Lane Signals

1. research lane：检查与 `survivor readability and anti-bloat` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `survivor readability and anti-bloat` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `survivor readability and anti-bloat` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `survivor readability and anti-bloat` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `survivor readability and anti-bloat` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 新增 readability guard。
2. 任何显著增厚都要解释。
3. 允许通过 split and compress 来提升 clarity。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

我在看前几轮积累时，已经能感觉到膨胀风险了。反膨胀不是美学，是生存条件。

## Checkpoint Note

本轮作为 intermediate checkpoint，职责是：

1. 压缩最近若干轮 accepted deltas
2. 提升当前 survivor 的可读性
3. 重新列出 invariants 与 residual risks

## Residual Risk

1. no-fork truth 还未定义
2. recovery/replay for failed round 还未细化