# Research Memo

- Date: 2026-03-23
- Owner: Compounding Engineering Lead
- Question: harness-gap-and-architecture-reassessment
- Scope:
  1. 客观评定当前仓库的 harness engineering 系统与公开最佳实践的差距
  2. 区分哪些是当前阶段合理缺失，哪些是根层错位
  3. 识别哪些问题可以修，哪些问题需要推翻现有设计假设
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-harness-gap-and-architecture-reassessment.md
- Linked work items: WI-0001
- Verification date: 2026-03-23
- Verification mode: mixed
- Freshness level: volatile
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-harness-gap-and-architecture-source-bundle.md
  2. README.md
  3. docs/organization/org-chart.md
  4. docs/workflows/decision-workflow.md
  5. .harness/workspace/state/README.md
  6. scripts/lib_state.sh
  7. scripts/transition_work_item.sh
  8. scripts/audit_state_system.sh
  9. https://openai.com/index/harness-engineering/
  10. https://openai.com/index/unrolling-the-codex-agent-loop/
  11. https://openai.com/index/unlocking-the-codex-harness/
  12. https://www.anthropic.com/engineering/building-effective-agents
  13. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
  14. https://github.github.com/gh-aw/patterns/project-ops/
  15. https://github.github.com/gh-aw/reference/compilation-process/
  16. https://code.claude.com/docs/en/hooks
  17. https://code.claude.com/docs/en/sub-agents
  18. https://geminicli.com/docs/core/subagents/
  19. https://docs.openhands.dev/openhands/usage/customization/repository
  20. https://docs.openhands.dev/overview/skills/org
- Conflicting sources:
  1. OpenAI 展示的是高投入、强 repo-local、强反馈闭环的 agent-first 工程体系；Anthropic 明确警告不要先上复杂框架，而要先用简单可组合模式。
  2. GitHub ProjectOps 以结构化字段和 safe outputs 作为控制面；当前仓库选择 `local-first` 文件本体，这本身不矛盾，但要求你们本地状态协议必须更硬。
  3. 当前仓库把 `company OS` 与 `product runtime` 分开是对的，但公开最佳实践里真正被机械强化的核心对象是 `thread / turn / item / field contract / verification loop`，不是“部门”和“会议”。
- Earliest-source check:
  1. 2024-12-19，Anthropic 已明确提出：最成功的 agent 系统通常依赖简单、可组合模式，而不是复杂框架。
  2. 2026-02-11，OpenAI 公开把 repo-local knowledge、agent legibility、cleanup、feedback loop 视为 harness engineering 的核心。
  3. 2026 年公开文档已清楚收敛：repo-local customization 是趋势，但真正的控制力来自结构化状态与可执行验证，而不是更多角色 prose。
- Strongest evidence:
  1. 当前仓库做对的一面是真实存在的。根入口、工具适配层、最低限度 hooks / rules / scripts、tool parity audit、freshness gate，都符合公开实践里“repo-local control surface”的方向。
  2. 当前仓库最强的不是 runtime harness，而是 `governance shell`。以公开文件计，当前大约有 45 份 `docs/*.md`、22 个 agent 定义、24 个 skill、24 个脚本，但只有 4 个 work item。本体状态面相对治理表面明显偏薄。
  3. 公开最佳实践并不把“角色系统”当作 harness 核心。OpenAI 的核心原语是可持久化的 `thread / turn / item` 与可恢复事件流；GitHub ProjectOps 的核心原语是结构化字段、受控写入、读写权限分离；Anthropic long-running harness 的核心原语是 `feature list`、`progress notes`、`init.sh`、基础测试回路。
  4. 当前仓库真正接近前沿的位置，是把 `AGENTS.md` 当路由入口而不是百科全书，把 knowledge 分层，把 board 视图做成派生物。这些方向是对的。
  5. 当前仓库真正落后的位置，不是“还没有更多 agent”，而是没有一个可执行、可恢复、可自证的验证回路。公开最佳实践里的 harness 都在不断把真实执行环境、状态原语和验证信号接入 agent，而当前仓库仍主要验证文档与状态格式。
  6. 当前状态层虽然已经起步，但仍是 shell 对 Markdown 行文本的解析与替换。它有枚举校验和 board 派生，但没有版本号、幂等迁移标识、并发保护、finalizer、session progress artifact，也没有把可变控制面从自由文本彻底收窄出来。
