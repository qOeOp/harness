# Document Routing And Lifecycle

更新日期：`2026-03-25`

## 目的

为新开的 coding agent 提供稳定入口，并把 active truth、active work item 与历史快照分离。

## Current Placement

本文件不再是根层 canonical first hop。

根 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 现在先重定向到：

1. [.harness/entrypoint.md](/Users/vx/WebstormProjects/trading-agent/.harness/entrypoint.md)

本文件当前保留为：

1. 详细 routing / lifecycle workflow source
2. 正在向 `harness` skill source 压缩中的 workflow 正文
3. 旧执行面仍在迁移期间的说明正文

因此：

1. 不要再在三份根入口镜像里分别维护完整宪法
2. 根层 first hop 已经收敛到 `.harness/entrypoint.md`
3. 本文件继续承载详细 routing / lifecycle 规则，直到并入 `harness` skill source
4. 工具差异仍只允许存在于 `.claude/`、`.codex/`、`.gemini/`

## 设计要求

1. 新员工不应该靠扫描全仓库来理解系统
2. 当前生效的 truth 必须有稳定路径
3. 执行中的主对象必须有稳定入口
4. 历史版本必须保留，但不应该继续占据 active 工作区
5. 文档如果没有 owner、入口和生命周期，就只是上下文垃圾

## 当前阶段

- 阶段：`pre-code`
- 目标：先把公司治理、文档路由、记忆分层、`agents + skills` canonical surface 与 rules/scripts 骨架做稳
- 暂不做：业务实现、复杂无人值守自动化、重度多 agent 写代码
- 纪律：当前 stage 没做到极致，不推进下一 stage

## 硬规则

1. 不要默认扫描全仓库 markdown。
2. 任何决定没有 artifact 就视为不存在。
3. 一个问题只能有一个 DRI。
4. `.harness/workspace/current/` 先于历史快照。
5. 一个线程一个 worktree，不共享同一工作目录并行编辑。
6. 公司级 `workspace/` 只允许 append-only 写入，不维护共享总表。
7. Founder-facing demo 必须是独立可运行的垂直切片。
8. 外部 `volatile` 主题必须带验证日期、来源和 `Verification mode`。
9. 工具差异只能存在于 `.claude/`、`.codex/`、`.gemini/`，公司 OS 语义必须一致。
10. 如果当前层基础不稳，必须 `stop-the-line`，不要为了推进进度继续叠下一层。

## Routing Order

任何新开的 coding agent，都不应直接扫全仓库。

正确顺序是：

1. `.harness/entrypoint.md`
   - 先确认 hosted-kernel first hop 与当前 runtime root
2. 本文件
   - 再理解详细 stage、硬规则、入口与生命周期
   - 先理解如何找 active truth，而不是先看历史
3. `.harness/workspace/current/`
   - 先读当前生效的 Founder 锁定信息
4. `.harness/workspace/state/boards/`
   - 公司级协同、排期、执行任务先读 `.harness/workspace/state/boards/company.md`
   - Founder 验收、升级、拍板任务先读 `.harness/workspace/state/boards/founder.md`
5. `.harness/workspace/state/items/WI-xxxx.md`
   - 统一入口优先运行 `./.agents/skills/harness/scripts/work_item_ctl.sh <select|open|start|complete> ...`
   - 人工执行通常运行 `./.agents/skills/harness/scripts/work_item_ctl.sh open company`、`./.agents/skills/harness/scripts/work_item_ctl.sh open founder` 或 `./.agents/skills/harness/scripts/work_item_ctl.sh open department <slug>`
   - 若要原子接单并记录进入执行的 event，运行 `./.agents/skills/harness/scripts/work_item_ctl.sh start <scope>`
   - 若要受控暂停执行中的事项，运行 `./.agents/skills/harness/scripts/work_item_ctl.sh pause --expected-from-status ... --expected-version ... --interrupt-marker ... WI-xxxx`
   - 若要恢复已暂停事项，运行 `./.agents/skills/harness/scripts/work_item_ctl.sh resume --expected-version ... WI-xxxx`
   - 若要原子收口，运行 `./.agents/skills/harness/scripts/work_item_ctl.sh complete --target-status review|done|killed <scope>`
   - 若当前事项已在 `in-progress`，同时检查 `.harness/workspace/state/progress/WI-xxxx.md`；若缺失、未链接或过期，先用 `./.agents/skills/harness/scripts/upsert_work_item_progress.sh` 刷新恢复信息
   - 若当前事项处于 `paused`，同时检查 `Interrupt marker`、`Resume target`，并优先使用 `./.agents/skills/harness/scripts/resume_work_item.sh` 恢复，不要手工改字段
   - 若由 automation / agent 消费，优先运行 `./.agents/skills/harness/scripts/select_work_item.sh --json ...`
   - 若 selector 返回 `WI-xxxx`，再进入该 item 作为运行态 source of truth
   - 若 selector 返回 no actionable item，则回看 board 识别 blocked / waiting-founder / waiting-handoff
6. 按任务类型进入对应规则层
   - 公司治理任务：`docs/organization/`、`docs/workflows/`
   - 产品方向任务：`.harness/workspace/current/product-vision.md`
   - 部门任务：对应 `.harness/workspace/departments/<department>/README.md`、`AGENTS.md / CLAUDE.md / GEMINI.md`、`charter.md`、`interfaces.md`
   - code change / code review 任务：先读 [code_review.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/code_review.md)，再读 [agent-operator-contract.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/agent-operator-contract.md)
7. 只在需要时读取历史快照
   - `.harness/workspace/archive/`
   - `.agents/skills/harness/references/archive/harness/`
   - `.harness/workspace/decisions/log/`
   - `.harness/workspace/status/snapshots/`

