# Harness V2 Boundary

- Linked work items: WI-0001

- Date: 2026-03-23
- Owner: Chief of Staff
- Status: active-working-brief
- Purpose:
  把当前仓库从“组织叙事驱动”收窄到“核心控制面驱动”，明确接下来什么可以做，什么不应该继续做。

## Divergent Hypotheses

1. 继续以 `company OS` 作为主架构，只在其上补更多状态脚本。
2. 直接删掉大部分治理表面，退回一个极简 task runner。
3. 保留必要治理壳，但把主架构重心切到四个机器友好原语。

## First Principles Deconstruction

1. agent 真正需要的是稳定任务对象、稳定状态、可追溯证据和可执行验证。
2. 人类喜欢用组织隐喻理解系统，但 agent 不会因为“角色更完整”就自动更稳定。
3. 任何不能提高任务可控性、恢复性或自证能力的治理表面，都不该继续扩张。

## Convergence

采纳第 3 条路线。

当前 `Harness v2` 只承认 4 个一等公民原语：

1. `Task`
   - Source of truth: `.harness/workspace/state/items/`
   - 目标：明确 owner、状态、依赖、交付边界
2. `State`
   - Source of truth: 结构化 work item 协议与 transition/event 协议
   - 目标：迁移可校验、可重试、可恢复、可清扫
3. `Evidence`
   - Source of truth: `.harness/workspace/research/sources/`、`.harness/workspace/research/dispatches/`、linked artifacts
   - 目标：所有关键判断都能回指来源与验证日期
4. `Verification`
   - Source of truth: 可执行检查、最小 runnable slice、审计脚本、必要时的 progress artifact
   - 目标：agent 不是“自称完成”，而是“完成并自证”

## Allowed Expansion

只有满足以下任一条件的新增内容，才允许继续进入仓库：

1. 让 `task` 更容易被读取、分派、切换或关闭
2. 让 `state` 更不容易漂移、更容易恢复
3. 让 `evidence` 更新鲜、更可追溯、更不容易伪装
4. 让 `verification` 更接近真实执行与真实自证

## Frozen Surface

在下一条最小 runnable validation loop 出现前，默认冻结：

1. 新部门定义
2. 新会议分类
3. 角色进一步戏剧化细分
4. 不能直接强化四个核心原语的治理 workflow prose

## Required Next Moves

1. 为 `work item` 增加更强结构化状态边界
2. 为长回合任务增加 progress / recovery artifact
3. 设计一条最小 runnable validation slice
4. 审计现有治理表面，标记保留 / 冻结 / 归档候选
