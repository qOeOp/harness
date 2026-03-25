# Operating State System Brief

- Date: 2026-03-23
- Status: draft
- Owner: Chief of Staff
- Verification date: 2026-03-23
- Verification mode: mixed
- Sources reviewed:
  1. .agents/skills/harness/references/archive/harness/company-harness-map.md
  2. .agents/skills/harness/references/archive/harness/2026-03-23-coding-agent-operating-skeleton-research-memo.md
  3. .harness/workspace/research/sources/2026-03-23-coding-agent-operating-skeleton-patterns.md
- Scope:
  1. 只设计 company OS 的运行状态主骨架
  2. 不进入产品 runtime 细节
  3. 不进入 requirements 或实现

## Decision

公司下一层主骨架应定义为 `Operating State System`，而不是继续堆文档或提前初始化更多部门/员工。

这套系统应采用：

1. `work-item-first`
2. `artifact-linked`
3. `board-driven`
4. `tool-neutral, local-first`

## Why now

当前 company OS 的 `Entry / Policy / Tools / Feedback` 已经有初步骨架，但 `State` 层明显不足。

如果现在继续往下游推进：

1. 文件会继续散落
2. 部门参与会继续失真
3. audit / retro / review 仍然挂不到统一状态对象上
4. 后续公司初始化和员工职责手册会建立在一个没有状态主骨架的系统上

## First Principles

1. 目录不是状态机，工作项才是状态机。
2. 文档是资产，不是主对象。
3. board 是视图，不是存储本体。
4. 状态系统必须先本地可运行，再考虑是否接 GitHub Projects 等外部系统。
5. 任何状态变化都必须可追溯、可审计、可压缩。

## Core Objects

### 1. Work Item

公司真正推进的最小单位。

最小字段建议：

1. `id`
2. `title`
3. `type`
   - `vision`
   - `governance`
   - `company-init`
   - `research`
   - `department-task`
   - `demo`
3. `status`
4. `priority`
5. `owner`
6. `sponsor`
   - `founder`
   - `chief-of-staff`
   - `department-lead`
7. `objective`
8. `ready_criteria`
9. `done_criteria`
10. `required_artifacts`
11. `created_at`
12. `updated_at`
13. `due_review_at`
14. `founder_escalation`
15. `required_departments`
16. `linked_artifacts`
17. `last_transition_event`
18. `blocked_by`
19. `blocks`

### 2. Artifact

附属于 work item 的证据、计划、审计、纪要、快照。

最小字段建议：

1. `artifact_type`
   - `brief`
   - `research-memo`
   - `decision-pack`
   - `audit`
   - `snapshot`
   - `report`
2. `artifact_status`
3. `owner`
4. `linked_work_item`
5. `supersedes`
6. `archived_at`

### 3. Board View

不是 source of truth，而是对 work items 的筛选视图。

当前至少需要三类：

1. `company board`
2. `department board`
3. `founder board`
4. `generated-only`

### 4. Department Participation Record

不是所有 work item 都由所有部门参与。

每个部门对某 work item 的参与状态建议统一为：

1. `required`
2. `optional`
3. `blocked`
4. `not-involved`
5. `done`

## State Machines

### Work Item State

```text
backlog
  -> framing
  -> planning
  -> ready
  -> in-progress
  -> review
  -> done

backlog / framing / planning / ready / in-progress / review
  -> paused
  -> killed
```

规则：

1. `framing` 前不得派发执行
2. `planning` 未封板不得进入 `ready`
3. `planning -> ready` 必须满足 `objective + ready_criteria + required department assignment`
4. `review -> done` 必须满足 `done_criteria + required artifact satisfaction + required department completion`
5. `review` 未通过不得进入 `done`
6. 状态迁移必须留下 append-only transition event
7. transition event 需要带 `Prev event / Prev event hash / Event hash`
8. 任意状态发现上游基础不稳，可回退到 `framing` 或 `planning`

### Artifact State

```text
draft
  -> under-review
  -> approved
  -> active
  -> superseded
  -> archived
```

规则：

1. `active` 只能极少数 artifact 拥有
2. `superseded` 不等于删除，必须可回溯
3. `.harness/workspace/current/` 只保留 `active truth` 的稳定入口，不直接承载所有 approved artifacts

