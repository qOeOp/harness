# Requirements Meeting Brief

- Linked work items: WI-0001,WI-0002




- Date: 2026-03-23
- Host: Chief of Staff
- Vision reference:
  1. .harness/workspace/current/product-vision.md
  2. .harness/workspace/decisions/log/2026-03-23-agent-harness-and-local-repo-strategy.md
  3. .agents/skills/harness/references/archive/harness/operating-state-system-brief.md
- Scope for this iteration:
  1. 封板 `Operating State System v1` 的最小对象模型。
  2. 封板本地存储形态：`work-item file as source of truth, board as derived view`。
  3. 封板 `company board / founder board / department board` 三类视图的最小列集。
  4. 封板 `work item / artifact / founder escalation / department participation` 四类状态对象与状态迁移。
  5. 封板 v1 迁移范围：只接入新的 governance / company-init / operating-system 事项，不 retroactively 全量迁旧资产。
- Acceptance criteria:
  1. 存在单一 `Work Item` 最小 schema，字段命名和语义稳定，能够覆盖 owner、sponsor、status、dependencies、department participation、linked artifacts。
  2. 存在单一 `Artifact Link` 规则，使 research memo、decision pack、snapshot、audit 可以绑定到 work item，而不引入第二套 source of truth。
  3. 存在清晰 `Work Item State Machine`，至少覆盖 `backlog -> framing -> planning -> ready -> in-progress -> review -> done`，并允许 `paused / killed` 作为终止或挂起分支。
  4. 存在清晰 `Artifact State Machine`，至少覆盖 `draft -> under-review -> approved -> active -> superseded -> archived`，并与 `.harness/workspace/current` / `.harness/workspace/archive` 路由相容。
  5. 存在 `Founder Escalation State`，至少能区分 `not-needed / pending-founder / approved / rejected / superseded`。
  6. 存在 `Department Participation Record`，至少能区分 `required / optional / blocked / done / not-involved`。
  7. `Company Board` 能回答：当前最重要事项、当前阶段、谁负责、卡在哪、哪些部门必须参与。
  8. `Founder Board` 只暴露需要 Founder 决策或验收的事项，不把全量运营细节直接推给 Founder。
  9. `Department Board` 能表达某部门对上游输入、当前参与状态和下一次 handoff 的局部视图。
  10. v1 设计必须保持 `tool-neutral, local-first`，不能把 GitHub Projects 当成唯一底座；若未来接 GitHub Projects，也只能作为同步视图或外部控制面。
  11. v1 设计必须能支持后续脚手架最小集合：`new_work_item`、`transition_work_item`、`refresh_boards`、`audit_state_system`。
  12. v1 设计必须显式定义 stop rule：若 1 个最小 internal task loop 仍无法在该状态系统下完整进入、推进、review、关闭，则本轮设计不通过。
- Non-goals:
  1. 不设计产品 runtime 数据模型。
  2. 不设计 GitHub Projects 的最终接入方案。
  3. 不 retroactively 改写全部历史 artifact。
  4. 不进入多 agent orchestration 或 runtime harness 自研。
  5. 不在本轮定义所有部门的二级局部状态机。
- Dependencies:
  1. docs/workflows/decision-workflow.md
  2. docs/memory/memory-architecture.md
  3. docs/organization/company-os-runtime-data-map.md
  4. .agents/skills/harness/references/archive/harness/company-harness-map.md
  5. .agents/skills/harness/references/archive/harness/agent-harness-and-local-repo-investment-research-memo.md
- Demo boundary:
  1. 用一个最小治理事项演示完整链路：
     `new work item -> link research memo -> move to planning -> mark ready -> enter review -> close as done`
  2. 同时展示三张只读视图：
     `company board`
     `founder board`
     `one department board`
  3. 不要求真正接 GitHub，不要求复杂 UI，只要求本地文件和脚手架能表达并刷新该链路。
- Risks:
  1. 若 schema 设计过重，会把 v1 变成另一套项目管理软件。
  2. 若 board 字段设计过轻，Founder 视图和部门视图会再次退回口头解释。
  3. 若 artifact link 规则不严格，会再次出现文档分散、无法追溯。
  4. 若默认要求全量迁移历史记录，成本会过高，导致 v1 无法落地。
