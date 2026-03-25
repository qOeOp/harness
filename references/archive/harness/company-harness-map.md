# Company Harness Map

- Date: 2026-03-23
- Status: draft
- Scope:
  1. 只审当前 company OS
  2. 不进入产品 runtime 细节
  3. 不进入 requirements 或实现

## 目的

把当前公司 OS 按 `Entry / Policy / Tools / State / Feedback` 五层拆开，识别：

1. 哪些层已经有骨架
2. 哪些层还空着
3. 哪些层只是写成了文档，还没真正进入控制面

## 五层总览

| Layer | 作用 | 当前主要资产 | 当前判断 |
| --- | --- | --- | --- |
| `Entry` | 新员工从哪里进入系统 | `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`、部门镜像入口、routing 文档 | 基本稳 |
| `Policy` | 什么能做、什么不能做 | charter、decision rights、workflow、阶段门、文档风格规则 | 较稳 |
| `Tools` | 系统如何机械执行规则 | scripts、hooks、skills、subagents、tool adapters、git gates | 可用但不够系统化 |
| `State` | 公司和项目当前处于什么状态 | `current`、`briefs`、`archive`、digests、snapshots、dispatches | 明显不足 |
| `Feedback` | 如何发现错误并回流改进 | audits、retro、process audit、decision log、acceptance / governance meeting | 可用但还不够贴近 work items |

## Layer 1: Entry

### 当前已有

1. 根入口：
   - [AGENTS.md](/Users/vx/WebstormProjects/trading-agent/AGENTS.md)
   - [CLAUDE.md](/Users/vx/WebstormProjects/trading-agent/CLAUDE.md)
   - [GEMINI.md](/Users/vx/WebstormProjects/trading-agent/GEMINI.md)
2. 部门入口镜像：
   - `.harness/workspace/departments/*/AGENTS.md`
   - `.harness/workspace/departments/*/CLAUDE.md`
   - `.harness/workspace/departments/*/GEMINI.md`
3. 路由入口：
   - [document-routing-and-lifecycle.md](/Users/vx/WebstormProjects/trading-agent/docs/workflows/document-routing-and-lifecycle.md)
   - [product-vision.md](/Users/vx/WebstormProjects/trading-agent/.harness/workspace/current/product-vision.md)

### 当前判断

这一层已经基本够用。新开的 coding agent 至少知道：

1. 先读什么
2. 当前 truth 去哪里找
3. 历史快照去哪里找

### 主要缺口

1. 还没有“按任务类型自动路由到 board/work item”的入口
2. 入口目前仍然主要面向文档，不面向状态系统

## Layer 2: Policy

### 当前已有

1. 宪法：
   - [company-charter.md](/Users/vx/WebstormProjects/trading-agent/docs/charter/company-charter.md)
2. 组织与权限：
   - [org-chart.md](/Users/vx/WebstormProjects/trading-agent/docs/organization/org-chart.md)
   - [department-map.md](/Users/vx/WebstormProjects/trading-agent/docs/organization/department-map.md)
   - [decision-rights.md](/Users/vx/WebstormProjects/trading-agent/docs/organization/decision-rights.md)
3. 流程：
   - [decision-workflow.md](/Users/vx/WebstormProjects/trading-agent/docs/workflows/decision-workflow.md)
   - [process-compounding-cadence.md](/Users/vx/WebstormProjects/trading-agent/docs/workflows/process-compounding-cadence.md)
4. 风格与路由规则：
   - [document-types-and-writing-style.md](/Users/vx/WebstormProjects/trading-agent/docs/charter/document-types-and-writing-style.md)
   - [document-routing-and-lifecycle.md](/Users/vx/WebstormProjects/trading-agent/docs/workflows/document-routing-and-lifecycle.md)

### 当前判断

Policy 层已经能约束：

1. 角色边界
2. 阶段门
3. 文档生命周期
4. Founder operating model

### 主要缺口

1. 缺少“工作项状态机”制度
2. 缺少“部门参与矩阵”制度
3. 缺少“资产状态”制度

## Layer 3: Tools

### 当前已有

1. 审计脚本：
   - `audit_document_system.sh`
   - `audit_tool_parity.sh`
   - `audit_doc_style.sh`
   - `validate_workspace.sh`
2. 新建脚手架：
   - `new_research_dispatch.sh`
   - `new_source_note.sh`
   - `new_decision.sh`
   - `new_daily_report.sh`
   - `new_retro.sh`
   - `new_worktree.sh`
3. 工具适配层：
   - `.claude/`
   - `.codex/`
   - `.gemini/`
4. Claude hooks / agents / skills
5. Codex agents / skills / rules

### 当前判断

Tools 层已经不是纯文档系统了，已经具备真实控制面。

### 主要缺口

1. 还没有面向 `Operating State System` 的脚本或状态脚手架
2. 还没有“工作项创建 / 状态迁移 / board 汇总”的控制面
3. 现有脚手架更偏 artifact，而不是 work item

## Layer 4: State

### 当前已有

1. `.harness/workspace/current/`
2. `.harness/workspace/briefs/`
3. `.harness/workspace/archive/`
4. `.harness/workspace/intake/inbox` / `triage`
5. `.harness/workspace/research/dispatches` / `sources`
6. `.harness/workspace/decisions/log`
7. `.harness/workspace/status/digests`
8. `.harness/workspace/status/process-audits`
9. `.harness/workspace/status/snapshots`

### 当前判断

这一层是当前最薄弱的主骨架。

现在有的是：

1. 文档生命周期
2. 决策和状态快照
3. 研究派发与来源记录

现在缺的是：

1. `work item` 对象
2. company board
3. department board
4. founder board
5. 状态机：
   - backlog
   - framing
   - planning
   - ready
   - in-progress
   - review
   - done / paused / killed
6. 部门参与状态：
   - required
   - optional
   - blocked
   - not-involved
7. 资产状态：
   - draft
   - under-review
   - approved
   - active
   - superseded
   - archived

### 结论

当前 company OS 的最大空白不是规则，也不是脚本，而是 `Operating State System`。

## Layer 5: Feedback

### 当前已有

1. document audits
2. governance surface audit
3. company daily digest
4. process audit
5. status snapshots
6. decision log
7. Founder governance meeting
8. acceptance review

### 当前判断

Feedback 层已经能发现很多治理问题，但它主要还是围绕文档和流程。

### 主要缺口

1. 还不能围绕 work item 回流
2. 还不能直接看出：
   - 哪些事项卡住最久
   - 哪些部门在 backlog 积压
   - 哪些 review 阶段堵塞
3. retro / audit 还没挂到统一 board 上

## 当前成熟度判断

| Layer | 成熟度 |
| --- | --- |
| Entry | `good` |
| Policy | `good` |
| Tools | `medium` |
| State | `weak` |
| Feedback | `medium` |

## 总结

当前 company OS 不是“只有 md 文档”，但也还不是完整 OS。

更准确的判断是：

1. `Entry` 和 `Policy` 已经搭起来了
2. `Tools` 已经有初步控制面
3. `Feedback` 已经开始成形
4. `State` 仍然缺主骨架

## 推荐下一步

不要继续往部门初始化、员工手册、requirements 或实现推进。

下一步只做这一件事：

**设计 `Operating State System v1`**

它至少要回答：

1. work item 是什么
2. board 长什么样
3. 状态机是什么
4. 资产如何绑定到 work item
5. 部门参与如何表达
6. Founder 看什么 board
