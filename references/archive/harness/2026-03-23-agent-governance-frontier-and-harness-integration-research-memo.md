# Research Memo

- Linked work items: WI-0001

- Date: 2026-03-23
- Owner: Compounding Engineering Lead
- Question: agent-governance-frontier-and-harness-integration
- Scope:
  1. 调查 agent governance 的前沿治理原语，而不是只看“谁更火”。
  2. 对比高 star 项目和当前 `trading-agent` repo harness 的分层能力。
  3. 判断哪些能力适合 `integrate now`、`pilot later`、`observe only`、`reject as backbone`。
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-agent-governance-frontier-and-harness-integration.md
- Verification date: 2026-03-23
- Verification mode: mixed
- Freshness level: volatile
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-agent-governance-frontier-source-bundle.md
  2. .harness/workspace/state/README.md
  3. .harness/workspace/state/items/WI-0001.md
  4. .agents/skills/harness/references/archive/harness/company-harness-map.md
  5. scripts/lib_state.sh
  6. scripts/new_work_item.sh
  7. scripts/transition_work_item.sh
  8. scripts/refresh_boards.sh
  9. scripts/audit_state_system.sh
  10. scripts/github_projects_sync_adapter.sh
  11. https://openai.com/index/harness-engineering/
  12. https://openai.com/index/unlocking-the-codex-harness/
  13. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
  14. https://docs.langchain.com/oss/python/langgraph/durable-execution
  15. https://docs.langchain.com/oss/python/langgraph/interrupts
  16. https://openai.github.io/openai-agents-python/guardrails/
  17. https://openai.github.io/openai-agents-python/human_in_the_loop/
  18. https://github.com/openai/codex
  19. https://github.com/OpenHands/OpenHands
  20. https://github.com/microsoft/autogen
  21. https://github.com/langchain-ai/langgraph
  22. https://github.com/crewAIInc/crewAI
  23. https://github.com/FoundationAgents/MetaGPT
  24. https://github.com/Significant-Gravitas/AutoGPT
  25. https://github.com/openai/openai-agents-python
- Conflicting sources:
  1. OpenAI 倾向于更硬的 repo-local system of record、长生命周期线程原语和 approval-aware harness；Anthropic 明确警告不要先堆复杂框架，而要先把 harness 做成 simple, composable patterns。
  2. LangGraph / OpenAI Agents SDK 强在 runtime state、interrupt、guardrails、tracing；MetaGPT / CrewAI 强在 role packaging 和 workflow narration。前者更接近治理原语，后者更接近组织叙事。
  3. GitHub stars 是 adoption signal，不是 governance fitness signal。`AutoGPT` 的超高 star 并不等于它最适合做当前仓库的主骨架。
- Earliest-source check:
  1. 2024，MetaGPT 把 “AI software company” 作为多 agent 框架主叙事，证明“角色公司化”很有传播力，但不等于硬治理。
  2. 2025，Anthropic 把 long-running harness 的核心收敛到 initializer、progress file、structured feature list、clean state。
  3. 2025-2026，LangGraph 与 OpenAI Agents SDK 明确把 `durable execution / sessions / guardrails / human-in-the-loop / tracing` 上升为 runtime primitives。
  4. 2026，OpenAI 把 harness engineering、Codex harness lifecycle 和 approval pause/resume 公开化，强调 repo-local truth、worktree、本地可验证和受控中断。
- Strongest evidence:
  1. OpenAI 的最新公开实践说明，优秀 harness 不是“多几个角色”，而是 `repo as system of record + worktree-local execution + explicit lifecycle + feedback loops + cleanup discipline`。
  2. Anthropic 的 long-running harness 经验说明，跨长会话稳定性的关键不是塞更多历史，而是 `initializer agent + progress file + structured plan + clean exit state`。
  3. LangGraph 的 `durable execution` 与 `interrupts` 给出了开源领域里最清晰的 runtime 治理原语：checkpoint、resume、thread-scoped state、human edit points。
  4. OpenAI Agents SDK 把 `guardrails`、`human-in-the-loop`、`sessions`、`tracing` 做成一等公民，适合未来产品 runtime 的受控实验。
  5. 当前仓库已经不只是文档系统。它已经具备：
     - `.harness/workspace/state/items/*.md` 作为运行态本体
     - `boards/` 作为派生视图
     - `transitions/` 作为 append-only ledger
     - `audit_state_system.sh` 作为机械校验
     - `github_projects_sync_adapter.sh` 作为外部板适配层
     - `.codex/agents/*.toml` 作为角色级 sandbox / capability boundary
