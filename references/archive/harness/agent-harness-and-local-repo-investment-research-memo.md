# Research Memo

- Date: 2026-03-23
- Owner: Compounding Engineering Lead
- Question: agent-harness-and-local-repo-investment
- Scope:
  1. `agent harness` 现在在官方高信号语境里到底指什么
  2. 当前主流实践把哪些能力放进 repo-local control surface
  3. 结合本仓库现状，哪些 local repo 投入是合理基建，哪些开始偏离产品
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-agent-harness-and-local-repo-investment.md
- Verification date: 2026-03-23
- Verification mode: mixed
- Freshness level: volatile
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-agent-harness-source-bundle.md
  2. AGENTS.md
  3. docs/research/frontier-practices-2026.md
  4. docs/workflows/worktree-parallelism.md
  5. .agents/skills/harness/references/archive/harness/company-harness-map.md
  6. .agents/skills/harness/references/archive/harness/2026-03-23-coding-agent-operating-skeleton-research-memo.md
  7. https://openai.com/index/harness-engineering/
  8. https://openai.com/index/unrolling-the-codex-agent-loop/
  9. https://www.anthropic.com/engineering/building-effective-agents
  10. https://code.claude.com/docs/en/sub-agents
  11. https://code.claude.com/docs/en/hooks
  12. https://geminicli.com/docs/core/subagents/
  13. https://github.github.com/gh-aw/introduction/overview/
  14. https://github.github.com/gh-aw/patterns/project-ops/
  15. https://docs.openhands.dev/openhands/usage/customization/repository
  16. https://docs.openhands.dev/overview/skills/org
- Conflicting sources:
  1. Anthropic 明确反对一上来堆复杂框架，强调 simple, composable patterns；OpenAI 则展示了一个高度 repo-local、强约束、重文档与重反馈回路的百万行 agent-generated 系统。
  2. GitHub Agentic Workflows 强调 project board + safe outputs + field contract；当前仓库更偏文档与 artifact，work-item 状态层仍然缺位。
  3. Meta-level 组织/角色想象可以帮助心智建模，但最新高信号实践的重心已经从“像公司一样扮演”转向“像系统一样可控、可审计、可恢复”。
- Earliest-source check:
  1. 2024-12-19，Anthropic 已经公开把“复杂 framework 不是默认答案”讲清楚，并区分了 workflow 与 agents。
  2. 2026-01-23，OpenAI 开始把 `Codex harness` 明确命名为 core agent loop + execution logic。
  3. 2026-02-11，OpenAI 进一步把 `harness engineering` 上升为一套 agent-first 软件工程方法：repo-local system of record、短入口、强边界、反馈回路、机械校验。
- Strongest evidence:
  1. `agent harness` 不是“角色设定文件集合”。OpenAI 对 `Codex harness` 的定义是 core agent loop 和 execution logic，也就是 prompt assembly、tool invocation、sandbox / permissions、plan management、thread state、tool-result feedback 这些使模型真正能工作的控制逻辑。
  2. 在 coding-agent 场景里，harness 的第二层是 `repo-local control surface`。OpenAI 明确指出，agent 看不到的知识就等于不存在；因此 `AGENTS.md` 应该是目录，不是百科全书，真正的 system of record 要进入 repo 中可版本化、可校验、可交叉引用的 artifacts。
  3. 这条路线不是 OpenAI 独有。Claude Code 官方把 project-scoped subagents 放在 `.claude/agents/`，Gemini CLI 把 project-level custom agents 放在 `.gemini/agents/`，OpenHands 把 repo customization 放进 `.openhands/`，并提供 skills、setup script、pre-commit script。主流收敛点很一致：agent 的长期工作方式越来越 repo-local。
  4. `repo-local` 不是只写 markdown。OpenAI 的高杠杆实践包括 per-worktree bootable app、本地可查询的日志/指标/trace、repository-embedded skills、agent 可直接运行标准开发工具。也就是说，真正好的 harness 会让 agent 能验证自己的改动，而不是只能写文档。
  5. 本仓库内部 `company-harness-map` 的判断与外部趋势一致：`Entry`、`Policy`、`Tools` 已经有骨架，最薄的是 `State`。这说明你们现在的主要矛盾不是“有没有 harness”，而是“harness 缺少 work-item / board / state machine 这层主骨架”。
  6. GitHub Agentic Workflows 给了一个很关键的补完：agent 不应该只靠 repo 文档理解系统，还应该读取结构化 work-item state，并通过 safe outputs 进行受控写入。对实际组织运行来说，这比继续扩写角色文档更接近生产控制面。