## Operating State Entry

当仓库已经启用 operating state system 时：

1. 根入口必须先把 agent 路由到 board，再由 board 路由到具体 work item。
2. `.harness/workspace/state/items/` 是运行态 source of truth，board 只是派生视图。
3. `./.agents/skills/harness/scripts/work_item_ctl.sh` 是统一控制面，只负责路由子命令，不复制状态机逻辑。
4. `./.agents/skills/harness/scripts/select_work_item.sh` 是 canonical selector，负责从 board 语义里选出首个 actionable work item，并提供 machine-readable `--json` 输出。
5. `./.agents/skills/harness/scripts/open_current_work_item.sh` 是 human-facing opener，负责把 selector 结果展开成当前执行 handoff packet。
6. `./.agents/skills/harness/scripts/start_work_item.sh` 是 atomic starter，负责把 `ready` 项推进到 `in-progress` 并写入正式 transition event。
7. `./.agents/skills/harness/scripts/complete_work_item.sh` 是默认 atomic closer，要求显式 `--target-status review|done|killed`；其中 `done / killed` 会下沉到 `./.agents/skills/harness/scripts/finalize_work_item.sh`，避免把送审和终结混成隐式动作。
8. 长回合恢复协议见 [work-item-progress-protocol.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/work-item-progress-protocol.md)。
9. 受控暂停 / 恢复协议见 [work-item-interrupt-protocol.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/work-item-interrupt-protocol.md)。
10. canonical root entry 不应直接硬编码某个长期有效的 `WI-xxxx`，避免入口与运行态漂移。

## Operator Contracts

凡是进入 code change / code review / workflow implementation 场景，除了 routing 与 state protocol，还应读取：

1. [code_review.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/code_review.md)
   - 定义跨 agent 的 canonical review contract
2. [agent-operator-contract.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/agent-operator-contract.md)
   - 定义跨 agent 的 canonical operator contract
3. `docs/workflows/provider-deltas/`
   - 只承载 provider-specific delta，不得复制第二套 operator constitution

## Required Outputs

执行正式治理/研究任务时，至少应考虑是否需要产出：

1. `Research Memo`
2. `Decision Pack`
3. 必要时的 `Decision Log Entry`
4. 必要时的 `Status Snapshot`

## Common Validation

常用校验入口：

```bash
./.agents/skills/harness/scripts/validate_workspace.sh
./.agents/skills/harness/scripts/audit_document_system.sh
./.agents/skills/harness/scripts/audit_tool_parity.sh
./.agents/skills/harness/scripts/validate_freshness_gate.sh --staged
```

## Version Lifecycle

正确做法不是让 `v1-v60` 永久堆在 active 目录。

正确生命周期是：

1. `in-flight draft`
   - 放在 `.harness/workspace/briefs/`
2. `founder-locked snapshot`
   - 产品 / repo-local runtime 对象迁入 `.harness/workspace/archive/`
   - harness framework 推导正文迁入 `.agents/skills/harness/references/archive/harness/`
   - 若 append-only artifact 仍引用旧路径，原路径只保留 redirect stub，不再保留完整正文
3. `current canonical pointer`
   - 在 `.harness/workspace/current/` 更新为最新稳定路径
4. `historical recall`
   - 需要回溯时再去 archive 读旧版本

## Stable Entry Rules

对于 Founder 已拍板的主题：

1. 必须有一个稳定的 current 文件
2. current 文件负责回答：
   - 现在生效的是什么
   - 指向哪份历史快照
   - supersede 了什么
   - 哪些问题仍未解决
3. current 文件的头部必须保持单行、可解析，至少包含 `Status`、`Last updated`、`Active snapshot`、`Supersedes`

当前要求至少存在：

1. `.harness/workspace/current/product-vision.md`

## Tool Adapter Parity

公司 OS 必须是工具中立的。

因此：

1. 根层 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 必须保持同义，并都只承担 redirect stub 语义
2. 部门层也采用同样镜像规则
3. 公司 OS 的 canonical capability surface 收敛为 `agents + skills`
4. `commands`、`hooks` 只允许作为 provider-specific optional adapters 存在，不得承载唯一真相
5. 工具差异只允许存在于：
   - `.claude/`
   - `.codex/`
   - `.gemini/`
6. canonical root first hop 由 `.harness/entrypoint.md` 承担
7. 本文件只承担详细 workflow source，不再承担根入口 first hop
8. 入口文件不负责承载工具专属细节
9. 详细投影规则见 [tool-adapter-capability-map.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/workflows/tool-adapter-capability-map.md)

检查脚本：

1. `./.agents/skills/harness/scripts/sync_tool_entrypoints.sh`
2. `./.agents/skills/harness/scripts/audit_tool_parity.sh`

## Audit Rules

定期检查至少包括：

1. 新员工入口是否仍然明确
2. `.harness/workspace/current/` 是否仍指向真实存在的快照
3. `.harness/workspace/briefs/` 是否出现 `v1-vN` 污染
4. active 目录中是否遗留 superseded 版本
5. 若旧路径仍被历史 artifact 引用，`.harness/workspace/briefs/` 中是否只留下短 redirect stub，而不是继续保留完整正文
6. 路由文档与目录结构是否同步

对应脚本：

1. `./.agents/skills/harness/scripts/audit_document_system.sh`
2. `./.agents/skills/harness/scripts/audit_tool_parity.sh`

## 禁止事项

1. 不要让新员工默认扫描全仓库 markdown
2. 不要把历史版本长期留在 `.harness/workspace/briefs/`
3. 不要让 `.harness/workspace/current/` 里出现版本号文件名
4. 不要把聊天上下文当成长期 source of truth
