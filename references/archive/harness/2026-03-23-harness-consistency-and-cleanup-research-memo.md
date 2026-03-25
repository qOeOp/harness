# Research Memo

- Date: 2026-03-23
- Owner: Workflow & Automation Lead
- Question: harness-consistency-and-cleanup
- Scope:
  1. OpenAI / Anthropic / GitHub / Kubernetes / Stripe 这些高信号实践如何处理 agent harness 的状态一致性、持续清扫和可恢复性
  2. 把这些模式翻译到当前 `Operating State System v1`
  3. 明确哪些对象应该被强约束，哪些对象只能接受派生一致性
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-harness-consistency-and-cleanup.md
- Linked work item: WI-0001
- Verification date: 2026-03-23
- Verification mode: mixed
- Freshness level: volatile
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-harness-consistency-and-cleanup-source-bundle.md
  2. .harness/workspace/state/README.md
  3. .harness/workspace/state/items/WI-0001.md
  4. .harness/workspace/decisions/log/2026-03-23-operating-state-system-v1-scope.md
  5. https://openai.com/index/harness-engineering/
  6. https://openai.com/index/unrolling-the-codex-agent-loop/
  7. https://openai.com/index/unlocking-the-codex-harness/
  8. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
  9. https://www.anthropic.com/research/building-effective-agents/
  10. https://github.github.com/gh-aw/patterns/project-ops/
  11. https://github.github.com/gh-aw/reference/compilation-process/
  12. https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/
  13. https://kubernetes.io/docs/concepts/architecture/garbage-collection/
  14. https://docs.stripe.com/api/idempotent_requests
  15. https://docs.stripe.com/api/request_ids
- Conflicting sources:
  1. OpenAI 倾向于更重的 repo-local protocol、长寿命状态原语和持续 GC；Anthropic 明确提醒不要先上复杂 framework，而要先用 simple, composable patterns。
  2. GitHub ProjectOps 更偏向外部 project board + safe outputs；当前仓库已锁定 `local-first, work-item-first, board-derived`，不能直接把外部板当本体。
  3. Kubernetes 的 controller / GC 模式本质是受控收敛与最终一致，不是全局锁；如果把它误读成“所有视图必须同步原子更新”，会把 harness 设计过重。
- Earliest-source check:
  1. 2017，Stripe 已把 `idempotency key + request id` 作为安全重试和追踪的基础模式。
  2. 2024，Anthropic 已明确提出：workflow 与 agent 要区分，默认从 simple, composable patterns 出发，而不是复杂框架。
  3. 2026，OpenAI 连续公开了 harness engineering、App Server、Codex agent loop 的状态原语、服务端持久线程与 compaction/一致排序实践。
- Strongest evidence:
  1. OpenAI App Server 把 `item / turn / thread` 定义为具有明确生命周期的状态原语，线程放在服务端持久化，并支持 reconnect、resume、fork、archive。长运行 harness 的状态本体不能放在易失 prompt 或客户端会话里。
  2. OpenAI 在 agent loop 中刻意保持新 prompt 的 exact prefix，并对 tool order、sandbox config、cwd 做稳定处理，因为乱序和中途改写会直接导致 cache miss 与行为漂移。这说明协议稳定性本身就是一致性设计的一部分，而不是单纯性能优化。
  3. OpenAI 已把熵增视为工程垃圾回收问题：通过 golden principles、持续清扫任务、linters/CI 和专门的 doc-gardening agent 维持 repo legibility。没有清扫机制的 harness 会自然发散。
  4. Anthropic 的 long-running harness 实践表明，稳定性来自 initializer agent + coding agent 分工、`progress` file、结构化 JSON feature list、会话结束时恢复 clean state，而不是继续把更多历史直接塞回 prompt。
  5. GitHub ProjectOps 通过 safe outputs、字段 allowlist、single-select exact values、读写 token 分离来控制状态漂移。先读结构化状态，再做受控写入，是 agentic workflow 可运维的前提。
  6. Kubernetes 的 finalizers、owner references、garbage collection 说明删除不是“马上删”，而是先进入受控终结态，完成依赖清理后再解除 finalizer。这是 work item / artifact / blocker 清扫的直接模板。
  7. Stripe 的 idempotent requests 和 request IDs 说明：所有可能被 retry 的状态迁移都必须带稳定 `operation identity`，否则 retry 会制造重复副作用并破坏可追踪性。
