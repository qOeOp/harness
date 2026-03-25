# Work Item Interrupt Protocol

更新日期：`2026-03-23`

## 目的

把“等待 Founder / Risk / manual review”的暂停点从自由文本 blocker 提升为可审计、可恢复的正式状态协议。

## 核心原则

1. `paused` 是唯一合法的 interrupt 承载状态。
2. `Interrupt marker` 负责表达暂停类型，不复用 `Founder escalation`。
3. `Resume target` 负责表达恢复后回到哪个 stage，不靠聊天上下文猜。
4. pause / resume 都必须写正式 transition event，不能只做 field mutation。
5. `Current blocker` 仍然保留给人读的说明，但不再承担 typed governance 语义。
6. human-facing opener / wrapper 必须继续暴露 `resume_command`，不能把 interrupt metadata 隐没在 blocked candidate 里。

## 最小字段

work item 头部新增两个协议字段：

1. `Interrupt marker`
   - `none`
   - `manual-review-required`
   - `founder-review-required`
   - `risk-review-required`
2. `Resume target`
   - `none`
   - `backlog|framing|planning|ready|in-progress|review`

新协议 transition event 也必须带同名字段，表示该次迁移后的 interrupt snapshot。

## 何时使用

1. 任务需要明确等待人工 review，但还不应进入 `review` / `done`。
2. 任务需要等待 Founder 批示，但不应只靠 `pending-founder` 和自由文本 blocker 表达。
3. 任务需要等待 Risk Office 审查，且恢复后仍要回到原 execution stage。

## 推荐命令

暂停一个 work item：

```bash
./.agents/skills/harness/scripts/pause_work_item.sh \
  --expected-from-status in-progress \
  --expected-version <state-version> \
  --interrupt-marker risk-review-required \
  WI-xxxx \
  "waiting for risk review" \
  "workflow-automation -> risk-office" \
  "pause for risk review"
```

恢复一个 paused work item：

```bash
./.agents/skills/harness/scripts/resume_work_item.sh \
  --expected-version <state-version> \
  WI-xxxx \
  "risk-office -> workflow-automation" \
  "resume after risk review"
```

## 硬规则

1. `paused` item 必须同时拥有非 `none` 的 `Interrupt marker` 和 `Resume target`。
2. 非 `paused` item 必须把 `Interrupt marker` 和 `Resume target` 都清回 `none`。
3. 不允许从 `paused` 直接推进到任意别的 open 状态；只能通过 resume 回到 `Resume target`，或被正式 kill。
4. 若 transition event 是 `To: paused`，event 上也必须带非 `none` 的 interrupt fields。
5. `./.agents/skills/harness/scripts/open_current_work_item.sh`、`./.agents/skills/harness/scripts/start_work_item.sh`、`./.agents/skills/harness/scripts/sweep_state_drift.sh`、`./.agents/skills/harness/scripts/audit_state_system.sh` 都必须理解这套协议。
6. 即使 selector 返回的是 blocked candidate，只要该项处于 `paused`，`open_current_work_item.sh` 也必须展开 `Interrupt marker`、`Resume target` 和 `resume_command`。

## 与 Founder Escalation 的边界

1. `Founder escalation` 表达是否需要 Founder 进入决策权边界。
2. `Interrupt marker` 表达任务当前是否被协议化暂停。
3. 两者可以同时存在，但谁都不替代谁。

## 禁止事项

1. 不要把 `manual-review-required` 写进 `Current blocker` 却不写 `Interrupt marker`。
2. 不要通过 `update_work_item_fields.sh` 手工伪造 pause / resume。
3. 不要让 paused item 没有 `Resume target`。
4. 不要让 resume 依赖“记得之前做到哪了”这种聊天记忆。