- Strongest counter-evidence:
  1. 当前阶段仍是 `pre-code`。如果现在把某个外部 framework 升格成主骨架，代价不是“更先进”，而是把当前问题从治理收敛变成平台迁移。
  2. 我们的核心问题不是缺一个“多 agent 框架”，而是需要维持 `tool-neutral company semantics + local-first state + append-only memory + worktree isolation`。这四者没有一个外部项目能直接替代。
  3. `MetaGPT / CrewAI` 这类 role-heavy 框架与本仓库最像的恰恰是表面叙事，而不是底层治理。直接引入会放大“像公司”的错觉，而不是强化可审计控制面。
  4. 当前 repo harness 的最大缺口不在 `Entry` 或 `Policy`，也不在“缺少更多 agent”，而在：
     - provider-neutral approval / interrupt abstraction
     - runtime tracing / replay
     - long-running progress artifact convention
     - state export / sync 边界的进一步硬化
- Unknowns:
  1. 产品 runtime 真正开始后，应优先 pilot `LangGraph` 还是 `OpenAI Agents SDK`。
  2. 是否需要一个 provider-neutral `approval required / interrupt required` 协议层，而不是只依赖各家原生 pause 语义。
  3. GitHub Projects 未来应保持 `export-only`，还是进入受控双向同步。
  4. `progress artifact` 最优形态应是 `progress.md`、`progress.json` 还是 work item 子节。
- Risks:
  1. 如果把 popularity 当成主筛选器，会选到 narrative 强但 governance 弱的项目。
  2. 如果同时引入多个 framework，会把当前清晰的 repo harness 打碎成 layered abstractions。
  3. 如果过早把 runtime framework 绑到 company OS，本仓库会失去 tool-neutral 特性，并把 Claude/Codex/Gemini 入口语义撕裂。
  4. 如果完全拒绝外部原语，又会错过 durable execution、guardrails、interrupts、tracing 这些真正高价值的治理积木。
- Recommendation:
  1. 不引入任何单个外部项目作为 `company governance OS` 主骨架。
  2. 保持当前 repo harness 为 authoritative backbone，继续拥有：
     `company semantics + local-first state + append-only memory + worktree-first discipline`
  3. 只选择性吸收 5 类治理原语：
     - `structured progress artifact`
     - `explicit interrupt / approval points`
     - `runtime sessions / durable resume`
     - `guardrails / tracing`
     - `export-only external board sync`
  4. `LangGraph` 和 `OpenAI Agents SDK` 进入 `pilot later`，仅用于未来产品 runtime 或 isolated experiments，不进入公司 OS 主骨架。
  5. `MetaGPT / CrewAI / AutoGPT` 不进入当前工程主骨架；最多保留为 narrative / benchmark / anti-pattern 参考。

## Current Harness Baseline

| Layer | Current repo status | Strength | Current gap |
| --- | --- | --- | --- |
| `Entry` | `AGENTS.md / CLAUDE.md / GEMINI.md` + routing docs | 工具中立、入口短、current/archive 清晰 | 还没有更统一的 approval/interrupt 入口 |
| `Policy` | org chart / decision rights / decision workflow | 语义清楚，Founder/CoS/部门权限边界明确 | 还未把所有治理约束都沉到机械协议 |
| `State` | `.harness/workspace/state/items + boards + transitions` | 已有单一本体、派生视图、hash-linked ledger | 更像 company OS state，不是 runtime session state |
| `Tools` | state scripts + audit + GitHub sync adapter + `.codex/agents` | 本地可执行、可审计、有角色级 sandbox boundary | runtime tracing / replay 还弱 |
| `Feedback` | audit + decision logs + snapshots | 已有闭环意识，不是纯 md 叙事 | 还缺更强的 run-level observability |

## Frontier Research Matrix

| Frontier source | Core governance primitive | What is best-in-class here | Literal-copy risk | What we should borrow |
| --- | --- | --- | --- | --- |
| `OpenAI Harness Engineering` | repo-local truth, worktree-local execution, cleanup discipline | 把 harness 定义成控制面，不是角色设定 | 直接照搬会高估我们当前对重型 repo protocol 的需求 | `repo as truth`、worktree discipline、持续清扫 |
| `OpenAI Codex harness / approval lifecycle` | explicit item-turn-thread lifecycle, pause/resume on approval | 中断、恢复、审批点都进入协议层 | 当前 company OS 不是服务端 runtime，不能硬套 thread API | 明确的 interrupt / approval state machine |
| `Anthropic long-running harnesses` | initializer + progress file + clean session exit | 用最小结构跨长会话保持稳定 | 如果照抄 app-dev artifact，会把治理层和实现层混掉 | `progress artifact` 和 clean-state discipline |
| `LangGraph durable execution + interrupts` | checkpoint, resume, thread-scoped state, human edit point | 开源 runtime 治理原语最完整 | 更适合 product runtime，不适合作为公司 OS 主骨架 | runtime pilot 的首选 shape |
| `OpenAI Agents SDK guardrails / HITL` | tripwires, sessions, tracing, handoffs | guardrails 和 tracing 非常适合受控实验 | Python/runtime 导向明显，不是 repo governance | runtime safety primitives 和 tracing taxonomy |

## High-Star Project Matrix