- Strongest counter-evidence:
  1. 当前仓库仍处于 `pre-code`。如果直接照搬 OpenAI 的重型 repo-local harness，会把 `WI-0001` 推向平台工程，而不是把 state skeleton 收稳。
  2. 如果把“强一致性”理解成“每个派生视图都要实时原子同步”，会和 local-first 文件系统现实冲突，导致不必要的锁、补偿和恢复复杂度。
  3. Anthropic 对复杂 framework 的警告仍然成立。为了一致性再造一层抽象平台，本身就是另一种发散。
  4. 当前 `.harness/workspace/state/items/*.md` 仍是自由文本 Markdown。如果继续让 agent 直接改写自由文本，再谈强一致性就是自我安慰。
- Unknowns:
  1. `work item file` 应升级为 `schema-locked markdown frontmatter`，还是 `json sidecar + md narrative`。
  2. `transition_work_item.sh` 应优先采用 `expected_version/hash` 还是 git-based compare-and-swap 作为并发保护。
  3. `GC cadence` 的默认周期和阈值：多久扫 stale item、多久升级 paused、多久要求 compaction/archival。
  4. v1 是否需要 `tombstone / deleting` 终结态，还是先只支持 `killed / archived / superseded`。
- Risks:
  1. 如果继续允许人工直接编辑 board 或 item 的任意字段，会立刻出现双重 source of truth。
  2. 如果没有 idempotent transition protocol，同一 agent retry / hook / automation 重复执行会写出重复状态和重复 artifact link。
  3. 如果没有 finalizer-style cleanup，work item 结束后会遗留 orphaned artifacts、stale boards、dangling blockers。
  4. 如果没有 GC cadence，append-only memory 与 current state 会一起变厚，最后 agent 看到的是大量历史，而不是最小有效 truth。
  5. 如果继续用 Markdown prose 承担 mutable control plane，agent 迟早会把解释性文本误写成状态。
- Recommendation:
  1. 不要把目标定义成“全局绝对强一致”。对当前 harness，正确目标是：
     `single mutable state authority + idempotent transitions + deterministic derived views + finalizer-style cleanup + recurring garbage collection`
  2. 继续保持 `.harness/workspace/state/items/` 为本体，但把每个 item 升级为 `schema-locked state doc`：
     - 顶部结构化 header 只允许脚本写入
     - 底部 `summary / notes` 才允许人工自由文本
     - board 永远只由 `refresh_boards.sh` 派生
  3. 每次状态迁移必须通过脚本完成，并带：
     - `operation_id`
     - `expected_from_status`
     - `expected_version`
     - `actor`
     - `timestamp`
     - `request_id` 或 `session_id`（若可得）
  4. 为 item 增加 `version` / `generation` 与最小 transition log；若 precondition 不满足就 fail fast，而不是静默覆盖。
  5. 为 `killed / archived / superseded` 增加 finalizer-like 流程：
     - linked artifacts resolved
     - dependent items unblocked or repointed
     - founder / company / department boards refreshed
     - stale blocker cleared
     - then mark terminal
  6. 把清扫分成三类 controller：
     - `invariant audit`: 每次变更后检查 schema、双向链接、枚举值、board freshness
     - `drift sweep`: 定时扫描 stale item、invalid blockers、orphaned artifacts、manual board edits
     - `context compaction`: 定时压缩 superseded/current/archive 路由、progress notes、session summaries
  7. 对 Founder 的硬挑战：
     - 如果继续让可变状态停留在自由文本 Markdown 里，然后希望“靠规则保持强一致”，这条路不够好，必须收窄成结构化状态协议。
  8. v1 最小落地顺序：
     - 先实现 structured item header + transition preconditions
     - 再实现 audit + refresh
     - 再实现 cleanup/finalizer
     - 最后才讨论外部 board sync

## Divergent Hypotheses

1. `Document discipline only`
   - 继续靠更多规则、更多 README、更多 audit 口头约束来控制发散，不引入更硬的状态协议。
2. `Heavy coordinator now`
   - 立刻上数据库、全局锁、外部 orchestrator，把当前仓库 state layer 升级为中心化运行时。
3. `Local state protocol`
   - 保持 `local-first`，但把 `work item` 收窄成 schema-locked state doc，只允许 script-only transitions，并补上清扫 controller。

## First Principles Deconstruction

1. 派生视图可以重建，本体状态才值得被强约束。
2. retry 是常态，不是异常；因此每次状态迁移都必须可去重、可追踪。
3. 删除不是瞬时动作，而是依赖清理流程。
4. 历史必须 append-only，但当前 truth 必须薄、稳、可直接读取。
5. 任何需要“靠记忆和口头解释维持”的一致性，都不是真正的一致性。

## Convergence To Excellence

采纳第 3 条路线：

1. 不继续幻想“更多文档 = 更多一致性”。
2. 也不在 `pre-code` 阶段上重型中心协调器。
3. 直接把 `Operating State System v1` 升级成一个最小但足够硬的状态协议：
   - 单一本体
   - 幂等转移
   - 派生视图
   - 终结清扫
   - 周期性 GC
