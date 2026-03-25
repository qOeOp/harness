# Process Compounding Cadence

更新日期：`2026-03-24`

## 目的

把流程治理、文档治理、审计脚本维护和前沿扫描放进固定节奏。

## 节奏总览

| 节奏 | Owner | 核心输入 | 核心输出 |
| --- | --- | --- | --- |
| 每日部门日报 | 各活跃部门 leader | 当日输入、输出、阻塞、handoff 摩擦 | 部门日报 |
| 每日 company digest | `Chief of Staff` | 各部门日报 | 公司级运营摘要 |
| 每周 operating checkpoint | `Chief of Staff` | digest、open blockers、跨部门承诺 | 本周运行状态与升级事项 |
| 每周 process audit | `Compounding Engineering Lead` | 部门 retro、checkpoint、Founder feedback | process audit、实验提案、治理会议输入 |
| 每周 governance surface audit | `Compounding Engineering Lead` | 文档/脚本/skills/hooks/rules 当前状态 | keep/compress/archive/promote 清单 |
| 每月 audit-the-auditors | `Compounding Engineering Lead` | 各类审计脚本、最近 audit 结果、新结构变更 | 审计覆盖缺口、脚本更新计划 |
| 周期性 frontier scan | `Compounding Engineering Lead` | 官方文档、社区实践、研究材料 | 候选试点与 adopt/reject 建议 |

## Daily Rituals

每个部门每天至少沉淀一条日报。

最小字段：

1. 今天输入了什么
2. 今天输出了什么
3. 被谁阻塞
4. 哪个 handoff 有摩擦
5. 哪个流程最浪费时间

模板：

- [docs/templates/daily-department-report.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/daily-department-report.md)

标准落盘位置：

- `.harness/workspace/departments/<department>/workspace/reports/daily/`

由 `Chief of Staff` 汇总各部门日报，形成公司级运营摘要。

company digest 至少覆盖：

1. 今天公司整体输入了什么
2. 今天公司整体产出了什么
3. 哪些 blocker 正在阻塞多个部门
4. 哪些 cross-department commitments 有风险
5. 哪些事项可能需要升级给 Founder

模板：

- [docs/templates/company-daily-digest.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/company-daily-digest.md)

标准落盘位置：

- `.harness/workspace/status/digests/`

## Weekly Rituals

### Operating Checkpoint

治理层每周至少审阅一次：

1. 哪些部门在重复做相同工作
2. 哪些流程有热点冲突
3. 哪些 handoff 经常失败
4. 哪些 ritual 应该删掉或加强

### Process Audit

至少每周一次，由 `Compounding Engineering Lead` 主导。

输入：

- 各部门日报
- checkpoint
- postmortem
- Founder feedback

输出：

- process audit memo
- experiment proposal
- playbook update proposal
- governance meeting brief

模板：

- [docs/templates/process-audit.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/process-audit.md)

标准落盘位置：

- 部门 retro: `.harness/workspace/departments/<department>/workspace/reports/retros/`
- 公司级 process audit: `.harness/workspace/status/process-audits/`

对交易决策相关的复盘，还应额外遵守：

1. raw retros append-only 保留
2. 周期性提炼 repeated mistake patterns
3. 维护一个当前有效的 `active trap library`
4. 新交易计划进入正式输出前，应先做一轮 `trap check`

详细见：

- [docs/workflows/retrospective-compaction-and-trap-check.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/retrospective-compaction-and-trap-check.md)
- [docs/templates/trap-card.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/trap-card.md)

### Governance Surface Audit

至少每周一次轻量审计、每月一次深度审计。

默认先运行：

- `./.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh`

详细规则见：

- [docs/workflows/governance-surface-audit.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/governance-surface-audit.md)
- [docs/templates/governance-surface-audit.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/governance-surface-audit.md)

### Founder Governance Meeting

Founder 治理会议由以下节奏产物触发，而不是单独维护一套平行 cadence：

1. company daily digest
2. process audit
3. governance surface audit
4. frontier scan
5. 需要升级的跨部门问题

本文件只定义它的触发来源，不展开会议内部流程。

详细流程与会议路由见：

- [docs/workflows/founder-governance-meeting-loop.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/founder-governance-meeting-loop.md)
- [docs/workflows/founder-meeting-taxonomy.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/founder-meeting-taxonomy.md)

## Monthly and Periodic Rituals

### Frontier Scan

固定频率建议：

- 每周轻量扫描一次
- 每月深度研究一次

研究范围：

1. 主流多 agent coding 实践
2. Codex / Claude Code / MCP / hooks / skills / rules 的新能力
3. 大型项目治理、context engineering、compound engineering 的最新实践
4. 值得试点的新 repo 结构、workflow、review 机制

模板：

- [docs/templates/frontier-scan.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/templates/frontier-scan.md)

### Audit-the-Auditors

至少每月一次，由 `Compounding Engineering Lead` 主导。

目标：

1. 检查审计脚本是否仍覆盖当前仓库结构
2. 检查新增目录、文档类型、工具适配层是否已进入审计范围
3. 检查脚本是否只在做“存在性检查”，却遗漏语义漂移
4. 检查哪些规则应从脚本升级为更硬的控制面，或从脚本降级回人工判断

最少检查对象：

1. `.agents/skills/harness/scripts/audit_document_system.sh`
2. `.agents/skills/harness/scripts/audit_tool_parity.sh`
3. `.agents/skills/harness/scripts/audit_doc_style.sh`
4. `.agents/skills/harness/scripts/validate_workspace.sh`
5. `.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh`

输出：

1. coverage gaps
2. stale checks
3. newly required checks
4. approved script updates

## Adoption Gate

外部新思想不能直接写进公司制度。

必须经过：

1. Observe
2. Research
3. Pilot
4. Review
5. Writeback
