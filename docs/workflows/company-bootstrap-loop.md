# Company Bootstrap Loop

更新日期：`2026-03-27`

## 目的

定义 `harness` 从默认 PM / governance baseline，到按需启用 consumer runtime workstream 的启动顺序。

## 当前状态

当前重点不是模拟一个完整公司，而是先把默认 `/harness` 入口、task runtime 和治理边界做稳。

## Bootstrap Phases

### Phase 0: Vision Lock

目标：

1. Founder 明确产品愿景。
2. Founder 明确自身参与边界。
3. Founder 明确当前阶段的非目标。

### Phase 1: Governance Baseline Bring-up

目标：

1. 建立默认 PM / governance 团队。
2. 建立 decision rights、memory writeback 和 acceptance gate。
3. 建立最低限度的 skills / scripts / contracts。

完成标准：

1. baseline roles 已存在。
2. decision workflow 已明确。
3. writeback 闭环已明确。
4. Founder-facing review 入口已明确。

### Phase 2: Core Task Runtime Stabilization

目标：

1. 把 `/harness` 入口做成默认可用。
2. 把 task-level scoping、tracking、resume、closure 做稳。
3. 验证 `.harness/` 只在确有需要时 materialize。

完成标准：

1. task runtime 路径稳定。
2. state transition 和 writeback 可恢复。
3. 默认体验不依赖 advanced governance。

### Phase 3: Optional Runtime Workstream Bring-up

目标：

1. 只在重复工作真实出现时，创建 repo-local runtime role。
2. 避免把临时分工误升级成 framework baseline。

规则：

1. 先用 baseline 团队跑多个回合。
2. 只有当输入输出、handoff 和 owner 都稳定后，才 promotion。
3. 新角色必须写到 `.harness/workspace/roles/`。
4. 不允许把 consumer runtime role 回写到 source repo `roles/`。

### Phase 4: Internal Planning Loop

目标：

1. 公司内部自己把 vision 翻译成 requirements。
2. 默认由 baseline 团队组织，而不是先扩组织图。

输出：

1. scoped requirements brief
2. tasking
3. acceptance target

### Phase 5: Implementation Loop

目标：

1. 承接任务并产出 artifact。
2. 通过 review / revise / integrate 收敛交付。
3. 把 runtime role 只当局部执行单元，而不是身份膨胀工具。

### Phase 6: Acceptance & Compounding Loop

目标：

1. 对 runnable slice 做验收。
2. 把反馈写回 task-local artifacts。
3. 在 compounding review 中决定是否需要新的 runtime-local role。
4. 若成立，再由 `Runtime Role Manager` 写入 `.harness/workspace/roles/`。

## 当前真实顺序

当前最合理的顺序不是先长一套行业组织，而是：

1. 稳定默认 `/harness` 入口和 task runtime。
2. 用 baseline 团队完成若干真实回合。
3. 在复利 review 中确认是否存在反复出现的专门职责。
4. 只有证据充分时，再在 `.harness/workspace/roles/` 创建 runtime-local role。
