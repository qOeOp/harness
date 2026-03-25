# Company OS / Product Runtime / Data Map

更新日期：`2026-03-23`

## 目的

区分公司 OS、产品 runtime 和 data layer，避免把组织结构错误投影成产品结构。

## 三层定义

1. `Company OS`
   - 给 coding agents 用的组织脚手架
   - 负责研发、治理、迭代、review、发布
2. `Product Runtime`
   - 最终用户真正使用时，产品内部运行的角色和链路
   - 负责在一次请求或一轮监控触发中生成结果
3. `Data Layer`
   - Runtime 读取和写回的账本、快照、模式库、状态对象

## 核心原则

1. 不是每个产品 runtime role 都需要一个独立部门
2. 不是每个公司部门都需要一个对外可见的产品概念
3. runtime 角色应该尽量少，部门职责可以更稳定和长期
4. data objects 是第一公民，runtime 和部门都只是围绕它们工作

## 三层映射表

| Company OS Owner | Product Runtime Role | Primary Data Objects | Notes |
| --- | --- | --- | --- |
| Market Intelligence Department | `evidence collector` / `source verifier` / `narrative updater` | source notes, evidence events, narrative events, source credibility records | 负责接外部世界，不直接给最终交易计划 |
| Strategy Research Department | `decision agent` / `thesis synthesizer` | thesis cards, trade plans, counter-evidence sets, confidence rationale | 主决策链 owner |
| Position Operations Department | `monitor engine` / `trigger evaluator` / `state updater` | monitored setups, trigger rules, position states, decision update events, snapshots | 负责持仓期和监控期的 runtime 更新 |
| Risk Office | `risk gate` / `plan auditor` / `retrospective guardian` | risk reviews, stop conditions, trap-check verdicts, risk-adjusted recommendations | `guardian` 是 runtime 角色，不是单独部门 |
| Learning & Evolution Department | `retro compactor` / `trap curator` | raw retros, pattern compactions, active trap library, playbook updates | 负责把复盘压缩成可复用防线 |
| Chief of Staff | 无直接长期 runtime 角色 | founder-facing briefs, execution plans, escalation decisions | 属于公司操作层，不是产品运行时组件 |
| Product Thesis Lead | 无直接长期 runtime 角色 | product hypotheses, scope boundaries, acceptance criteria | 决定做什么，不直接参与每次产品推理 |
| Knowledge & Memory Lead | `ledger steward`（偏系统维护，不是用户可见角色） | decision ledger, narrative ledger, snapshots, canonical mappings | 保障数据层一致性与可追溯性 |
| Workflow & Automation Lead | `runtime orchestrator designer`（研发态，不是业务态） | pipelines, hooks, commands, scheduling config | 设计 runtime，不直接扮演产品角色 |
| Compounding Engineering Lead | 无直接长期 runtime 角色 | process audits, workflow experiments, governance proposals | 优化做法，不直接做用户态决策 |

## Guardian 的位置

`retrospective guardian` 的正确位置是：

1. **产品 runtime 角色**
   - 在正式输出交易计划前，对当前计划做 anti-repeat debate
2. **Company OS ownership**
   - 主要由 `Risk Office` 拥有使用逻辑
   - 由 `Learning & Evolution` 提供 trap library 输入
3. **Data layer dependency**
   - active trap library
   - pattern compactions
   - linked raw retros

因此第一阶段更适合把它做成 risk gate 里的按需 runtime step，而不是新部门。

## 推荐 runtime pipeline

```text
external evidence
  -> evidence collector / source verifier
  -> decision agent
  -> risk gate
  -> retrospective guardian
  -> final trade plan or no-trade
  -> monitor engine
  -> decision update events
  -> raw retro
  -> pattern compaction
  -> active trap library refresh
```

## 推荐数据对象

最小集合建议分成 6 类：

1. `Evidence Event`
   - 新闻、价格、指标、宏观、链上等
2. `Narrative Event`
   - 叙事延续、叙事反转、冲突叙事
3. `Thesis Card`
   - 当前交易命题及其证据、反证、invalidation
4. `Decision Event`
   - 新建计划、更新计划、风险调整、no-trade、失效判定
5. `State Snapshot`
   - 任意时点的完整判断视图
6. `Retro / Trap Objects`
   - raw retros, pattern compactions, active trap library

## 设计边界

1. 不要因为产品里有一个 runtime 角色，就给公司 OS 新建一个部门
2. 不要让公司 OS 的所有角色都进入产品运行时
3. 第一版应优先保证 `runtime 简洁`，而不是 `组织结构对称`