- Strongest counter-evidence:
  1. `harness` 现在很火，但不是一个充分标准化的术语。若不先定义清楚团队内部语义，很容易把 runtime loop、repo memory、workflow orchestration、project board 全部混成一个词。
  2. Anthropic 的核心警告仍然成立：很多团队会因为 agent 概念热而过早抽象、过早框架化。复杂 scaffolding 可能遮蔽真实 prompt/tool 问题，也可能诱导团队逃避真实产品约束。
  3. OpenAI 的重型 harness 是在“空 repo 起步、百万行代码、内部真实用户、0 行手写代码、高吞吐 PR”这个极端条件下长出来的。直接照搬到当前 pre-code 阶段，会高估你们现在对复杂 harness 的必要性。
  4. 仅靠 local repo 文档体系，并不能自动形成有效 product loop。如果没有 work item、状态迁移、验证标准和最小 runnable slice，repo 只会越来越整洁，但不一定越来越接近产品。
- Unknowns:
  1. 对本仓库最优的 `Operating State System v1` 究竟应该是纯文件化、GitHub Projects 驱动，还是 hybrid 结构。
  2. 在进入产品构建阶段之前，最小可验证的“agent harness ROI 指标”该如何定义，例如任务吞吐、回合数、返工率、artifact freshness 违规率。
  3. 当前阶段是否需要先做一个 internal runnable harness demo，还是直接等到产品 runtime 最小切片出现再验证。
- Risks:
  1. 如果继续扩写角色、部门、会议体裁，却不补 work-item state，会形成治理表演，不能形成真正的 agent operating system。
  2. 如果开始自己造 runtime harness，而不是借 Codex / Claude / Gemini / OpenHands 的现成 substrate，会把时间烧在最不该重写的一层。
  3. 如果把 “local repo 很重要” 误读成 “所有知识都先写成 md”，会忽略 agent 最终需要的是可执行验证回路，而不是更厚的静态说明书。
  4. 如果没有明确 stop rule，pre-code 阶段会无限延长，local repo 建设会从必要基建滑向产品前拖延。
- Recommendation:
  1. 不要再把 `agent harness` 当成一个模糊热词使用。内部统一定义为三层：
     - `Runtime Harness`: agent loop、tools、sandbox、permissions、review / retry loop。这层直接借官方工具，不自己造。
     - `Repo Harness`: AGENTS/CLAUDE/GEMINI entrypoints、技能、hooks、scripts、worktree discipline、versioned artifacts。这层你们已经基本到位。
     - `Operating State Harness`: work items、board、状态机、department participation、asset linkage、safe transition rules。这层正是当前最大缺口。
  2. 对你们来说，继续投入 local repo 是对的，但只在一个前提下成立：每一项投入都必须让未来 agent 更容易理解、执行、验证、审计某个真实任务。凡是不直接提高这四件事的 repo 工程，都应该停。
  3. 当前最优方向不是继续补更多角色说明、也不是开始自己造 agent runtime，而是只做 `Operating State System v1`。这是现有 repo 从“治理文档系统”跨到“可运转 harness”的必要门槛。
  4. 具体 stop rule：
     - 停止新增泛化角色/部门/会议文档，除非它直接服务于 work-item routing。
     - 停止讨论抽象的 multi-agent company 叙事，除非它能落到字段、状态、脚手架或校验器。
     - 暂不自研 runtime harness，不重写 agent loop，不自造复杂 orchestration。
  5. 结论：你们现在不是“不该花时间构建 local repo”，而是“已经花够了第一段时间，接下来只能继续补 state skeleton，不能再无边界扩写 repo 表层”。再往前多走一步就会开始偏离产品。

## Divergent Hypotheses

1. 继续加厚 local repo，把更多规则、角色、会议与部门结构写进仓库，认为 harness 会自然变强。
2. 停止 repo 投入，直接进入产品实现，默认官方 agent 自己会解决上下文、协作和审计问题。
3. 把 harness 重新拆层，借 runtime、稳住 repo、只补 state，并用最小可验证任务回路来约束后续投入。

## First Principles Deconstruction

1. agent 只能基于当轮可见上下文行动；看不见的约束等于不存在。
2. 上下文是稀缺资源；一个巨型总提示词不是资产，而是噪音。
3. 可靠性来自可执行边界、状态与验证，不来自角色 prose。
4. 预先建设 local repo 只有在它减少未来任务熵增时才有价值；否则只是把不确定性延后包装。
5. 没有 work-item state 的系统无法复利，因为任务无法被一致地进入、转移、审查、关闭。

## Convergence To Excellence

最稳、最强、也最务实的收敛方案是第 3 条：

1. 借现成 runtime harness，不自己重造 agent substrate。
2. 保留当前 repo harness，但不给它继续无限膨胀的许可。
3. 把剩余 pre-code 预算集中投入 `Operating State System v1`，让 repo 从“文档可读”升级为“任务可控”。
