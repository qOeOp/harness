# Founder Governance Meeting Loop

更新日期：`2026-03-24`

## 目的

定义 `Governance Meeting` 这一类 Founder 会议的输入打包、主持流程、会后执行链和 writeback 要求。

## 适用边界

本文件只处理：

1. 公司运行状态
2. 流程摩擦
3. 跨部门协作问题
4. 治理表面变化
5. 值得进入试点的治理改进

本文件不负责：

1. 会议类型路由
2. vision / acceptance / requirements / brainstorming 的边界说明
3. 日报或 audit cadence 本身

会议类型路由见：

- [docs/workflows/founder-meeting-taxonomy.md](./founder-meeting-taxonomy.md)

节奏来源见：

- [docs/workflows/process-compounding-cadence.md](./process-compounding-cadence.md)

## 角色分工

1. `Compounding Engineering Lead`
   - 主持治理会议
   - 审阅日报、retro、process audit、governance surface audit
   - 向 Founder 提出流程优化建议和组织风险
2. `Chief of Staff`
   - 汇总 company daily digest
   - 维护跨部门承诺
   - 会后负责落地与跟踪
3. Founder
   - 只拍板需要创始人决定的治理问题
   - 不接管日常执行

### Step 1: Department Daily Reports

每个活跃部门按 cadence 提交日报。

### Step 2: Company Daily Digest

`Chief of Staff` 汇总部门日报，形成公司级运营摘要。

### Step 3: Governance Meeting Brief

`Compounding Engineering Lead` 在 digest 基础上，叠加：

- 过程摩擦
- handoff 失败
- ritual 问题
- governance surface audit 发现
- 值得吸收的前沿治理实践
- 建议 Founder 拍板的治理问题

### Step 4: Founder Meeting

Founder 通过 canonical `meeting-router` skill 进入治理会议。

向 Founder 呈现的不是原始日报，而是高密度治理会议包：

1. 公司现在运行得怎样
2. 哪些部门在卡住彼此
3. 哪些流程该优化
4. 哪些建议值得进入试点
5. 哪些问题需要 Founder 拍板

### Step 5: Meeting Minutes

会议结束后，`Compounding Engineering Lead` 产出：

- meeting minutes
- approved improvement directions
- departments impacted
- required improvement plans

### Step 6: Department Improvement Plans

相关部门 leader 提交本部门改进计划。

模板：

- [docs/templates/improvement-plan.md](../templates/improvement-plan.md)

### Step 7: Review and Rollout

`Compounding Engineering Lead` review 改进计划。

如果只是本部门局部优化，可以直接进入执行。
如果涉及：

- 跨部门协作协议
- 公司 ritual
- 高权限自动化
- Founder-facing demo gate

则必须交给 `Chief of Staff` 和必要时 `Founder` 复核。

### Step 8: Execution and Follow-up

`Chief of Staff` 负责执行、追踪和检查是否真正落地。

### Step 9: Writeback

最终写入：

- process audit
- decision log entry
- status snapshot
- playbook / SOP updates

## `meeting-router` 应该输出什么

一个合格的 Founder governance meeting 输出至少包含：

1. Company Health
2. Department Highlights
3. Key Blockers
4. Process Frictions
5. Improvement Proposals
6. Decisions Needed From Founder
7. Next 7 Days

模板：

- [docs/templates/governance-meeting-brief.md](../templates/governance-meeting-brief.md)

## 升级条件

以下问题必须进入 Founder governance meeting 或会后补充升级：

1. 需要改变跨部门协作协议
2. 需要修改 Founder-facing demo gate
3. 需要引入高权限自动化、hooks、rules 或危险工具权限
4. 审计脚本或治理规则已经明显失真
5. 公司流程开始和已锁定 vision 冲突

## 相关文档

- [docs/workflows/founder-meeting-taxonomy.md](./founder-meeting-taxonomy.md)
- [docs/workflows/process-compounding-cadence.md](./process-compounding-cadence.md)
- [docs/workflows/governance-surface-audit.md](./governance-surface-audit.md)