| Project | Stars on 2026-03-23 | Governance locus | Strengths | Weaknesses | Fit to `trading-agent` harness | Integration verdict |
| --- | ---: | --- | --- | --- | --- | --- |
| `openai/codex` | 66954 | runtime harness + repo-native coding loop | 真正贴近 repo-local coding；approval-aware；对 worktree / instructions / tools 很友好 | provider/runtime 耦合，不给 company semantics | 高 | `Integrate now` at operator/runtime level; 不 vendor，不当公司 OS |
| `OpenHands/OpenHands` | 69573 | coding-agent platform + SDK/CLI/GUI | CLI/GUI/SDK 三层齐全；cloud/enterprise 有 RBAC/permissions；benchmark culture 强 | licensing 混合；更像完整平台；公司语义仍需自建 | 中 | `Observe / isolated pilot`，不做主骨架 |
| `microsoft/autogen` | 56044 | multi-agent runtime framework | event-driven agents、MCP、local/distributed runtime、bench/studio 生态完整 | 当前官方已引导新用户看 Agent Framework；framework gravity 重 | 中低 | `Borrow concepts only`，不引入核心依赖 |
| `langchain-ai/langgraph` | 27191 | stateful orchestration runtime | durable execution、interrupt、memory、thread scope 很强 | 需要自己定义上层语义；不是 repo governance | 高于 runtime，低于 company OS | `Pilot later` for product runtime |
| `crewAIInc/crewAI` | 46908 | role-based crews + event flows + control plane | Flows/Crews 拆分清晰；事件流表述不错；控制平面叙事完整 | 角色叙事偏重；容易与我们自有 company semantics 冲突 | 低 | `Do not integrate as backbone` |
| `FoundationAgents/MetaGPT` | 65827 | AI software company metaphor | SOP / artifact-first 思路有启发；研究影响力强 | 过度公司化类比；与本仓库 `No Analogies` 纪律冲突 | 低 | `Reference only` |
| `Significant-Gravitas/AutoGPT` | 182729 | agent platform + builder + benchmark | 市场认知度最高；agent protocol / benchmark 值得观察 | stars 明显大于治理适配度；平台范围过宽；许可混合 | 低 | `Reject as backbone` |
| `openai/openai-agents-python` | 20199 | multi-agent workflow SDK | guardrails、sessions、HITL、tracing、handoffs 都是硬治理原语 | Python/runtime 层，不解决 repo/company semantics | 中高 | `Pilot later` for runtime, not governance backbone |

## Divergent Hypotheses

1. `Framework replacement`
   - 直接选一个高 star 框架当主骨架，替换当前 repo harness。
2. `Popularity portfolio`
   - 同时引入多个高 star 项目，各借一点，慢慢堆成系统。
3. `Governance kernel`
   - 保持当前 repo harness 为主骨架，只吸收经过验证的治理原语，并把 runtime pilot 与 company OS 明确分层。

## First Principles Deconstruction

1. 我们真正要治理的是：
   - 状态
   - 权限边界
   - 审批/中断点
   - 可追溯性
   - worktree 并行安全
2. `company governance OS` 与 `product runtime` 不是一个对象。
3. 本仓库当前阶段是 `pre-code`，所以最优解不是“最强平台”，而是“最小但足够硬的控制面”。
4. tool-neutral 是硬约束。任何只在单一 provider 里成立的主骨架，都不能直接成为公司 OS。
5. 高 star 只能说明“很多人围观/使用”，不能说明“最适合当前层级和约束”。

## Convergence To Excellence

采纳第 3 条路线，也就是 `Governance kernel`：

1. `Current repo harness` 继续做主骨架。
2. `Codex / Claude / Gemini` 继续做 provider-native operator layer。
3. `LangGraph / OpenAI Agents SDK` 留给未来 runtime spike，不碰当前 company OS source of truth。
4. `GitHub Projects` 只做派生同步目标，不做本体。
5. `MetaGPT / CrewAI / AutoGPT` 不作为主集成对象，避免把叙事感和真实治理能力混淆。

## Concrete Integration Ladder

| Priority | What to add | Why this is the right next step | Source inspiration |
| --- | --- | --- | --- |
| `P0` | `progress artifact` convention for long-running work items | 让跨会话连续性不再依赖聊天历史 | Anthropic |
| `P0` | explicit `approval required / interrupt required` markers in work item flow | 把中断与审批从口头规则升级成协议字段 | OpenAI Codex harness |
| `P1` | richer tracing taxonomy for state transitions and artifact writes | 当前有 transition ledger，但 run-level trace 仍弱 | OpenAI Agents SDK / LangGraph |
| `P1` | keep GitHub board sync strictly export-only | 防止外部板反客为主 | current adapter + frontier board patterns |
| `P2` | isolated runtime spike in `LangGraph` or `OpenAI Agents SDK` | 为未来产品 runtime 预埋 durable execution 能力 | LangGraph / OpenAI Agents SDK |