- Strongest counter-evidence:
  1. 当前仓库处于 `pre-code`，没有产品代码和真实 runtime，因此缺少 UI / logs / metrics / tests 并不自动等于方向错误。
  2. 仓库已经显式声明 `Company OS / Product Runtime / Data Layer` 分层，这比很多公开仓库更清醒，说明你们并非完全误解问题。
  3. 对当前阶段而言，严格控制自动化边界、限制 destructive 命令、把 volatile research 变成默认规则，这些都不是过度工程，而是必要护栏。
- Unknowns:
  1. 当产品 runtime 最小切片出现后，当前“公司组织隐喻”还需要保留多少，还是应该大幅退化成更薄的治理 overlay。
  2. `.harness/workspace/state/items/*.md` 最优形态究竟是 frontmatter 锁定、sidecar JSON，还是迁入更强结构化载体。
  3. 当前 harness 的 ROI 指标应如何定义，例如任务往返回合数、返工率、人工纠偏时间、stale rule 比率、状态漂移率。
- Risks:
  1. 如果继续扩张“管理层 / 部门 / 会议 / 流程”表面，而没有同步收紧 `task / state / evidence / verification` 四个核心对象，当前系统会从治理 bootstrap 滑向治理拟像。
  2. 如果继续把可变状态寄存在 shell 可编辑的 Markdown bullet 里，再宣称自己拥有长期稳定 harness，这个判断并不诚实。
  3. 如果把 Anthropic 的“保持简单”误读为“继续停留在自由文本规则”，会错失真正该结构化的控制面。
  4. 如果把 OpenAI 的 repo-local harness 误读为“多写文档、多写角色”，会在错误层面堆投资，最后得到的是厚重语义表层，而不是强执行骨架。
- Recommendation:
  1. 重新命名当前系统。它更准确的定位不是“已经形成的 harness engineering 系统”，而是“治理优先的 repo harness bootstrap”。这个判断很重要，因为它决定后续投入是否继续堆在错误层。
  2. 立即停止继续扩张组织隐喻层，除非新增内容直接强化 `task routing`、`state transition`、`evidence linkage`、`verification loop` 四个对象之一。
  3. 把当前 top-level architecture 从“公司角色系统”降级为人类可读叙事层，把真正的 harness 核心提升为四个机器友好原语：`task`、`state`、`artifact/evidence`、`verification`.
  4. 不要自研 vendor runtime loop。继续借 OpenAI / Claude / Gemini / OpenHands 这类已有 substrate，但把 repo 内控制面做硬，尤其是 state protocol 和验证闭环。
  5. 下一阶段的唯一正确升级，不是再补部门，不是再补会议，而是把一条最小 runnable slice 接进来，让 agent 能完成“读取任务 -> 执行 -> 自证 -> 回写”的闭环。没有这条闭环，当前系统再精致也仍是治理 OS，而不是 best-in-class harness。

## Divergent Hypotheses

1. `Current direction is basically right`
   - 继续在现有 company OS 上补状态、补脚本、补会议闭环，认为这就是 best practice 的本地化版本。
2. `The whole thing is mostly wrong`
   - 认为“AI 公司”隐喻本身就是错的，应该直接删掉大部分治理表面，退回极简 task runner。
3. `Layer split is right, center of gravity is wrong`
   - 承认 repo-local governance shell 有价值，但认为你们把太多预算花在组织叙事层，而没有把控制面和验证面做成真正的一等公民。

## First Principles Deconstruction

1. Harness 的目的不是“让系统看起来像一个组织”，而是让 agent 在真实任务上更稳定、更可控、更可恢复。
2. 可复利的不是角色 prose，而是结构化状态、受控写入、明确反馈回路和可复现验证。
3. 人类能靠隐喻理解系统，agent 更依赖稳定原语和可执行环境。
4. 如果一个控制面无法机械校验、无法安全重试、无法恢复，它就还不是成熟 harness。
5. 在 `pre-code` 阶段，治理 bootstrap 是合理的；但一旦治理表面的增长速度长期快于状态与验证层，它就会从“脚手架”变成“替代品”。

## Convergence To Excellence

最稳妥、也最不自欺的收敛是第 3 条：

1. 当前分层意识不是错的，`repo-local` 方向也不是错的。
2. 真正的问题是控制重心错了。你们把太多清晰度投资在“谁像谁、谁汇报谁、开什么会”，而不是“什么是状态本体、怎么迁移、怎么自证、怎么恢复”。
3. 因此不该做的是继续微调现有叙事壳；该做的是把公司隐喻退位，让 `task/state/evidence/verification` 变成新核心。
