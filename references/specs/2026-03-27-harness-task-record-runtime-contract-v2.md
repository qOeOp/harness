# Harness Task-Record Runtime Contract v2

- Status: accepted
- Date: 2026-03-27
- Scope: define the active minimum runtime as a flat task-record system with header-driven workflow, routing, and signoff
- Related:
  - [references/layering.md](../../references/layering.md)
  - [references/runtime-workspace.md](../../references/runtime-workspace.md)
  - [references/top-level-surface.md](../../references/top-level-surface.md)
  - [references/contracts/task-record-runtime-tree-v2.toml](../../references/contracts/task-record-runtime-tree-v2.toml)

## Contract Summary

`harness` 的默认 minimum runtime 采用 `task-record` 模型。

核心要求只有四条：

1. `.harness/tasks/<task-id>/task.md` 是唯一任务真相
2. Recovery 与主状态同文件共存
3. task-local 正式材料默认进入 `attachments/`
4. `archived` 用状态字段表达，而不是目录迁移

## Target Tree

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  runtime/
  tasks/
    WI-0001/
      task.md
      attachments/
      closure/
      history/
        transitions/
  locks/
```

规则：

1. `runtime/` 是按需出现的 non-canonical support root，用于 cache、tool home、isolated env 等 operational state
2. `attachments/`、`closure/`、`history/transitions/` 按需创建
3. 默认 query 直接从 `task.md` header 派生
4. board 不属于默认 runtime contract

## Runtime Support State Boundary

`.harness/runtime/` 允许承载 tool-owned support state，但它不是 canonical task truth。

补充规则：

1. 若 support state 会 durable 到进程外、跨 session 或跨重启恢复，必须带显式 schema / format version
2. 跨代码版本恢复这类 state 时，默认要 migrate 或 fail closed
3. raw checkpoint internals、serialized agent state、provider-owned blobs 不能直接晋升为 task truth

## Lock And Claim Boundary

`.harness/locks/` 与 `task.md` 头部 claim 字段分别服务两个不同层次：

1. `.harness/locks/`
   - 短生命周期的 mutation guard
   - lock dir 元数据默认应带 `owner`、`claimed_at`、`lease_expires_at`、`lease_id` 与 `pid`
   - stale reclaim 以 lease 过期或 pid 已死为准
2. `task.md` claim header
   - task-level claim snapshot，而不是 mutex 本体
   - 用于解释当前谁持有执行 claim、在哪个 worktree、claim 何时过期、lease 已轮换到哪个版本

两者都重要，但职责不同，不能互相替代。

## Canonical Task Record

### Required Header Fields

1. `Schema version`
2. `State authority`
3. `State version`
4. `Last operation ID`
5. `ID`
6. `Title`
7. `Type`
8. `Status`
9. `Priority`
10. `Owner`
11. `Sponsor`
12. `Assignee`
13. `Worktree`
14. `Claimed at`
15. `Claim expires at`
16. `Lease version`
17. `Objective`
18. `Ready criteria`
19. `Done criteria`
20. `Current stage owner`
21. `Current stage role`
22. `Next gate`
23. `Founder escalation`
24. `Decision status`
25. `Review status`
26. `QA status`
27. `UAT status`
28. `Acceptance status`
29. `Blocked by`
30. `Current blocker`
31. `Next handoff`
32. `Linked attachments`
33. `Created at`
34. `Updated at`
35. `Archived at`

### Recommended Sections

1. `## Summary`
2. `## Recovery`
3. `## Workflow Notes`
4. `## Signoff Notes`
5. `## Attachment Notes`
6. `## Transition Log`
7. `## Notes`

### Recovery Fields

`## Recovery` 至少应包含：

1. `Current focus`
2. `Next command`
3. `Recovery notes`

若任务是长回合、会委派 worker、或可能超过当前 session，
`Recovery notes` 还应写明 budget / stop boundary，
例如 `max turns / iterations`、timebox、tool / write budget、
pause / cancel / kill semantics。

## Bootstrap vs Steady-State

frontier 长任务默认把 bootstrap 与 steady-state 分开建模。

规则：

1. bootstrap session 负责 materialize 最小运行面：
   - `task.md`
   - 必要的 `## Recovery`
   - baseline smoke / baseline check 入口
   - 若 feature / acceptance progress 会跨 session 累计，则补 task-local `Acceptance Ledger`
2. steady-state session 默认消费同一份 task truth：
   - 先读 `task.md`
   - 再读 `## Recovery`
   - 再看最近 transition / progress / 必要附件
   - 先跑一个 cheap baseline check，再执行 `Next command`
3. 若进度需要跨回合累计，优先写 task-local、结构化、可机读 ledger，
   不要只写 narrative prose、provider transcript 或聊天结论
4. 每次长回合结束时，应至少留下：
   - next command
   - validated completion boundary
   - checkpoint、acceptance status 或其他 reviewable artifact 之一

### Claim / Lease Fields

`Claimed at`、`Claim expires at` 与 `Lease version`
不是占位字段，而是 active claim 的正式快照。

默认规则：

1. `in-progress` 与 `paused` task 必须带：
   - `Assignee`
   - `Worktree`
   - `Claimed at`
   - `Claim expires at`
   - `Lease version`
2. 进入 active execution 时，claim expiry 默认按可续租的小时级 lease 生成
3. 当前 shell runtime 默认通过 `HARNESS_CLAIM_LEASE_HOURS`
   控制 lease 时长；未显式配置时使用仓库默认值
