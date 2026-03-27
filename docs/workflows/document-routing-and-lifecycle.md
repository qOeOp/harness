# Document Routing And Lifecycle

更新日期：`2026-03-26`

## 目的

为 `/harness` 提供稳定入口，并把当前任务、恢复状态、任务产物与归档历史分离。

## Current Placement

本文件定义默认 `core task runtime` 的 routing / lifecycle 规则。

默认产品入口是：

1. `/harness`

repo-local runtime 只在需要持久化时出现：

1. `.harness/`

本文件不再围绕 root overlay、board-first 路由或广义 company workspace 组织默认体验。

## 设计要求

1. 用户不应该靠扫描全仓库来理解当前任务。
2. 当前正在执行的 task 必须有稳定路径。
3. 恢复信息必须独立于聊天上下文。
4. 历史任务必须保留，但不应该继续占据 active surface。
5. 默认 runtime 不得先天长成公司治理树。

## 当前阶段

- 阶段：`pre-code`
- 目标：先把 `/harness` 默认入口、任务状态模型、恢复协议与最小 writeback 闭环做稳
- 暂不做：公司治理默认化、复杂无人值守自动化、重度多 agent 写代码
- 纪律：当前 stage 没做到极致，不推进下一 stage

## 硬规则

1. 不要默认扫描全仓库 markdown。
2. 任何决定没有 artifact 就视为不存在。
3. 一个问题只能有一个 DRI。
4. `.harness/tasks/<task-id>/task.md` 是默认 task source of truth。
5. `.harness/tasks/<task-id>/progress.md` 只承担恢复协议，不承担决策本体。
6. 一个线程一个 worktree，不共享同一工作目录并行编辑。
7. 外部 `volatile` 主题必须带验证日期、来源和 `Verification mode`。
8. 默认 runtime 不得自动长出 departments、boards、cadence trees。
9. 工具差异只能存在于 provider-specific adapter，不得反客为主。
10. 如果当前层基础不稳，必须 `stop-the-line`，不要为了推进进度继续叠下一层。

## Routing Order

任何新开的 `/harness` 任务，都不应直接扫全仓库。

正确顺序是：

1. 若任务预计一轮内自然收口：
   - 保持 ephemeral session mode
   - 不创建 `.harness/`
2. 若任务需要跨回合追踪、恢复、review、decision 或 research writeback：
   - materialize 最小 runtime
   - 创建 `.harness/manifest.toml`
   - 创建 `.harness/current-task`
   - 创建 `.harness/tasks/<task-id>/task.md`
   - 按需创建 `.harness/tasks/<task-id>/progress.md`
   - 按需创建 `.harness/tasks/<task-id>/refs/` 与 `.harness/tasks/<task-id>/outputs/`
3. 若 runtime 已存在：
   - 先读 `.harness/current-task`
   - 再读 `.harness/tasks/<task-id>/task.md`
   - 若当前状态为 `in-progress` 或 `paused`，再读 `.harness/tasks/<task-id>/progress.md`
   - 新 intake、ready task 的 progress writeback，不得偷改一个已在执行中的 `.harness/current-task`
4. 若当前事项处于 `paused`：
   - 先读 `Interrupt marker` 与 `Resume target`
   - 再决定是否恢复，不要靠聊天记忆猜
   - 一旦显式执行 resume，恢复后的 task 应重新认领 `.harness/current-task`
5. 按任务类型进入对应规则层
   - code change / code review：先读 [code_review.md](./code_review.md)，再读 [agent-operator-contract.md](./agent-operator-contract.md)
   - volatile external task：再读 [volatile-research-default.md](./volatile-research-default.md) 与 [internal-research-routing.md](./internal-research-routing.md)
   - advanced governance task：只有显式升级后，才进入 `docs/organization/` 与 governance workflows
6. 只在需要时读取历史
   - `.harness/archive/`
   - `references/archive/harness/`

## Current Implementation Note

当前 source repo 里的 task kernel 仍主要由脚本实现。

迁移期边界说明：

