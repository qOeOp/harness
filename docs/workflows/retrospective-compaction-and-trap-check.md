# Retrospective Compaction And Trap Check

更新日期：`2026-03-22`

## 目的

定义复盘如何压缩、守门和回流到下一次决策。

## 结构

1. `Raw Retros`
2. `Pattern Compactions`
3. `Active Trap Library`

## Layer 1: Raw Retros

作用：

- 保留每一笔被采纳交易的完整证据链、执行链、结果和复盘文本

规则：

1. append-only
2. 一笔交易一份 retro
3. 不作为默认推理上下文全量注入

## Layer 2: Pattern Compactions

作用：

- 把多个 raw retros 压缩成重复模式

例如：

1. 突破后追高，但缺少成交量确认
2. 宏观利空出现后 thesis 已弱化，却仍按旧计划加仓
3. 新闻 headline 和价格结构矛盾时，过度相信 headline

规则：

1. 由复利/学习流程周期性提炼
2. 多个相似 retro 合并成一个 pattern memo
3. pattern memo 必须回指原始 retros

## Layer 3: Active Trap Library

作用：

- 只保留当前最值得防范的“重复错误”

一个 trap 不是一句模糊提醒，而是一个可被检查的模式：

1. 触发条件
2. 常见伪信号
3. 典型后果
4. 反制检查项
5. 关联历史案例

## Anti-Repeat Debate

在新的交易计划进入正式输出前，不要把所有 raw retros 全部塞给主决策 agent。

更优结构是：

1. `Decision Agent`
   - 负责基于当前市场和证据链形成 thesis 与交易计划
2. `Retrospective Guardian`
   - 只读取压缩后的 pattern compactions 和 active trap library
   - 专门攻击当前计划是否落入旧陷阱

它们之间进行一轮针对性的辩论：

1. 当前计划最像哪类历史错误
2. 哪些反制检查项仍未满足
3. 这次为什么不是同一个坑
4. 如果无法证明不同，就输出 `blocked by trap risk` 或 `reduced confidence`

## 为什么不用全量复盘直接塞上下文

原因：

1. 成本高
2. 噪音大
3. 容易把无关历史模式误带入当前判断
4. 模型会被冗长、相互冲突的旧复盘污染

所以：

- 原始 retro 用来审计
- pattern compaction 用来总结
- active trap library 用来守门

## 何时压缩

建议至少两种节奏：

1. `per-trade`
   - 每笔被采纳交易后生成 raw retro
2. `periodic`
   - 每周或每 N 笔交易，提炼 pattern compactions 和 trap updates

## 输出要求

一个合格的 trap check 至少输出：

1. Relevant traps
2. Why this plan may repeat them
3. Why this plan is meaningfully different
4. Remaining unresolved trap risk
5. Final effect on confidence / risk / no-trade decision
