# Task Artifact Routing

更新日期：`2026-03-27`

## 目的

把 `research dispatch / research brief / source note / research memo / decision pack / checkpoint / role change proposal` 这类正式 artifact 的默认落点收敛到一套单一规则，避免 task truth 和治理投影同时冒充默认真相。

## Divergent Hypotheses

1. 继续把 `.harness/workspace/*` 当默认正式 artifact 面。
2. 所有 artifact 永久只留 task 目录，完全禁止 promotion。
3. 默认 `task-local first`，只有显式 `--promote-governance` 时才升级到治理面。

## First Principles Deconstruction

1. agent 恢复当前工作时，第一问题是“哪个 task 在推进”，不是“公司级总目录在哪”。
2. 与某个 task 强绑定的证据和决策，默认应该贴着该 task 存放。
3. 跨任务沉淀是升级动作，应该由 operator 显式表达。
4. minimum-core runtime 必须在没有 governance tree 的情况下也能完整执行、暂停、恢复、校验。

## Convergence To Excellence

采纳第 3 条：

`task-local first, governance by explicit promotion`

## Canonical Rules

### 1. 默认绑定方式

在 minimum-core runtime 中，正式 artifact 必须优先绑定到某个 work item。

绑定顺序：

1. 显式 `--work-item <WI-xxxx>` 时，写 task-local artifact
2. 若没有 `--work-item`，直接拒绝
3. 只有显式 `--promote-governance` 时，才允许走治理升级分支
4. promotion 分支仍要求 runtime 已启用 `advanced governance mode`

### 2. Canonical Task-Local Paths

默认 task-local 路径：

1. `Research Dispatch`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md`
2. `Research Brief`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-brief.md`
3. `Source Note`
   - `.harness/tasks/<task-id>/attachments/sources/<date>-<slug>.md`
4. `Research Memo`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-research-memo.md`
5. Optional `Evidence Ledger`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-evidence-ledger.md`
6. `Decision Pack`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-decision-pack.md`
7. `Checkpoint`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-checkpoint.md`
8. `Role Change Proposal`
   - `.harness/tasks/<task-id>/closure/<date>-<slug>-role-change-proposal.md`

说明：

1. `Research Brief` 是 collection 复杂时的前置 artifact，不要求每次都写。
2. `Evidence Ledger` 是长流程、多来源、可中断研究时的可选台账，不应变成强制 paperwork。
3. `Source Note` 仍是默认正式证据 artifact。

### 3. Governance Promotion

只有在以下条件同时满足时，才允许写到 `.harness/workspace/*`：

1. runtime 已显式启用 `advanced governance mode`
2. artifact 的价值确实超出单个 task
3. operator 明确传入 `--promote-governance`

promotion 是显式升级动作，不再通过“缺少 task context 就退回 workspace”隐式触发。

### 4. Freshness Gate Coverage

任何 freshness / evidence 校验都必须理解：

1. task-local `dispatch / source / research / decision / checkpoint`
2. governance-promoted `dispatch / source / decision / briefs`

### 5. Pointer Neutrality

research / source / decision / checkpoint / dispatch 这类 artifact writeback 默认不应改变执行焦点。

在 v2 core 里，这条规则等价于：

1. 非执行写回只更新 task-local attachment 与 task header
2. selector 与 query 从 task record 派生视图，不声明全局焦点

## 禁止事项

1. 不要把 `.harness/workspace/*` 写成默认 task-flow 心智
2. 不要再让 task-local artifact 依赖隐式当前 task
3. 不要让缺省路径偷偷触发治理升级
