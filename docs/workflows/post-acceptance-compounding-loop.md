# Post-Acceptance Compounding Loop

更新日期：`2026-03-28`

## 目的

把 `任务完成候选 -> 用户验收 -> 复利 review -> runtime role mutation` 收敛成一条正式闭环，避免 role 增长继续靠口头直觉或临时聊天决定。

## Canonical Flow

当前生效的闭环是：

`completion candidate -> acceptance -> compounding review -> role change proposal -> runtime-role-manager execution`

生效规则：

1. “我觉得做完了”不是组织变更的充分条件。
2. role 变更必须先经过用户认可后的 post-acceptance compounding。
3. role file 是跨 provider 的 canonical truth；provider-specific agent 文件只是 user-owned adapter surface。
4. 新增或改写 role 属于高信任写操作，必须先有 reviewable artifact。
5. 决策与执行必须拆开：`Compounding Engineering Lead` 判断是否需要变更，`Runtime Role Manager` 执行实际 role mutation。

## Trigger

触发顺序：

1. 主控 agent 判断任务达到完成标准，提交 `completion candidate`
2. 交付进入用户 / Founder 验收
3. 用户明确认可交付
4. 进入 `post-acceptance compounding review`

说明：

1. 主控 agent 的完成判断只负责声明“可以进入验收”
2. 没有用户认可，就没有 post-acceptance compounding trigger

## Participants

固定参与者：

1. `Compounding Engineering Lead`
2. `Runtime Role Manager`
3. 当前任务实际参与过的 baseline / runtime roles

可按需参与：

1. `general-manager`
2. `Risk & Quality Lead`
3. `Knowledge & Memory Lead`

## Required Artifacts

复利 review 至少要检查：

1. Acceptance artifact
   - `Acceptance Review Brief` 或等价 task-local acceptance 记录
2. 必要时的 `Process Audit`
3. 若发现角色边界问题，则创建 `Role Change Proposal`

默认 task-local 路径：

1. acceptance / closeout 相关材料：`.harness/tasks/<task-id>/closure/`
2. `Role Change Proposal`：`.harness/tasks/<task-id>/closure/<date>-<slug>-role-change-proposal.md`

## Review Questions

`Compounding Engineering Lead` 复盘时至少回答：

1. 现有角色是否覆盖了本轮 heavy work？
2. 是否出现重复 handoff 摩擦，但没有稳定 owner？
3. 是应该新增 role，还是只需修正现有 role 边界？
4. 这个问题是 task-local 偶发事件，还是已具备复用性？

## Allowed Outcomes

复利结论只能落到以下几类：

1. `no-change`
2. `edit-existing-runtime-role`
3. `create-new-runtime-role`
4. `merge-or-retire-runtime-role`

## Mutation Protocol

如果结论涉及 role 变更：

1. 先生成 `Role Change Proposal`
2. 再由 `Runtime Role Manager` 读取 proposal
3. 只允许写入 consumer runtime 的 `.harness/workspace/roles/`
4. 变更后立即跑 role schema audit

当前 canonical 执行入口：

```bash
./scripts/runtime_role_manager.sh --consumer-runtime dogfood --stage post-acceptance-compounding --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md create ...
./scripts/runtime_role_manager.sh --consumer-runtime dogfood --stage post-acceptance-compounding --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md edit ...
./scripts/runtime_role_manager.sh --consumer-runtime dogfood audit
```

当前实现说明：

1. 本仓库已经把 runtime role mutation 收敛到单一脚本入口和单一路径边界。
2. `runtime-role-manager` 的 role frontmatter 现在声明了 `policy_*` schema，wrapper 会检查 `entrypoint / action / artifact / stage / write root`。
3. 但 provider-level 的 per-agent 硬 ACL 目前仍不是 source repo 的既成事实；当前强制面主要是 role policy schema、脚本入口、审计和文档边界。

## Forbidden Shortcuts

1. 不要让主控 agent 直接跳过 acceptance 去长角色。
2. 不要让 `Runtime Role Manager` 自己决定是否需要新增 role。
3. 不要把 provider-specific agent 文件当作 role mutation 的 canonical 输出。
4. 不要把 source repo 的 `roles/` 当成 consumer runtime 组织演化的落点。