1. `task` 与 `progress` 的 canonical truth 在 task 目录
2. transition ledger 的 canonical truth 在 `.harness/tasks/<task-id>/history/transitions/`
3. `.harness/workspace/state/transitions/` 只保留为 legacy fallback 读取面
4. boards 只属于 governance-derived surface，不属于默认 core routing

当前实现常用入口包括：

1. `scripts/work_item_ctl.sh`
2. `scripts/open_current_work_item.sh`
3. `scripts/start_work_item.sh`
4. `scripts/pause_work_item.sh`
5. `scripts/resume_work_item.sh`
6. `scripts/complete_work_item.sh`
7. `scripts/upsert_work_item_progress.sh`

这些是当前实现细节，不应继续决定产品层的用户心智。

## Operator Contracts

凡是进入 code change / code review / workflow implementation 场景，除了 routing 与 state protocol，还应读取：

1. [code_review.md](./code_review.md)
   - 定义跨 agent 的 canonical review contract
2. [agent-operator-contract.md](./agent-operator-contract.md)
   - 定义跨 agent 的 canonical operator contract
3. `docs/workflows/provider-deltas/`
   - 只承载 provider-specific delta，不得复制第二套 operator constitution

## Required Outputs

执行正式治理/研究任务时，至少应考虑是否需要产出：

1. `Research Memo`
2. `Decision Pack`
3. 必要时的 task-scoped artifact writeback
4. 只有显式升级到治理模式时，才追加更重的 governance artifact

## Common Validation

常用校验入口必须按仓库模式区分：

framework source repo：

```bash
./scripts/validate_source_repo.sh
./scripts/audit_role_schema.sh
./scripts/run_governance_surface_diagnostic.sh --mode source
```

materialized task runtime：

```bash
./scripts/validate_workspace.sh --mode core
./scripts/audit_state_system.sh --mode core
./scripts/audit_document_system.sh
./scripts/validate_freshness_gate.sh --staged
./scripts/run_governance_surface_diagnostic.sh --mode consumer
```

advanced governance runtime：

```bash
./scripts/validate_workspace.sh --mode governance
./scripts/audit_state_system.sh --mode governance
./scripts/audit_document_system.sh
./scripts/validate_freshness_gate.sh --staged
./scripts/run_governance_surface_diagnostic.sh --mode consumer
```

## Version Lifecycle

正确做法不是让任务历史永久堆在 active 目录。

正确生命周期是：

1. `active task`
   - 当前 task 保持在 `.harness/tasks/<task-id>/task.md`
2. `active recovery`
   - 若任务仍在执行，用 `.harness/tasks/<task-id>/progress.md` 承担恢复信息
3. `artifact accumulation`
   - task 产物进入 `.harness/tasks/<task-id>/refs/`、`.harness/tasks/<task-id>/outputs/` 与 `closure/`
4. `historical recall`
   - 需要回溯时再去 archive 读旧版本
5. `close and compact`
   - 任务完成后迁入 `.harness/archive/`

## Tool Adapter Boundary

公司 OS 必须是工具中立的。

因此：

1. 公司 OS 的 canonical capability surface 收敛为 `agents + skills`
2. `commands`、`hooks` 只允许作为 provider-specific optional adapters 存在，不得承载唯一真相
3. 工具差异只允许存在于：
   - `.claude/`
   - `.codex/`
   - `.gemini/`
4. `/harness` 是默认产品入口
5. 本文件只承担详细 workflow source
6. 默认体验不依赖根层镜像入口文件保持逐字一致
7. 详细投影规则见 [tool-adapter-capability-map.md](./tool-adapter-capability-map.md)

## Audit Rules

定期检查至少包括：

1. 默认入口是否仍围绕 `/harness`
2. `.harness/current-task` 是否仍指向真实存在的 task 文件
3. 进行中的 task 是否拥有对应的 progress artifact
4. active surface 是否遗留已关闭但未归档的任务
5. 路由文档与最小 runtime contract 是否同步

对应脚本：

1. `./scripts/audit_document_system.sh`

## 禁止事项

1. 不要让新员工默认扫描全仓库 markdown
2. 不要把 advanced governance tree 默认长进最小 runtime
3. 不要把 `.harness/current-task` 写成第二个 source of truth
4. 不要把聊天上下文当成长期 source of truth
