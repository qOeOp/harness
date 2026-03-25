# Research Memo

- Date: 2026-03-23
- Owner: Compounding Engineering Lead
- Question: coding-agent-operating-skeleton-patterns
- Scope:
  1. coding-agent 公司操作系统是否已有接近形态
  2. 社区/开源是否已有“角色公司”“repo-local harness”“状态看板系统”三类参考
  3. 我们当前是否在重复造轮子
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-coding-agent-operating-skeleton-patterns.md
- Verification date: 2026-03-23
- Verification mode: web-verified
- Freshness level: volatile
- Sources reviewed:
  1. .harness/workspace/research/sources/2026-03-23-coding-agent-operating-skeleton-patterns.md
  2. https://openai.com/index/harness-engineering/
  3. https://openai.com/business/guides-and-resources/how-openai-uses-codex/
  4. https://www.anthropic.com/engineering/building-effective-agents
  5. https://code.claude.com/docs/en/subagents
  6. https://geminicli.com/docs/core/subagents/
  7. https://github.github.com/gh-aw/introduction/overview/
  8. https://github.github.com/gh-aw/patterns/project-ops/
  9. https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/triaging-an-issue-with-ai
  10. https://docs.openhands.dev/overview/skills/repo
  11. https://docs.openhands.dev/openhands/usage/customization/repository
  12. https://github.com/FoundationAgents/MetaGPT
  13. https://github.com/OpenBMB/ChatDev
  14. https://arxiv.org/abs/2308.00352
  15. https://arxiv.org/abs/2307.07924
- Conflicting sources:
  1. MetaGPT / ChatDev 倾向把“AI 软件公司”角色化、戏剧化
  2. Anthropic / OpenAI / GitHub Agentic Workflows 更强调简单可组合模式、repo-local artifacts、guardrails 和状态化工作流
- Earliest-source check:
  1. “AI software company”这一类公开形态，至少在 2023 年的 ChatDev 与 MetaGPT 论文/仓库中已经明确出现
  2. 2025-2026 的主流演进方向不是继续做纯角色扮演，而是转向 repo-local harness、subagents、safe outputs、project state 与 guardrails
- Strongest evidence:
  1. 你现在的方向不是凭空发明。MetaGPT 明确把自己定义为 “The Multi-Agent Framework: First AI Software Company”，ChatDev 也把 v1 定义为 Virtual Software Company。说明“用多个 agent 模拟软件公司”这条路在开源里早就有人走过。
  2. 但最新高质量实践并不把重点放在“角色越像公司越好”，而是放在可审计控制面。Anthropic 明确说最成功的实现不是依赖复杂框架，而是 simple, composable patterns。OpenAI 在 Harness Engineering 里也强调 humans steer, agents execute，工程师的工作转成设计环境、指定意图、构建 feedback loops。
  3. OpenAI 的新材料已经非常接近你要的核心：repository-local, versioned artifacts 是 system of record；active plans、completed plans、tech debt 要 co-located；严格边界和机械约束是 agent 速度不失控的前提。
  4. Claude、Gemini、OpenHands 都在朝相同方向收敛：subagents / skills / setup hooks / pre-commit / repository agent。说明 repo-local control surface 已经是共识，不是你独有的想法。
  5. GitHub Agentic Workflows 的 ProjectOps、Issue triage 和 workflow structure 给了你现在最缺的一层参考：不是所有状态都靠文档目录表达，而是用 project board / structured fields / safe outputs 管理 work items，然后让 agent 读状态、做低风险变更、把高风险变更升级给人。
- Strongest counter-evidence:
  1. 现有开源里还没有看到一个成熟项目，把 “Claude/Codex/Gemini tool-neutral 公司 OS + repo-local harness + project-state system + department operating model” 真正一体化做好。
  2. MetaGPT / ChatDev 这类“AI 公司”项目对角色组织很强，但通常更像演示框架或研究范式，不足以直接当你的生产骨架。
  3. GitHub Agentic Workflows / OpenHands 更强在 workflow、repo automation、sandbox、safe outputs，但并没有替你完成“部门章程 + Founder operating model + 产品愿景治理”这一层。
- Unknowns:
  1. 目前没有看到一个被广泛验证的“最佳” coding-agent company OS 标准架构
  2. GitHub Agentic Workflows 仍处于早期阶段，适合作为 pattern source，不适合作为直接 production dependency
  3. 你这套系统未来到底更适合用 GitHub Projects、文件化 board，还是二者混合，还需要下一轮内部设计
- Risks:
  1. 如果照搬 MetaGPT / ChatDev，会过度角色扮演，忽视状态系统和控制面
  2. 如果只照搬 OpenHands / Claude / Codex 的 repo-local agent harness，会缺少 company-level operating state
  3. 如果完全自己发明，又会重复社区已经验证过的 repo-local entrypoints、subagents、skills、hooks、project board triage 这些基础轮子
- Recommendation:
  1. 不要把当前方向判断成“纯粹在造轮子”。你在做的不是重复一个现有框架，而是在组合三类成熟形态：
     - `AI software company` 组织想象：借 MetaGPT / ChatDev
     - `repo-local agent harness`：借 OpenAI / Claude / Gemini / OpenHands
     - `stateful work board`：借 GitHub Projects + Agentic Workflows / Issue Triage
  2. 我们真正该补的核心不是更多 md，而是 `Operating State System`。这层在现有开源里没有现成最佳答案，仍然需要我们自己设计。
  3. 最优路径不是继续闭门设计，也不是整体迁移到某个框架，而是明确采用：
     - repo-local control surface
     - tool-neutral semantics with tool-specific adapters
     - work-item-first board layer
     - artifact lifecycle and archive discipline
     - department participation matrix
  4. 结论：你不是在错误地造轮子；你是在缺少 state skeleton 的情况下，已经把上层组织和下层工具适配先搭了出来。下一步不该再发散，而应该专门设计 `Operating State System`，并优先参考 GitHub Projects / Agentic Workflows 的状态字段与 safe output 思想，而不是继续堆角色或文档。
