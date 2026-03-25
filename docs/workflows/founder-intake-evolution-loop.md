# Founder Intake Evolution Loop

更新日期：`2026-03-22`

## 问题背景

Founder 会持续提供：

- 文章
- 视频
- 别人的交易思路
- 自己的临时直觉
- 对公司流程和策略的主观质疑

这些输入如果直接打到各部门，会造成：

1. 部门被频繁打断
2. 同一个材料被重复研究
3. 没有人对“是否采纳”负责
4. 好想法无法制度化沉淀

## 收敛结论

Founder 输入必须有统一入口。

统一入口是：

`Learning & Evolution Department`

## Loop

### Step 1: Intake

Founder 输入进入：

- `.harness/workspace/intake/inbox/`

模板：

- [docs/templates/material-intake.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/material-intake.md)

### Step 2: Triage

Owner: `Learning & Evolution Department`

分成 4 类：

1. `Discard`
   - 噪音高
   - 不适配当前阶段
   - 没有可执行价值

2. `Observe`
   - 值得记录
   - 暂不值得投入研究

3. `Research`
   - 指派相关部门进一步研究

4. `Pilot Candidate`
   - 已经足够强，值得进入小范围试点建议

### Step 3: Translation

如果进入 `Research` 或 `Pilot Candidate`，必须先被翻译成公司语言：

- 它试图改进什么
- 适用于哪个部门
- 可能带来什么收益
- 可能带来什么风险
- 需要改变哪些 SOP / thesis / workflow

### Step 4: Cross-Department Review

至少需要：

- `Strategy Research Department` 评估有效性
- `Risk Office` 评估副作用
- `Knowledge & Memory Lead` 评估是否能被制度化

### Step 5: Decision

由 `Chief of Staff` 汇总成决策包。

若只是局部流程优化，可在治理层批准后执行。
若是策略或方向性变化，则升级给 Founder。

### Step 6: Rollout and Writeback

通过后必须更新：

- playbook
- 相关部门 charter 或 SOP
- `.harness/workspace/decisions/log/`
- `.harness/workspace/status/snapshots/`

## 关键规则

1. Founder 输入不是命令本身，而是候选思想。
2. 任何思想要进入公司制度，必须经过 triage、review 和 writeback。
3. 采纳的是“被验证后的制度化表达”，不是原始素材本身。
