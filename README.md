# Harness

`harness` 不是普通的技能仓库，也不该先被理解成一个“公司治理操作系统”。

它更准确的定位是：

`agent execution substrate = /harness 入口 + agent-readable repo map + minimal resumable task runtime + deterministic validation/evals + observability/replay + optional governance projections`

换句话说，它首先是给 agent 用的执行底座，其次才是治理系统。

这个 source repo 负责六件事：

1. 定义入口：`SKILL.md`
2. 定义能力包：`skills/`
3. 定义责任与路由基线：`roles/`、`docs/workflows/`
4. 定义合同：`references/`
5. 提供执行器：`scripts/`
6. 提供可验证、可审计、可恢复的读取与写回入口

它不保存任何 consumer repo 的 live runtime truth。真正运行时的任务状态，只会按需 materialize 到 consumer repo 的 `.harness/`。

## 第一性原理

一个 production-grade agent harness，首先必须解决的不是“怎么模拟组织”，而是下面这些更底层的问题：

1. agent 能不能快速读懂当前 repo
2. 长任务在跨 session / 跨 context window / 工具失败后，能不能从中断点恢复
3. agent 的动作有没有可重复验证的反馈回路
4. 状态为什么改变、改变到了哪里，能不能回放与解释
5. 只有在跨任务协调真的存在时，才引入治理投影

因此，`harness` 的默认产品心智不是“模拟一家公司”，而是“让 agent 在 repo 内可读、可做、可恢复、可验证、可追踪”。

## 结构心智

`harness` 里有四类结构对象，但它们不是同一种东西：

| Layer | Meaning | Canonical Surface |
| --- | --- | --- |
| `root` | 宪法层、共享底座、总入口 | `SKILL.md`, `docs/`, `references/`, `roles/`, `scripts/` |
| `skills` | 自包含能力 bundle | `skills/*` |
| `roles` | 责任主体与默认路由基线 | `roles/*` |
| `workstreams` | runtime-local cross-task 视图与协作投影 | `.harness/workspace/workstreams/*` when materialized |

一句话：

1. `skill` 不是 agent
2. `role` 不是 skill
3. `workstream` 不是 source repo 顶层目录
4. 组织结构是树，能力结构是图
5. runtime primitive 先于 governance projection

详细地图见：

- [governance-capability-map.md](/Users/vx/WebstormProjects/harness/docs/organization/governance-capability-map.md)

## 一句话心智模型

`harness = /harness 入口 + agent-readable repo map + 按需 materialize 的 minimal task-record runtime + deterministic validation/evals + observability/replay + optional governance projections`

这几个词的优先级不要搞反：

1. 先有 legibility
2. 再有 runtime continuity
3. 再有 verification loops
4. 再有 observability / replay
5. 最后才是 governance projection

## 四层分层

```mermaid
flowchart TD
    A["/harness<br/>产品入口"] --> B["source repo map<br/>skills / roles / docs / scripts / references"]
    A --> C[".harness/<br/>task-record runtime"]
    C --> D["verification loops<br/>tests / audits / freshness / review"]
    C --> E["observability / replay<br/>recovery / transitions / queryable state"]
    C --> F["optional governance projections<br/>组织治理 / cadence / cross-task views"]
```

对应参考：

- [references/layering.md](/Users/vx/WebstormProjects/harness/references/layering.md)
- [references/runtime-workspace.md](/Users/vx/WebstormProjects/harness/references/runtime-workspace.md)
- [references/top-level-surface.md](/Users/vx/WebstormProjects/harness/references/top-level-surface.md)
- [task-record-runtime-tree-v2.toml](/Users/vx/WebstormProjects/harness/references/contracts/task-record-runtime-tree-v2.toml)
- [org-chart.md](/Users/vx/WebstormProjects/harness/docs/organization/org-chart.md)
- [governance-capability-map.md](/Users/vx/WebstormProjects/harness/docs/organization/governance-capability-map.md)

## Skills Are Bundles

`skills/*` 是最重要的能力面，应该坚持自包含。

如果某个 capability 专用的文档、模板、脚本、rubric 只服务一个 skill，就优先放进该 skill：

```text
skills/<bundle-slug>/
  SKILL.md
  manifest.toml
  refs/
  templates/
  scripts/
```

不要把只服务一个 skill 的 `templates / refs / scripts` 回流到 root。

root 只保留：

1. 全局 contract
2. 全局 workflow
3. 共享脚本基础设施
4. baseline role 定义
5. 总导航与审计入口

## Skills Need Progressive Disclosure

`skills/*` 不只是“自包含”，还应当满足“窄触发、晚展开”。

