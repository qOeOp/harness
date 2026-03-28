# Process Compounding Cadence

更新日期：`2026-03-28`

## 目的

把流程改进、表面审计、审计脚本维护和前沿扫描放进固定节奏。

本节奏服务的是 control surfaces 与 process quality，不定义 company / workstream 组织投影。

## 节奏总览

| 节奏 | Owner | 核心输入 | 核心输出 |
| --- | --- | --- | --- |
| 每任务 closeout review | 任务 owner | closure artifacts、acceptance 结果、postmortem | closeout note、follow-up actions |
| 每周 process audit | `Compounding Engineering Lead` | checkpoints、postmortems、freshness failures、handoff 问题 | process audit、实验提案、流程修订建议 |
| 每周 surface audit | `Workflow & Automation Lead` 或 `Compounding Engineering Lead` | docs / scripts / skills / hooks / rules 当前状态 | keep / compress / archive / promote 清单 |
| 每月 audit-the-auditors | `Compounding Engineering Lead` | 各类审计脚本、最近 audit 结果、新结构变更 | 审计覆盖缺口、脚本更新计划 |
| 周期性 frontier scan | `Compounding Engineering Lead` | 官方文档、社区实践、研究材料 | 候选试点与 adopt / reject 建议 |

## Weekly Rituals

### Process Audit

至少每周一次。

输入：

- postmortem
- acceptance ledger
- acceptance / closeout 记录
- checkpoint
- freshness failures
- repeated handoff problems

输出：

- process audit
- experiment proposal
- workflow or playbook update proposal

模板：

- [skills/process-audit/templates/process-audit.md](../../skills/process-audit/templates/process-audit.md)

建议默认先写 task-local artifact。
只有确实需要共享留痕时，才显式 promote 到共享记录面。

### Surface Audit

至少每周一次轻量审计、每月一次深度审计。

默认先运行：

- source repo:
  - `./scripts/run_governance_surface_diagnostic.sh --mode source`
- consumer / dogfood repo:
  - `./scripts/run_governance_surface_diagnostic.sh --mode consumer`

详细规则见：

- [docs/workflows/governance-surface-audit.md](./governance-surface-audit.md)
- [skills/os-audit/templates/governance-surface-audit.md](../../skills/os-audit/templates/governance-surface-audit.md)

### Escalation Rule

以下问题不进入独立“治理会议”分类，而是按主题升级回已有主流程：

1. 改产品边界
   - 升级到 `vision`
2. 改当前交付是否过 gate
   - 升级到 `acceptance`
3. 改阶段需求或验收标准
   - 升级到 `requirements`
4. 纯流程或控制面修订
   - 留在 process audit / surface audit / decision pack

## Monthly and Periodic Rituals

### Frontier Scan

固定频率建议：

- 每周轻量扫描一次
- 每月深度研究一次

研究范围：

1. 主流 coding-agent 实践
2. Codex / Claude Code / MCP / hooks / skills / rules 的新能力
3. 大型项目里的 context engineering、review、eval、trace 实践
4. 值得试点的新 repo 结构、workflow、review 机制

模板：

- [docs/templates/frontier-scan.md](../templates/frontier-scan.md)

### Audit-the-Auditors

至少每月一次。

目标：

1. 检查审计脚本是否仍覆盖当前仓库结构
2. 检查新增目录、文档类型、工具适配层是否已进入审计范围
3. 检查脚本是否只在做“存在性检查”，却遗漏语义漂移
4. 检查哪些规则应从脚本升级为更硬的控制面，或从脚本降级回人工判断

最少检查对象：

1. source repo：
   - `./scripts/validate_source_repo.sh`
   - `./scripts/audit_role_schema.sh`
   - `./scripts/run_governance_surface_diagnostic.sh --mode source`
2. consumer / dogfood repo：
   - `./scripts/audit_document_system.sh`
   - `./scripts/audit_doc_style.sh`
   - `./scripts/validate_workspace.sh`
   - `./scripts/run_governance_surface_diagnostic.sh --mode consumer`

输出：

1. coverage gaps
2. stale checks
3. newly required checks
4. approved script updates
5. 哪些 prompt / policy / skill / handoff / model snapshot 变更
   还没有绑定 replay fixture、eval slice
   或 regression sample

## Adoption Gate

外部新思想不能直接写进 canonical rules。

必须经过：

1. Observe
2. Research
3. Pilot
4. Review
5. Writeback
