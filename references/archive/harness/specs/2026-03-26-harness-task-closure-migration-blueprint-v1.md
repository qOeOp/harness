# Harness Task-Closure Migration Blueprint v1

- Status: proposal
- Date: 2026-03-26
- Scope: migrate the current dual-track runtime from `workspace/state/* + scattered workspace artifacts` into the task-closure asset model
- Related:
  - [2026-03-26-harness-task-closure-asset-model-v1.md](./2026-03-26-harness-task-closure-asset-model-v1.md)
  - [2026-03-26-harness-minimum-core-runtime-contract-v1.md](./2026-03-26-harness-minimum-core-runtime-contract-v1.md)
  - [2026-03-26-harness-surface-buckets-v1.md](../archive/harness/2026-03-26-harness-surface-buckets-v1.md)

## Problem

当前实现同时存在两种心智：

1. 目标契约已经转向最小 runtime
   - `.harness/current-task`
   - `.harness/tasks/`
   - `.harness/progress/`
   - `.harness/artifacts/`
   - `.harness/archive/`
2. 真实脚本实现仍然以旧路径为主
   - `.harness/workspace/state/items`
   - `.harness/workspace/state/progress`
   - `.harness/workspace/state/boards`
   - `.harness/workspace/state/transitions`
   - 以及散落的 `briefs / decisions / research / current`

如果不先给出迁移蓝图，后续只会继续出现：

1. 规范往一边走
2. 脚本往另一边走
3. 用户理解第三套

## Divergent Hypotheses

### Hypothesis 1: Big-Bang Rewrite

一次性把所有脚本、目录、校验、板子都改成 task directory 模型。

优点：

1. 结构最干净
2. 没有长期兼容债

缺点：

1. 风险太高
2. 当前脚本与 audit 面太多
3. 任何一处漏改都会导致 runtime 不可恢复

### Hypothesis 2: Keep The Current Split

继续让规范写 `.harness/tasks/*`，脚本继续读写 `.harness/workspace/state/*`。

优点：

1. 眼前改动最少

缺点：

1. 永远收不拢
2. 用户心智持续混乱
3. task-closure 永远落不到实现

### Hypothesis 3: Staged Migration With Compatibility Window

先冻结概念，再逐步把旧实现收敛到新目录：

1. 保留 task id
2. 先引入 task directory
3. 逐步把 progress、refs、outputs、boards 改成从 task 目录派生
4. 旧路径只做兼容壳，最后删除

## First Principles Deconstruction

迁移蓝图必须优先保护这几件事：

1. 任何时刻都只能有一个 task source of truth
2. pause / resume 不能被迁移打断
3. board 不能因为迁移变成手工维护
4. 已有 artifact link 不能批量腐烂
5. 迁移阶段要允许旧 task 和新 task 共存
6. 引入 task closure 的收益，必须大于 ID 重命名或目录美化带来的 churn

因此：

1. 不适合先改 ID
2. 适合先改目录边界
3. 适合先做 read-compat，再做 write-cutover
4. 适合把 `board` 继续保留为 generated-only
5. 适合把 `brief / research / decision` 的新产物优先落进 task 目录

## Convergence To Excellence

最佳迁移路线是：

> 保留现有 `WI-xxxx` task identity，先把 source of truth 从“单文件 work item + 散落 artifact”迁到“同 ID 的 task directory”，再逐步缩掉旧 `workspace/state/*` 写入面

这意味着：

1. 迁移期不改主 ID 命名
2. `WI-0001` 先变成目录名，而不是先改成 `T-0001`
3. 先减少状态平面数量，再追求名字漂亮

## Non-Negotiable Migration Rules

1. 迁移期间禁止同时维护两份可写 task truth
2. 旧路径最多只允许：
   - 只读兼容
   - 自动生成镜像
   - redirect stub
3. 新任务一旦进入新模型，就不再向旧全局 brief 树写主文件
4. 任何 close / archive 流程都必须经过 `task closure`，不能直接丢文件

## Current To Target Mapping

### Identity And State

| Current | Target | Decision |
| --- | --- | --- |
| `.harness/workspace/state/items/WI-0001.md` | `.harness/tasks/WI-0001/task.md` | `task.md` 成为 source of truth |
| `.harness/workspace/state/progress/WI-0001.md` | `.harness/tasks/WI-0001/progress.md` | 原 progress 语义保留，位置迁移 |
| `.harness/current-task` | `.harness/current-task` | 保留，继续只做指针 |
| `.harness/workspace/state/transitions/` | `.harness/tasks/WI-0001/history/` 或 task-scoped ledger | 先兼容保留，后续 task-scoped 化 |

### Task Assets