### Founder Escalation State

```text
not-needed
  -> pending-founder
  -> approved
  -> rejected
  -> superseded
```

### Department Participation State

```text
not-involved
required -> done
optional -> done
required -> blocked
optional -> blocked
```

## Boards

### 1. Company Board

用来回答：

1. 公司当前最重要的 work items 是什么
2. 它们处于哪个阶段
3. 卡在哪里
4. 哪些部门必须参加

建议列：

1. `Work Item`
2. `Type`
3. `Status`
4. `Owner`
5. `Required Departments`
6. `Current Blocker`
7. `Founder Escalation`
8. `Last Updated`

### 2. Department Board

用来回答：

1. 本部门当前接了哪些 work items
2. 哪些是 required，哪些只是 optional
3. 当前卡在 input 还是 review

建议列：

1. `Work Item`
2. `Participation`
3. `Local Status`
4. `Upstream Dependency`
5. `Next Handoff`
6. `Artifact Due`

### 3. Founder Board

Founder 不该看 company board 全量细节。

Founder board 只显示：

1. `pending-founder`
2. `ready for acceptance`
3. `high-risk blocked`
4. `vision-sensitive changes`

建议列：

1. `Item`
2. `Why it matters`
3. `Decision needed`
4. `Deadline`
5. `Supporting pack`

## Asset Binding

当前仓库已经有：

1. `.harness/workspace/briefs/`
2. `.harness/workspace/decisions/log/`
3. `.harness/workspace/status/snapshots/`
4. `.harness/workspace/status/process-audits/`
5. `.harness/workspace/research/dispatches/`
6. `.harness/workspace/research/sources/`

下一层不应该推翻这些目录，而应该给它们补一条绑定规则：

**每个正式 artifact 都必须绑定到一个 work item。**

最小要求：

1. 在 artifact 中写 `linked_work_item`
2. 在 work item 中回指 `linked_artifacts`

## Department Participation Matrix

当前最需要的不是“再加部门”，而是明确什么类型的事项默认拉哪些部门：

| Work Item Type | Default Required Departments | Default Optional Departments |
| --- | --- | --- |
| `vision` | `Strategy Research`, `Risk Office`, `Learning & Evolution` | `Market Intelligence` |
| `governance` | `Chief of Staff`, `Compounding Engineering Lead` | `Learning & Evolution` |
| `company-init` | `Chief of Staff`, `Compounding Engineering Lead`, `Knowledge & Memory` | 相关部门 |
| `research` | `Market Intelligence`, `Strategy Research` | `Risk Office` |
| `department-task` | 发起部门 | 相邻 handoff 部门 |
| `demo` | `Chief of Staff`, `Risk Office` | 对应交付部门 |

这只是 `v1` 默认矩阵，后面可以调。

## Storage Shape

最优不是把工作项按状态分目录堆叠，而是：

1. 一条 work item 一个文件
2. board 是汇总视图
3. 状态写在 work item 字段里，而不是靠文件移动表达

建议的本地形态：

```text
.harness/workspace/state/
  items/
    WI-0001.md
    WI-0002.md
  boards/
    company.md
    founder.md
.harness/workspace/departments/<department>/workspace/
  board.md
```

## Control Surface Hooks

这层不应只靠手工维护。

后续最值得补的不是新文档，而是这些脚手架：

1. `new_work_item.sh`
2. `transition_work_item.sh`
3. `refresh_boards.sh`
4. `audit_state_system.sh`
5. per-work-item `hash chain`

## Adoption Path

不要一次性把所有现有 artifact 全迁过去。

正确迁移顺序：

1. 先定义 work item schema
2. 先建 company board / founder board 两个视图
3. 先把新的治理事项和 initialization 事项接入
4. 再逐步把已有 briefs / audits / decisions 绑定到 work items

## Risks

1. 如果把 board 设计得太像项目管理软件，会过重
2. 如果只做文档，不做脚手架，又会退回“纸面状态系统”
3. 如果把所有资产都要求完整绑定，初期迁移成本会太高

## Recommendation

下一步不进入公司初始化，不进入员工职责手册，不进入 requirements。

下一步只做：

1. `Operating State System` 的对象模型封板
2. 本地文件形态封板
3. board 视图封板
4. v1 迁移范围封板
