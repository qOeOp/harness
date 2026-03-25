# Requirements Meeting Brief

- Linked work items: WI-0001


- Date: 2026-03-23
- Host: Chief of Staff
- Vision reference:
  1. .harness/workspace/current/product-vision.md
  2. .harness/workspace/decisions/log/2026-03-23-agent-governance-integration-strategy.md
- Scope for this iteration:
  1. 把前一轮研究里 `P0/P1` 的 agent governance 建议收敛成当前 harness 的 3 个具体改造任务。
  2. 每个任务都必须能挂到现有 `.harness/workspace/state/` 和 state scripts，而不是另起平台。
  3. 本轮只定义 rollout 任务和验收边界，不直接扩张到 product runtime。
- Acceptance criteria:
  1. 已定义 3 个具体任务，每个任务都有 owner、输入、输出、依赖和 done signal。
  2. 任务边界能直接映射到当前 harness，而不是抽象框架迁移。
  3. 至少 1 个任务可以在不引入新 framework 的情况下直接开工。
- Non-goals:
  1. 不把 `LangGraph`、`OpenAI Agents SDK`、`OpenHands` 直接接入公司 OS。
  2. 不引入新的外部 board 作为 source of truth。
  3. 不在当前回合设计完整 runtime session store。
- Dependencies:
  1. scripts/audit_state_system.sh
  2. scripts/lib_state.sh
  3. scripts/transition_work_item.sh
  4. .agents/skills/harness/references/archive/harness/2026-03-23-agent-governance-frontier-and-harness-integration-research-memo.md
  5. .harness/workspace/decisions/log/2026-03-23-agent-governance-integration-strategy.md
- Demo boundary:
  1. 用一个真实或 synthetic work item，演示：
     - progress artifact 的存在与更新
     - approval / interrupt marker 的触发
     - trace taxonomy 在 transition / artifact write 上的落点
- Risks:
  1. 如果任务仍然写成“加强治理”“增强可追溯性”这种口号，执行时会重新发散。
  2. 如果先设计 runtime，再回头补 company OS，会再次把层级混淆。
  3. 如果不给 trace 和 interrupt 定义最小协议，后续 provider-native 能力会继续碎片化。
- Verification date: 2026-03-23
- Verification mode: mixed
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-agent-governance-frontier-source-bundle.md
  2. .agents/skills/harness/references/archive/harness/2026-03-23-agent-governance-frontier-and-harness-integration-research-memo.md
  3. .harness/workspace/decisions/log/2026-03-23-agent-governance-integration-strategy.md
  4. scripts/audit_state_system.sh
  5. scripts/lib_state.sh
  6. scripts/transition_work_item.sh
- What remains unverified:
  1. `progress artifact` 的最终存储路径和格式仍需在实现时封板。
  2. `approval / interrupt` 是放在 work item header、transition event 还是两者都要，需要实现时最后定稿。
  3. `trace taxonomy` 是否只覆盖 state layer，还是要提前兼容未来 runtime traces，尚未最后验证。
- Decisions needed from Founder:
  1. none

## Task Breakdown

| Task | Owner | Why it exists | Concrete output | Dependency | Done signal |
| --- | --- | --- | --- | --- | --- |
| `P0-1 Progress Artifact Protocol v1` | Workflow & Automation Lead | 长运行治理不能继续依赖聊天历史维持连续性 | 一个规范化 progress artifact 模板、约定路径、更新时机、最小字段；并在 1 个 work item 上试跑 | current `.harness/workspace/state/` schema + artifact linking | 能看到一个 work item 在跨回合后仍通过 progress artifact 恢复上下文，而不是靠对话历史 |
| `P0-2 Approval / Interrupt Marker v1` | Workflow & Automation Lead + Risk Office | 现在的 Founder escalation 不足以表达所有受控暂停点 | work item / transition 的最小 interrupt marker 设计，至少区分 `manual-review-required`、`founder-review-required`、`risk-review-required` | transition protocol and board semantics | 一个状态迁移因为 interrupt marker 被合法阻断，并能被后续 resume |
| `P1-1 State Trace Taxonomy v1` | Workflow & Automation Lead | 当前 transition ledger 有事件，但缺统一 trace 分类，后续会越来越难审 | 一套 trace event taxonomy，至少覆盖 `state-transition`、`artifact-link`、`approval-pause`、`resume`、`board-refresh` | existing transition ledger + audit | 审计脚本能验证事件类型属于 allowlist，且至少 1 个 item 的事件链体现该分类 |

## Ordering

1. 先做 `P0-1`。
   - 因为 progress artifact 是跨会话稳定性的最低成本前提。
2. 再做 `P0-2`。
   - 因为没有 interrupt marker，就无法把审批点从口头规则升级成协议。
3. 最后做 `P1-1`。
   - 因为 trace taxonomy 需要对前两个任务的事件类型做归类，否则会返工。

## Stop-The-Line Rule

出现以下任一情况，本 brief 不再继续拆实现，先回到协议层：

1. 任务要求新增外部 framework 才能启动。
2. 任务要求把 GitHub Projects 变成 source of truth。
3. 任务要求改写当前 company semantics，使其依赖单一 provider。