| Current | Target | Decision |
| --- | --- | --- |
| `.harness/workspace/briefs/*.md` | `.harness/tasks/WI-0001/working/*` 或 `refs/*` | 不再做默认全局 active 层 |
| `.harness/workspace/decisions/log/*.md` | task 内 `refs/decision-pack.md` + 可选 promote 到 `memory/decisions/` | 先 task 闭包，再决定是否全局 promote |
| `.harness/workspace/research/dispatches/*.md` | task 内 `working/research-dispatch.md` 或 `refs/research-dispatch.md` | 默认 task-local |
| `.harness/workspace/research/sources/*.md` | task 内 `refs/sources/` 或 task-local evidence bundle | 来源跟 task 走 |
| `.harness/workspace/current/*.md` | `task.md` / `closure/closeout.md` / promoted memory | 减少“全局 current”作为执行入口 |

### Views And Derived Surfaces

| Current | Target | Decision |
| --- | --- | --- |
| `.harness/workspace/state/boards/company.md` | `.harness/boards/company.md` | 继续 generated-only |
| `.harness/workspace/state/boards/founder.md` | `.harness/boards/founder.md` | 继续 generated-only |
| `.harness/workspace/departments/*/workspace/board.md` | 保留为 advanced governance view | 不属于最小 runtime 主骨架 |

## Canonical Target Tree During Migration

迁移期建议采用这棵树：

```text
.harness/
  manifest.toml
  current-task
  inbox/
  boards/
    company.md
    founder.md
  tasks/
    WI-0001/
      task.md
      progress.md
      refs/
        index.toml
      working/
        discussions/
        agent-passes/
        scratch/
      outputs/
      closure/
        closeout.md
        promotion-log.md
      history/
        transitions/
  memory/
    decisions/
    research/
    patterns/
  archive/
    tasks/
```

关键判断：

1. 迁移 v1 继续保留 `WI-xxxx` 作为 task id
2. `task.md` 与 `progress.md` 进入 task 目录
3. `refs/working/outputs/closure/` 成为 task 闭包的标准子树
4. board 从 task 目录派生

## Compatibility Strategy

### Stage A: Read Compatibility

目标：

1. 新代码优先读新路径
2. 若新路径不存在，再 fallback 读旧路径

读取顺序：

1. `.harness/tasks/WI-0001/task.md`
2. fallback `.harness/workspace/state/items/WI-0001.md`

progress 同理：

1. `.harness/tasks/WI-0001/progress.md`
2. fallback `.harness/workspace/state/progress/WI-0001.md`

### Stage B: Write Cutover

目标：

1. 所有新写入只落新路径
2. 如旧脚本仍依赖旧路径，则由兼容壳自动同步

原则：

1. 不能让人手工改两处
2. 不能让脚本随机决定写哪边

### Stage C: Redirect / Mirror Expiry

当所有主脚本都已切到新路径后：

1. 旧 item 文件改成 redirect stub 或只读镜像
2. 旧 progress 文件改成 redirect stub 或删除
3. 校验脚本开始拒绝旧路径写入

### Stage D: Legacy Removal

删除：

1. `.harness/workspace/state/items/` 作为主数据平面
2. `.harness/workspace/state/progress/` 作为主数据平面
3. 对旧路径的写入逻辑

保留：

1. 归档快照
2. 必要 redirect
3. migration ledger

## Script Migration Order

### Wave 1: Path Abstraction

先改这些底层函数与 helper：

1. `scripts/lib_state.sh`
2. `work_item_path()`
3. `work_item_progress_path()`
4. `list_work_items()`
5. artifact link 解析 helper

目标：

1. 把“路径是什么”从业务脚本里抽掉
2. 业务脚本不直接假设 `workspace/state/items`

### Wave 2: Task Lifecycle Control

再改这些入口：

1. `scripts/new_work_item.sh`
2. `scripts/start_work_item.sh`
3. `scripts/pause_work_item.sh`
4. `scripts/resume_work_item.sh`
5. `scripts/complete_work_item.sh`
6. `scripts/transition_work_item.sh`
7. `scripts/open_current_work_item.sh`
8. `scripts/select_work_item.sh`

目标：

1. 新建 task 时直接建目录闭包
2. start / pause / resume / close 全部围绕 task directory 工作

### Wave 3: Artifact Routing

然后改 artifact 脚本：

1. `scripts/new_decision.sh`
2. `scripts/new_research.sh`
3. `scripts/new_research_dispatch.sh`
4. `scripts/new_source_note.sh`
5. `scripts/link_work_item_artifact.sh`
6. `scripts/archive_brief.sh`
7. `scripts/report_brief_registry.sh`

目标：

1. 新 artifact 默认先落 task 内
2. 全局层只保留 promote 后资产

### Wave 4: Boards And Review Surfaces

最后改：

1. `scripts/refresh_boards.sh`
2. `scripts/render_founder_review_page.js`
3. `scripts/github_projects_sync_adapter.sh`

目标：

1. 从 task 目录读数据
2. 不再依赖旧 `workspace/state/items` 作为数据源

### Wave 5: Validation And Audit

最后收口：

1. `scripts/validate_workspace.sh`
2. `scripts/audit_document_system.sh`
3. `scripts/audit_state_system.sh`
4. `scripts/run_state_validation_slice.sh`

