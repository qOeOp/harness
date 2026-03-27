# Task Artifact Routing

更新日期：`2026-03-27`

## 目的

把 `research dispatch / source note / research memo / decision pack / checkpoint` 这类正式 artifact 的默认落点收敛到一套单一规则，避免最小 runtime 和治理 workspace 同时冒充默认真相。

## 当前缺陷

本轮审计发现的 task-flow 问题：

1. 多个 active skills 与 templates 仍把正式 artifact 默认写到 `.harness/workspace/*`。
2. 多个 `new_*` 脚本只有在显式传 `--work-item` 时才会保持 task-scoped；否则会悄悄退回全局 workspace。
3. `validate_freshness_gate.sh` 只扫描 governance-style workspace artifacts，导致 canonical task-local evidence 可能绕过 freshness 校验。
4. 部分 workflow 文档仍把 governance writeback 写成默认闭环，稀释了 `minimum-core` 的单任务闭环。

## Divergent Hypotheses

1. 保持 `.harness/workspace/*` 作为默认正式 artifact 面，task 目录只存状态。
2. 所有 artifact 永久只留在 task 目录，完全禁止 promotion 到治理面。
3. 默认 `task-local first`，只有在显式启用 `advanced governance mode` 且确有跨任务价值时，才把 artifact promote 到 `.harness/workspace/*`。

## First Principles Deconstruction

先回到第一性原理：

1. 一个 agent 要恢复当前工作，首先需要知道“当前任务是什么”，不是先看公司级总目录。
2. 与某个 task 强绑定的证据和决策，默认应该贴着该 task 存放，才能最小化检索面和误读面。
3. 人工 review、Founder 决策、跨任务沉淀属于升级动作，应该显式 promote，而不是被默认路径偷偷触发。
4. `minimum-core` runtime 必须在没有 governance tree 的情况下也能完整执行、暂停、恢复、校验。
5. 校验面必须覆盖 canonical path；否则“正确写法”会反而失去 guardrail。

## Convergence To Excellence

采纳第 3 条路线：

`task-local first, governance by explicit promotion`

原因：

1. 它保留了长期治理沉淀的能力，但不让治理表面反向定义默认任务流。
2. 它符合 OpenAI / Anthropic / LangGraph 一致强调的模式：先用简单、清晰、可恢复的工作流，再在需要处加 durability、human checkpoint 和 promotion。
3. 它让 `current task -> task.md -> progress.md -> task-scoped refs/working/outputs` 成为真正最短可恢复路径。

## Canonical Rules

### 1. 默认落点

在 `minimum-core` runtime 中，正式 artifact 必须优先绑定到某个 work item。

绑定顺序：

1. 显式 `--work-item <WI-xxxx>`
2. 否则读取 `.harness/current-task`
3. 若两者都没有，且 runtime 不是 `advanced governance mode`，则拒绝创建全局 artifact

### 2. Canonical Task-Local Paths

默认 task-local 路径：

1. `Research Dispatch`
   - `.harness/tasks/<task-id>/working/<date>-<slug>-research-dispatch.md`
2. `Source Note`
   - `.harness/tasks/<task-id>/refs/sources/<date>-<slug>.md`
3. `Research Memo`
   - `.harness/tasks/<task-id>/refs/<date>-<slug>-research-memo.md`
4. `Decision Pack`
   - `.harness/tasks/<task-id>/refs/<date>-<slug>-decision-pack.md`
5. `Checkpoint / closeout-style snapshot`
   - 默认写回该 task 的 `progress.md`、`outputs/` 或 `closure/`

### 3. Governance Promotion

只有在以下条件同时满足时，才允许写到 `.harness/workspace/*`：

1. runtime 已显式启用 `advanced governance mode`
2. artifact 的价值确实超出单个 task
3. operator 明确希望沉淀到 company / founder / department 级视图

promotion 是显式升级动作，不是默认路径 fallback。

### 4. Freshness Gate Coverage

任何 freshness / evidence 校验都必须同时理解：

1. task-local `dispatch / source / research / decision`
2. governance-promoted `dispatch / source / decision / briefs`

### 5. Skills And Templates

skills、workflow 文档和模板必须先教 task-local 写法，再说明 governance promotion。

禁止再把 `.harness/workspace/*` 写成默认 task-flow 心智。