4. 离开 active execution 后，应清掉 claim snapshot，
   避免把过期 claim 误当当前执行真相

## State Model

### Primary Statuses

1. `backlog`
2. `planning`
3. `ready`
4. `in-progress`
5. `review`
6. `paused`
7. `done`
8. `killed`
9. `archived`

### Gate Fields

以下能力通过 gate 字段承载，而不是主状态：

1. `Decision status`
2. `Review status`
3. `QA status`
4. `UAT status`
5. `Acceptance status`

## Workflow Routing

task record 同时承载状态与路由。

当前处理链路至少通过这些字段表达：

1. `Current stage owner`
2. `Current stage role`
3. `Next gate`
4. `Founder escalation`

## Slow Human Gate Model

慢速 human approval / review / feedback 不应被建模成隐藏的 in-flight waiting state。

默认处理方式：

1. 若等待会跨 session 或超出当前 run，自任务主状态切到 `paused`
2. 用 `Interrupt marker` 与 `Resume target` 表达暂停语义，而不是只写自由文本 blocker
3. 人审完成后通过正式 resume transition 恢复，而不是假设原 run 会继续挂起等待
4. `resume` 默认是 checkpoint-relative、node-level re-entry，
   不是 instruction-pointer continuation
5. resume 后边界前代码可能重跑，
   外部副作用必须具备 effect fence、expected version、
   idempotency key 或被移到边界之后

## Wait / Wakeup Model

wait / wakeup 是 runtime contract，不是活着的线程偶然还在。

默认要求：

1. webhook、queue、async callback、
   background job completion
   这类跨 run 唤醒，应留下显式 wakeup handle
   或 event reference
2. 外部 wakeup 默认按 at-least-once delivery 设计，
   恢复链路应带 dedupe / idempotency key
3. provider thread、response、stream cursor
   这类 transport handle 只服务 reconnect / resume /
   correlation，不构成 exactly-once 保证

## Session Continuity Boundary

provider / SDK continuation handle
只表示 transport / session continuity，
不等于 instruction continuity。

默认要求：

1. `system / developer / policy / prompt object /
   managed settings`
   默认要显式重放、重绑版本
   或重新注入
2. provider-native reasoning / compaction artifact
   若 provider 要求回传，
   默认只做 continuation payload，
   不手改、不解析成业务状态
3. serialized app / agent / session context
   一旦持久化，
   就按 persisted data 治理，
   必须带 schema / format version
4. 跨代码版本恢复 serialized context
   时要 migrate 或 fail closed
5. raw secret、raw credential、
   高敏感 token
   不应写入 serialized app / agent / session context；
   默认只保留 handle、scope 与 expiry

## Budget / Termination Model

bounded autonomy 也是 runtime contract 的一部分，而不是聊天习惯。

默认要求：

1. 长任务在进入持续执行前，应把 budget / stop boundary 写进 `task.md` 的恢复面或对应 artifact
2. budget 命中、cancel、kill、timebox 触发时，
   应落成 transition reason、recovery 更新或正式 reviewable artifact
3. 终止原因必须可审计，不能只留在临时日志里

## Attachment Routing

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
7. Optional `Acceptance Ledger`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-acceptance-ledger.md`
8. `Checkpoint`
   - `.harness/tasks/<task-id>/attachments/<date>-<slug>-checkpoint.md`
9. `Role Change Proposal`
   - `.harness/tasks/<task-id>/closure/<date>-<slug>-role-change-proposal.md`

长任务若需要跨 session 维护 feature / acceptance checklist，
优先使用 `Acceptance Ledger` 这类结构化、可机读附件，
不要把“已完成 / 已验证”只留在 prose 或 provider transcript。

## Query Surface

默认 query 行为：

1. shell 动态查询
2. 默认排除 `archived`
3. 通过 header 过滤 `status / assignee / role / next gate / gate status`
4. 不依赖 persisted board

## Validation Surface

source repo：

1. [validate_source_repo.sh](/Users/vx/WebstormProjects/harness/scripts/validate_source_repo.sh)
2. [run_surface_diagnostic.sh](/Users/vx/WebstormProjects/harness/scripts/run_surface_diagnostic.sh)

materialized runtime：

1. [validate_workspace.sh](/Users/vx/WebstormProjects/harness/scripts/validate_workspace.sh)
2. [audit_document_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_document_system.sh)
3. [audit_state_system.sh](/Users/vx/WebstormProjects/harness/scripts/audit_state_system.sh)
4. [run_state_validation_slice.sh](/Users/vx/WebstormProjects/harness/scripts/run_state_validation_slice.sh)

## Observability Capture Boundary

observability / replay 的默认职责是解释执行过程、支持 trace correlation，
而不是把高敏感文本再复制成第二份账本。

默认规则：

1. 完整 prompt、instruction、tool payload 与 model output 默认不做全量采集
2. 内容捕获必须显式 opt-in
3. 优先记录 artifact path、evidence reference、object handle 或 content hash
4. source / provenance metadata
   例如 `tool`、`human approval`、`external evidence`、
   `framework note`
   应独立于 message / transcript / trace display surface 保留，
   不要在转换视图时丢失 trust analysis 所需来源
5. tracing backend 不应成为第二套 canonical task memory 或高敏感语料库

## Non-Goals

1. 不把目录位置当成业务状态
2. 不把 board 当成账本
3. 不把聊天上下文当成长期恢复机制
4. 不把治理投影当成默认 task truth
