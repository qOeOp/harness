# Evolutionary Hardening Mode v3.49

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: checkpoint-survivor
- Parent survivor:
  - [2026-03-25-evolutionary-hardening-mode-spec-v3-48.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-evolutionary-hardening-mode-spec-v3-48.md)
- Round focus:
  - real run directory activation plan

## Why This Round

`v3.48` 已经把 mode 的内部合同压到接近完整，但它还停留在“模式规范”。  
如果没有真实 run directory activation plan，mode 仍然不能被稳定执行。

## Lane Signals

1. research lane：检查真实实验追踪、artifact lineage、fixture 目录组织的成熟实践，避免 run 目录沦为杂物箱。
2. structure lane：检查 run root、round root、checkpoint root、archive root 的边界是否清晰。
3. evaluation lane：检查真实 run 之后 scorecard、plateau、promotion 信号如何进入执行面。
4. lineage lane：检查 run directory 是否能承接 accepted/rejected/provenance/checkpoint 的全链条。
5. safety lane：检查 run activation 是否引入隐式 truth、并发污染或半初始化状态。

## Candidate Deltas Considered

1. 只在文档里建议 run root，继续不落实际目录。
2. 定义最小 run directory plan，但不触碰 truth hierarchy。
3. 直接把 `.harness/evolution/runs/` 作为实时 source of truth 激活。

## Selected Mutation

1. 采纳第 2 条路线：先定义 `run directory activation plan`，不在本轮冒然把运行真相从 archive spec 直接切到 `.harness/evolution/runs/`。
2. 明确真实运行目录最小结构：
   - `.harness/evolution/runs/<run-id>/seed/`
   - `.harness/evolution/runs/<run-id>/rounds/<round-id>/`
   - `.harness/evolution/runs/<run-id>/checkpoints/`
   - `.harness/evolution/runs/<run-id>/archive/`
   - `.harness/evolution/runs/<run-id>/reflections/`
3. 规定 run activation 必须先经过：
   - bootstrap-state detection
   - doctor green
   - seed freeze
   - run-id allocation

## Pairwise Outcome

本轮 survivor 相对 parent survivor 的主要提升是：

1. 把“mode 能跑”从抽象承诺推进到了真实目录计划。
2. 没有把 archive-based spec truth 与 future run-time truth 混成一层。
3. 为 `v3.50` 最终整合版补上了最后一个缺口。

## Operator Reflection

跑到这里，我最明显的感受是：  
真正阻碍 mode 落地的，从来不是概念不够丰富，而是“最后一步怎么启动”往往没有被认真写下来。`v3.49` 其实就是把这最后一步从想当然变成协议。

## Checkpoint Note

本轮作为 intermediate checkpoint，职责是：

1. 把 mode 的静态规范与真实 run activation 之间的断层补上
2. 明确真实运行目录的最小布局
3. 为最终 integrated survivor 清掉最后的启动面残余风险

## Residual Risk

1. 还没有一个把前 49 轮全部收束进单一 mode 正文的最终 survivor
2. 真实 run 的第一次 dogfood 执行仍需在最终版中锁定