目标：

1. 让 audit 保护新模型，而不是继续保护旧分裂结构

## File-Level Migration Rules

### Rule 1: Old Item File To New Task Directory

旧：

```text
.harness/workspace/state/items/WI-0001.md
```

新：

```text
.harness/tasks/WI-0001/task.md
```

迁移字段：

1. `ID` -> `Task ID`
2. `Title` -> `Title`
3. `Status` -> `Status`
4. `Objective` -> `Goal`
5. `Done criteria` -> `Deliverable` / acceptance fields
6. `Linked artifacts` -> `Pinned refs` + `Outputs`

### Rule 2: Progress File Must Move With Task

progress 不再是平铺全局路径，而是 task 的局部状态。

旧：

```text
.harness/workspace/state/progress/WI-0001.md
```

新：

```text
.harness/tasks/WI-0001/progress.md
```

### Rule 3: New Intermediate Artifacts Must Default To `working/`

以下新文件默认不应继续写全局主目录：

1. brainstorming notes
2. raw research notes
3. internal discussions
4. agent pass outputs

它们应优先进入：

```text
.harness/tasks/WI-0001/working/
```

### Rule 4: Adopted Artifacts Must Snapshot Into `refs/`

当一个 research memo、decision pack、review brief 被正式采用后：

1. 复制或生成稳定快照进入 `refs/`
2. 在 `refs/index.toml` 记录 adopted metadata
3. 在 `task.md` 记录 `Pinned refs`

### Rule 5: Close Requires `closure/closeout.md`

`done` 或 `killed` 之前，必须先写：

```text
.harness/tasks/WI-0001/closure/closeout.md
```

它至少回答：

1. 任务结论是什么
2. 哪些 refs 被保留
3. 哪些 working 文件被 compact / pruned
4. 哪些结果被 promote 到 memory

## Board Semantics During Migration

这里有一个必须说透的决策：

`board` 不应该和 task directory 一起进入 archive。

原因：

1. board 是 derived surface
2. task 才是 record
3. archived board 没有新的独立信息密度

所以正确做法是：

1. active board 只显示非 terminal task
2. archived task 通过 task closure 回放
3. 若 Founder 需要历史视图，单独生成 report，而不是保存旧 board 当真相

## Memory Promotion Policy

只有这三类东西值得从 task 中提升到全局 `memory/`：

1. 已稳定的决策
2. 可复用研究结论
3. pattern / trap / playbook

其余内容默认留在 task 闭包中，不做全局化。

## Risks

### Risk 1: 过早改 ID

如果迁移第一步就把 `WI-0001` 改成 `T-0001`，会造成：

1. 脚本 churn
2. 链接 churn
3. 用户认知 churn

但几乎没有产品收益。

因此 v1 明确不做 ID 重命名。

### Risk 2: Dual Write Drift

如果新旧路径长期双写，很容易漂。

因此兼容期应优先：

1. 新路径主写
2. 旧路径镜像
3. 尽快结束双写

### Risk 3: Artifact Promotion Without Discipline

如果所有 retained artifact 都 promote 到 memory，全局层还是会膨胀成垃圾场。

因此必须坚持：

1. task closure 默认本地保留
2. memory 只收稳定复用资产

## Recommended Migration Phases

### Phase 0: Freeze Semantics

做法：

1. 批准本 blueprint
2. 停止再增加新的全局 active artifact 类型
3. 新设计以 task closure 为唯一方向

### Phase 1: Introduce New Task Directory Skeleton

做法：

1. 在 `lib_state.sh` 增加新路径 helper
2. `new_work_item.sh` 可创建 `.harness/tasks/WI-0001/`
3. task 目录内生成：
   - `task.md`
   - `progress.md`
   - `refs/`
   - `working/`
   - `outputs/`
   - `closure/`

### Phase 2: Move Control Plane

做法：

1. start / pause / resume / complete 改读写 `task.md`
2. progress 改读写 `progress.md`
3. `current-task` 指向 task id，不变

### Phase 3: Move Artifact Plane

做法：

1. new decision / research / review 默认写 task 内
2. `briefs/` 不再承担默认 active 主平面
3. `refs/index.toml` 上线

### Phase 4: Rebuild Board Plane

做法：

1. board 从 task directory 派生
2. founder review page 从 task closure 读 supporting artifacts

### Phase 5: Remove Legacy State Plane

做法：

1. 旧 state paths 只留 redirect 或 archive
2. audit 拒绝旧主写入
3. 文档更新为单一心智

## Sharp Conclusion

真正该迁移的不是“文件位置”本身，而是：

1. 从“全局目录堆积中间态”
2. 迁到“task 闭包保留 adopted refs，working 默认可清理”

因此本蓝图的核心不是 rename，而是：

1. task directory 化
2. ref snapshot 化
3. working 垃圾回收化
4. board 派生化
5. memory 显式 promote 化