一个好的 skill bundle，默认应做到：

1. `SKILL.md` 先回答触发条件、目标产出、读取顺序
2. 详细说明、模板、脚本放在 `refs/`、`templates/`、`scripts/`，只在命中 skill 后按需读取
3. skill 描述负责路由，skill 内部材料负责深度，不把所有上下文常驻在 root 入口
4. skill 的目标是压缩默认上下文，而不是重新制造一个巨型总提示词
5. 若 skill 会驱动 subagent / hooks / MCP，还应显式声明它的 tool scope、memory scope 与 verification expectation，避免“会用但边界不明”

## Frontier Priority

如果按 2025-2026 社区里更稳的 harness 经验排序，优先级应是：

1. agent legibility
   - 入口短
   - 读取顺序稳定
   - 文档可按需展开
2. resumability
   - 长任务跨 context window 仍可恢复
   - 当前 focus、next command、history 可回放
   - `task truth`、`execution checkpoint`、`transport state` 必须分层
3. deterministic verification
   - tests、audit、freshness gate、review loop 必须可重复执行
4. observability and replay
   - state transition 要能解释
   - query surface 要能回放当前工作面
   - recovery 写回不能形成第二套平行账本
5. optional governance projection
   - 跨任务投影、部门协作、cadence 只在需要时启用

因此 `harness` 的默认产品心智不是“模拟一家公司”，而是“让 agent 在 repo 内可读、可做、可恢复、可验证、可追踪”。

## Runtime Primitives First

`harness` 的默认 runtime，不应先从部门、角色、board 出发，而应先从几个更底层的 primitive 出发：

1. `task record`
   - 当前任务为何存在、处于什么状态、下一步做什么
2. `attachments`
   - task-local 正式材料与证据
3. `transitions`
   - 状态迁移与可审计历史
4. `locks`
   - 受控状态修改期间的并发保护
5. `execution checkpoints`
   - 可选的 engine-local step snapshots，用于 durable execution、resume、fork 与 pending writes
6. `query`
   - 面向 agent 的读取视图，而不是账本本体
7. `validation`
   - 对 runtime contract、文档系统、freshness 与状态机的可重复验证

`roles` 与 `workstreams` 可以存在，但它们默认应被理解成 routing / coordination / cross-task projection，而不是 runtime substrate 本体。

## Governance Capability Families

当前 skills 更适合按治理能力理解，而不是当作一条单流水线：

1. intake and framing
   - `founder-brief`, `meeting-router`, `brainstorming-session`, `vision-meeting`
2. discovery and evidence
   - `research`, `capability-scout`
3. scope and decision
   - `requirements-meeting`, `decision-pack`, `acceptance-review`
4. memory and writeback
   - `memory-checkpoint`, `daily-digest`
5. governance and compounding
   - `governance-meeting`, `process-audit`, `os-audit`, `retro`

## 最小 runtime

v2 的最小 runtime 已经收敛到 flat task-record：

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  tasks/
    WI-xxxx/
      task.md
      attachments/
      closure/
      history/
        transitions/
  locks/
