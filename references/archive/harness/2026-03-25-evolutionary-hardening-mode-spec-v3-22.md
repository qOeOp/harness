# Evolutionary Hardening Mode v3.22

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: round-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-21.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-21.md)
- Round focus:
  - catastrophic drift gate

## Why This Round

预算已经受控，但模式还缺最硬的 kill switch。

## Lane Signals

1. research lane：检查与 `catastrophic drift gate` 相关的一手资料、反例、矛盾 source 与 freshness 约束，确认本轮变更不是闭门造车。
2. structure lane：检查 `catastrophic drift gate` 是否让模式更模块化、更清晰，是否减少概念过载与边界混淆。
3. evaluation lane：检查 `catastrophic drift gate` 是否能进入 rubric / pairwise score / gating，而不是停留在口号。
4. lineage lane：检查 `catastrophic drift gate` 是否留下可追溯的 accepted/rejected/provenance 记录。
5. safety lane：检查 `catastrophic drift gate` 是否引入 drift、无限循环、静默覆盖、预算失控或 kill-switch 缺失。

## Candidate Deltas Considered

1. 保守收紧：只补最小缺口，不扩大 mode 表面。
2. 平衡增强：在不破坏 invariants 的前提下补齐本轮合同。
3. 激进扩展：把本轮主题做成更宽的能力面。

## Selected Mutation

1. 定义 catastrophic drift：破坏 invariant、破坏 single survivor、破坏 replayability。
2. 一旦触发立即 stop。
3. stop 后只允许 doctor/repair/meta-review。

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 本轮 focus 从“隐含约定”提升成“显式合同”。
2. 本轮 selected mutation 都没有触碰 frozen invariants。
3. parent 的主要残余风险被转化成了更窄的下一轮输入。

## Operator Reflection

到这一步，系统终于有了“不能碰”的东西，这很重要。

## Residual Risk

1. research lane protocol 还未定
2. structure lane 还未协议化