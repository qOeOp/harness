# Department Map

更新日期：`2026-03-22`

## 目的

定义每个部门的长期使命、核心输入、核心输出和主要服务对象。

## 部门生命周期

1. `部门` 不等于立刻要创建一个常驻 agent。
2. 初期每个部门先有 `Department Charter + Lead + Skills + Templates`。
3. 只有当某部门的输入输出稳定后，才值得把它扩成独立多 agent 工作组。

## 部门总览

| Department | Mission | Key Inputs | Key Outputs | Serves |
| --- | --- | --- | --- | --- |
| `Market Intelligence` | 获取、校验、清洗外部市场与资讯信号 | 外部新闻、社媒、宏观信息、链上信息、Founder 物料 | source registry 更新、event timeline memo、信号质量评估 | Strategy Research, Position Operations, Risk Office |
| `Strategy Research` | 把清洗信号转成 thesis、策略假设与研究提案 | Market Intelligence 信号、Founder 候选思想 | strategy memo、trade thesis draft、strategy change proposal | Position Operations, Risk Office, Learning & Evolution |
| `Position Operations` | 管理持仓、监控状态、触发更新建议 | 已批准的策略与 thesis、风险约束 | position book、monitor alerts、decision update memo | Founder, Learning & Evolution |
| `Risk Office` | 做建仓前风险审查与持仓期风控约束 | Strategy Research 提案、Position Operations 状态、市场异常事件 | risk review、exposure policy、escalation note | Founder, Chief of Staff, Position Operations |
| `Learning & Evolution` | 吸收 Founder 输入、复盘交易和流程、推动制度化改进 | Founder 物料、各部门 postmortem | material intake memo、postmortem、playbook update proposal | All departments, Chief of Staff, Knowledge & Memory Lead |

## Founder 输入入口

Founder 输入先进入：

`Learning & Evolution Department -> triage -> relevant departments -> Chief of Staff synthesis`

详细流程见：

- [docs/workflows/founder-intake-evolution-loop.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/founder-intake-evolution-loop.md)

## 与产品 runtime 的边界

部门层不等于产品 runtime 角色。

详细映射见：

- [docs/organization/company-os-runtime-data-map.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/organization/company-os-runtime-data-map.md)
