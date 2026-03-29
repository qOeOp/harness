# Founder Intake Evolution Loop

更新日期：`2026-03-28`

## 问题背景

Founder 会持续提供：

- 文章
- 视频
- 链接
- 外部案例
- 对产品、流程或工具链的主观质疑

这些输入如果直接打到执行面，会造成：

1. baseline 团队被频繁打断。
2. 同一个材料被重复研究。
3. 没有人对“是否采纳”负责。
4. 好想法无法制度化沉淀。

## 收敛结论

Founder 输入必须有统一入口。

默认入口是：

`general-manager`

而不是预设某个行业部门。

## Loop

### Step 1: Intake

Founder 输入进入：

- `.harness/workspace/intake/inbox/`

模板：

- [docs/templates/material-intake.md](../templates/material-intake.md)
补充边界：intake 记录的是候选输入，不等于已批准任务或可直接执行的命令；模板里的 `Why this input matters right now` 应说明它和当前 substrate / task surface 的关系，不把“Founder 提了这个想法”当成充分理由。

### Step 2: Triage

Owner: `general-manager`

分成 4 类：

1. `Discard`
   - 噪音高
   - 不适配当前阶段
   - 没有可执行价值
2. `Observe`
   - 值得记录
   - 暂不值得投入研究
3. `Research`
   - 指派 baseline 团队或已有 runtime role 进一步研究
4. `Pilot Candidate`
   - 已经足够强，值得进入小范围试点建议

### Step 3: Translation

如果进入 `Research` 或 `Pilot Candidate`，必须先被翻译成当前 task/workflow 语言：

- 它试图改进什么
- 影响哪个任务或 workflow
- 可能带来什么收益
- 可能带来什么风险
- 需要改变哪些 SOP / workflow / contract

### Step 4: Cross Review

至少需要：

- `Product Thesis Lead` 评估问题定义与边界
- `Risk & Quality Lead` 评估副作用与误用风险
- `Knowledge & Memory Lead` 评估是否能被制度化

### Step 5: Decision

由 `general-manager` 汇总成决策包。

若只是局部流程优化，可在默认 approval boundary 内批准后执行。
若需要跨越已批准产品边界，则升级给 Founder。

### Step 6: Rollout and Writeback

通过后必须更新：

- playbook / workflow
- 相关 task-local artifacts
- 必要时 promote 到 `.harness/workspace/decisions/log/`
- 必要时生成 process audit 或 improvement proposal

### Step 7: Promotion Check

如果相同类型输入反复出现，并持续需要专门 owner：

1. 先在 compounding review 里论证
2. 再决定是否在 `.harness/workspace/roles/` 创建 runtime-local role
3. 不允许直接把这类角色写进 source repo `roles/`

## 关键规则

1. Founder 输入不是命令本身，而是候选思想。
2. 任何思想要进入当前 substrate contract，必须经过 triage、review 和 writeback。
3. 默认优先复用 baseline 团队，不预置行业部门。
4. 采纳的是“被验证后的制度化表达”，不是原始素材本身。