```

核心约束：

1. `task.md` 是唯一任务执行真相
2. Recovery 写在同一个 `task.md` 里
3. `archived` 用状态字段表达
4. board 不是默认 runtime contract；默认改为 shell query
5. v2 core 故意不把 per-step checkpoint store 直接写进默认目录合同；若某个 engine 需要 `thread_id`、`checkpoint_id`、pending writes 或 fork metadata，应保持 engine-local、可替换、可垃圾回收，不上升为第二套 task truth

## 三层状态边界

2025-2026 的 frontier agent runtime，已经越来越常见地提供 durable conversation state、background jobs、server-side compaction、stream resume、workflow checkpoints 与 provider-owned threads。

这些能力都很有用，但它们不是同一种 state。默认应分成三层：

1. `task truth`
   - `task.md`、`attachments/`、`history/transitions/` 组成跨 provider、跨 session 稳定的 canonical task state
2. `execution checkpoint state`
   - workflow engine 的 `thread_id`、`checkpoint_id`、pending writes、fork point、interrupt cursor 等细粒度执行快照
   - 它可以 durable，也可以比 `task.md` 更频繁写入，但它是 engine-local execution state，不是任务真相
3. `transport state`
   - provider conversation / response / thread / background job / compaction item / stream cursor 等 provider-owned state
   - 它可以 durable，也可以跨 session / job 存活，但仍然只是 transport layer，不应直接驱动业务状态机

补充边界：

1. opaque compaction item、raw transcript、provider thread history、checkpoint internals 都不应直接晋升为 canonical task state
2. 若需要恢复 engine run 或 provider run，可在 `task.md` 的 recovery 或 `history/` 中记录临时 execution handles，例如 `thread_id`、`checkpoint_id`、`response_id`、`conversation id`、`stream cursor`、`trace id`、`request id`
3. 这些 handles 只服务 reconnect / resume / fork / cancel / trace correlation，过期可替换
4. 真正跨 provider、跨 session 稳定的恢复入口，仍应回到 `task.md`、`attachments/` 与 `history/transitions/`

## `task.md` 是什么

`.harness/tasks/WI-xxxx/task.md` 是唯一任务执行真相，也是 human + agent 的主读取入口。

注意边界：

1. 它是 task execution state 的 canonical record
2. 它不是代码真相，代码真相仍在 repo
3. 它不是测试真相，测试真相仍在 tests / audit outputs
4. 它不是需求全文真相，正式材料仍在 `attachments/` 与相关 spec
5. 它不是第二套 workflow engine；真正状态迁移仍受脚本、锁与验证面约束
6. 它不是 execution checkpoint store；若某个 runtime 需要 `thread_id`、`checkpoint_id`、pending writes 或 fork metadata，这些属于 engine-local execution state
7. 它不是 provider transport state；conversation state、background response、opaque compaction item 只应作为可替换的执行句柄
8. 它的职责是把“当前任务为什么在这里、现在该做什么、下一步怎么恢复”压缩成单一入口

同时要注意：

1. `task.md` 是面向人和 agent 的 canonical surface
2. machine-readable contract 仍由 `references/contracts/*` 与验证脚本约束
3. 如果未来需要更细粒度 machine state，也应从 task record 派生，而不是再引入第二套平行 truth

它不只是轻 ticket，而是一个重实体 task record，至少承载这几组字段：

1. 身份与主状态
   - `ID`
   - `Title`
   - `Type`
   - `Status`
   - `Priority`
2. claim / 执行上下文
   - `Assignee`
   - `Worktree`
   - `Claimed at`
   - `Claim expires at`
   - `Lease version`
3. 流程路由
   - `Current stage owner`
   - `Current stage role`
   - `Next gate`
4. gate / 签字状态
   - `Decision status`
   - `Review status`
   - `QA status`
   - `UAT status`
   - `Acceptance status`
5. 恢复协议
   - `## Recovery`
   - `Current focus`
   - `Next command`
   - `Recovery notes`
6. 关联材料
   - `Linked attachments`
   - `attachments/`
   - `history/transitions/`

其中 `Current stage role` 是路由元数据，不是 substrate 的第一性对象。

## 主状态机

v2 的主状态只保留：

```text
backlog -> planning -> ready -> in-progress -> review -> done -> archived
```

补充分支：

- 任意执行中可进 `paused`
- 任意阶段可进 `killed`
- `archived` 表示退出默认 active query surface，而不是物理搬目录

`review / QA / UAT / acceptance` 默认不再膨胀成主状态，而是 gate 字段。

## Attachments

task-local 正式材料默认放在 `attachments/`：

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

注意：

1. `Source Note` 是默认正式证据 artifact
2. `Research Memo` 是综合判断 artifact
3. `Research Brief` 只在 collection 复杂时推荐
4. `Evidence Ledger` 是可选台账，不该变成强制 paperwork
5. 默认坚持 task-local first，避免过早 promote 到 governance 面

只有显式 `--promote-governance` 且 runtime 已进入 advanced governance mode，才允许写到 `.harness/workspace/*`。

## 命令面

推荐高层入口：

```bash
./scripts/work_item_ctl.sh status --json --all
./scripts/work_item_ctl.sh start --json company
./scripts/work_item_ctl.sh pause --expected-from-status in-progress --expected-version <v> --interrupt-marker risk-review-required <WI-xxxx>
./scripts/work_item_ctl.sh resume --expected-version <v> <WI-xxxx>
./scripts/work_item_ctl.sh close --json --target-status review --work-item <WI-xxxx> company
./scripts/query_work_items.sh --status in-progress --assignee codex
```

注意：

1. `status` 现在是 `query` 别名，不再是“open 当前焦点”
2. task-local artifact 写回一律要求显式 `--work-item`
3. `./scripts/upsert_work_item_recovery.sh` 写入 `task.md` 的 `## Recovery`

## 运行时读取顺序

materialized runtime 下，正确读取顺序是：

1. `.harness/README.md`
2. `.harness/entrypoint.md`
3. `./scripts/query_work_items.sh` 的结果，或明确的 `.harness/tasks/<task-id>/task.md`
4. 若状态为 `in-progress` / `paused`，再读该 task 的 `## Recovery`
5. 若该 task 绑定某个 durable execution engine，再读必要的 `thread_id / checkpoint_id / pending writes / interrupt cursor`
6. 若该 task 仍绑定 in-flight provider execution，再读必要的 `response_id / conversation id / thread id / stream cursor / trace id`
7. 只在需要时读取 `attachments/` 和 `history/transitions/`

## 验证、审计与可回放性

frontier harness 的关键不是“有状态”，而是“状态可验证、可解释、可恢复”。

因此验证面应被视为一等公民，而不是附属脚本：

framework source repo：

```bash
./scripts/validate_source_repo.sh
./scripts/audit_role_schema.sh
./scripts/run_governance_surface_diagnostic.sh --mode source
```

materialized runtime：

```bash
./scripts/validate_workspace.sh --mode core
./scripts/audit_state_system.sh --mode core
./scripts/audit_document_system.sh
./scripts/validate_freshness_gate.sh --staged
./scripts/run_state_validation_slice.sh
```

对 frontier harness，`tests pass` 仍然不够。验证至少应分三层：

1. result-level
   - tests、audit、freshness gate、review loop、dataset regression 是否通过
2. trace-level
   - decision、tool calls、handoff、retry、interrupt 是否符合预期，可进入 trace grading / trajectory review
3. state-level
   - transitions、locks、writeback、derived views、checkpoint lineage 是否满足 runtime contract

`replay` 在 frontier runtime 里至少有三种含义，不能混写成一个词：

1. `state replay`
   - 从 `task.md`、`attachments/`、`history/transitions/` 重建 query / projection / derived view
   - 这部分才追求 contract-level determinism
2. `execution resume / fork`
   - 从 `thread_id`、`checkpoint_id`、pending writes 或 interrupt point 继续执行
   - 这通常会从某个 restart boundary 重新执行后续步骤，而不是从原代码行号继续
3. `trace replay / trajectory review`
   - 为 debug、evals、incident review 复盘或重跑轨迹
   - 它服务解释性与比较，不承诺 bit-for-bit transcript determinism

因此：

1. LLM calls、interrupts、tool calls、外部 API 在 replay boundary 之后可能再次执行并产生分叉
2. 外部 side effects 应尽量 idempotent，或被包进可单独恢复的 task / node 边界

当前 runtime 的可回放入口主要来自：

1. `task.md` 的 `## Recovery`
2. `history/transitions/`
3. query 输出
4. audit / validation 输出
5. 可关联的 trace / run identifiers

`observability` 输出应优先携带稳定关联键，例如 `workflow_name`、`trace_id`、`group_id` / `thread_id` / `conversation id`、`provider`、`model`、`operation`、`tool`、`error.type`。若接入 OpenTelemetry 或 vendor tracing，尽量映射到这些通用字段；但实验性 trace schema 不应反过来定义 canonical task contract。

## Enforcement Boundary

README、roles、skills 负责表达 intent；真正“必须发生”的约束，应尽量下沉到工具与权限边界。

默认原则：

1. rules / hooks / managed settings 负责机械约束，而不是只靠叙事提醒
2. MCP / external tools 默认最小授权、最小暴露面
3. subagent / skill / command 默认窄范围 allowlist，而不是全量继承
4. 非可信外部输入先作为 evidence 进入 `attachments/` / `Source Note`，再决定是否 promote 为状态或结论
5. approvals / human gates 属于 trust-boundary control，不属于 organization chart 本体
6. scope escalation 应 progressive / least-privilege，先给低风险读权限，再按需抬到写权限或高风险 tool
7. token / credential 应做 audience binding；禁止 token passthrough
8. local hook / MCP / sidecar 若实际以宿主权限运行，应默认视为高风险组件，并尽量 sandbox

## 设计纪律

1. `task.md` 是唯一任务执行真相
2. query 是视图，不是账本
3. 目录不承载业务状态
4. verification loop 不是附属能力，而是 runtime 主链的一部分
5. observability / replay 是核心能力，不是事后补丁
6. governance 是 projection，不是默认前台叙事
7. Recovery 只回答恢复执行所需的最小问题
8. task-local first，governance by explicit promotion
9. source repo 不保存 consumer runtime 的 live state
10. provider transport memory 可以 durable，但 task truth 必须稳定
11. execution checkpoint 可以细粒度，但不能晋升为第二套任务真相
12. replay 先服务恢复、审计与分叉，不承诺 bit-for-bit transcript determinism
13. 低层约束优先落在 tool / permission boundary，而不是组织叙事
14. trace 优先使用稳定关联键，并尽量映射到通用语义约定
15. 验证既看最终结果，也看 trace 与状态迁移