- Verification date: 2026-03-23
- Verification mode: mixed
- Sources reviewed:
  1. .agents/skills/harness/references/archive/harness/operating-state-system-brief.md
  2. .agents/skills/harness/references/archive/harness/company-harness-map.md
  3. .agents/skills/harness/references/archive/harness/agent-harness-and-local-repo-investment-research-memo.md
  4. .harness/workspace/research/sources/2026-03-23-agent-harness-source-bundle.md
  5. docs/workflows/decision-workflow.md
  6. docs/memory/memory-architecture.md
  7. docs/organization/company-os-runtime-data-map.md
- What remains unverified:
  1. pure local-first board 与 future GitHub Projects sync 的最优映射还未验证。
  2. `department board` 是否应单独存于部门子树，还是由公司级 state 派生输出，仍未最终锁定。
  3. v1 的字段集是否已经足够支撑后续 requirements / demo / implementation work items，还有待第一轮实跑验证。
- Decisions needed from Founder:
  1. 是否批准 `Operating State System v1` 作为当前唯一允许推进的 pre-code 事项。
  2. 是否接受 `local-first state, optional future sync` 的路线，而不是立即把 GitHub Projects 设为主本体。
  3. 是否接受强 stop rule：在 v1 验收前，不再扩写角色/部门/会议治理表层。

## Divergent Hypotheses

1. `Document-first`
   - 继续依赖 briefs / memos / decisions / snapshots 的目录体系，只补交叉引用，不引入 work item 本体。
2. `Board-first externalized`
   - 直接把 GitHub Projects 设为主本体，repo 只保留摘要和回写。
3. `Local-first state-first`
   - 以本地 `work item file` 为 source of truth，repo 中派生 board 视图，未来可选择性同步到 GitHub Projects。

## First Principles Deconstruction

1. 目录不能稳定表达状态迁移，字段对象才能。
2. Founder 需要的是决策面，不是运营全量视图。
3. append-only memory 适合沉淀证据和决策，不适合承担可变状态主表。
4. 工作项是主对象，artifact 只是证据与输出。
5. v1 若不能本地独立跑通，就没有资格外接更复杂的 board / automation。

## Convergence To Excellence

采纳第 3 条路线：

1. `Local-first`
   - work item 文件是本体。
2. `State-first`
   - 所有正式 artifact 反向挂接到 work item。
3. `Board-derived`
   - board 是视图，不是存储本体。
4. `Founder-thin`
   - Founder 只看 escalation / acceptance。
5. `Migration-light`
   - 只接新事项，不强制回填全部历史。

## Proposed V1 Object Model

### Work Item

必填字段建议：

1. `id`
2. `title`
3. `type`
4. `status`
5. `owner`
6. `sponsor`
7. `priority`
8. `created_at`
9. `updated_at`
10. `founder_escalation`
11. `required_departments`
12. `participation_records`
13. `linked_artifacts`
14. `blocked_by`
15. `blocks`
16. `current_blocker`
17. `next_handoff`

### Artifact Link

必填字段建议：

1. `artifact_path`
2. `artifact_type`
3. `artifact_status`
4. `linked_work_item`
5. `owner`
6. `supersedes`

### State Enums

1. `work_item.status`
   - `backlog`
   - `framing`
   - `planning`
   - `ready`
   - `in-progress`
   - `review`
   - `done`
   - `paused`
   - `killed`
2. `artifact_status`
   - `draft`
   - `under-review`
   - `approved`
   - `active`
   - `superseded`
   - `archived`
3. `founder_escalation`
   - `not-needed`
   - `pending-founder`
   - `approved`
   - `rejected`
   - `superseded`
4. `department participation`
   - `required`
   - `optional`
   - `blocked`
   - `done`
   - `not-involved`

## Proposed Local Shape

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

规则：

1. `items/` 是 source of truth。
2. `boards/` 全部由脚手架刷新，不手工维护。
3. `.harness/workspace/decisions/log`、`.harness/workspace/research/sources`、`.harness/workspace/status/snapshots` 继续 append-only，不被替代。
4. 每个正式 artifact 必须写 `linked_work_item`。

## Default Board Columns

### Company Board

1. `Work Item`
2. `Type`
3. `Status`
4. `Priority`
5. `Owner`
6. `Required Departments`
7. `Current Blocker`
8. `Founder Escalation`
9. `Last Updated`

### Founder Board

1. `Work Item`
2. `Why It Matters`
3. `Decision Needed`
4. `Deadline`
5. `Supporting Pack`

### Department Board

1. `Work Item`
2. `Participation`
3. `Local Status`
4. `Upstream Dependency`
5. `Next Handoff`
6. `Artifact Due`
