# Frontier Practices 2026

调研日期：`2026-03-22`

## 研究范围

- OpenAI Codex / Codex CLI / AGENTS.md / custom agents / skills / rules / review / non-interactive workflows
- Claude Code / CLAUDE.md / skills / subagents / hooks / settings / agent teams
- 高信号社区实践：跨工具仓库结构、battle-tested settings、上下文分层

## Divergent Hypotheses

1. 一个超长总提示词就足够。
2. 先做复杂 memory 和 orchestration，后面再补治理。
3. 先建立分层操作系统：constitution、rules、skills、subagents、hooks、canonical docs，再逐步扩大自动化。

## First Principles Deconstruction

- 上下文是稀缺资源，不应该把所有规则常驻在一个大 prompt 里。
- “必须发生”的约束不该只依赖模型自觉，应尽量落到 hooks、rules、权限边界和模板。
- 空项目最先需要的是治理可复现、文档可审计、记忆可追溯，而不是复杂多 agent 编排。
- 并行 agent 只在任务独立、边界清晰、文件隔离时有效。

## Convergence

我们采纳第 3 条路线。

### 现在就采用

1. 根级宪法文件：`CLAUDE.md` 与 `AGENTS.md`
2. 项目级 subagents
3. 项目级 skills
4. 最小 hooks
5. Codex `.rules`
6. 决策模板与 writeback 机制
7. Git 作为并行与审计底座

### 暂缓采用

1. 复杂 agent teams
2. 高权限无人值守写操作
3. 复杂动态上下文注入
4. 过早的 CI 自动实现
5. 过度依赖“智能 memory bank”而忽视 canonical docs

## 采用策略摘要

### Codex

- 用 [AGENTS.md 指南](https://developers.openai.com/codex/guides/agents-md) 的分层 instruction 模式管理长期规范。
- 用 [Subagents](https://developers.openai.com/codex/subagents) 的 project-scoped `.codex/agents/*.toml` 管理窄而强的角色。
- 用 [Skills](https://developers.openai.com/codex/skills) 的 `.agents/skills/` 管理可复用工作剧本。
- 用 [Rules](https://developers.openai.com/codex/rules) 管理低层 exec policy。
- 用 [Configuration Reference](https://developers.openai.com/codex/config-reference) 里的 `.codex/config.toml` 管理项目级 agent 深度与线程数。

### Claude Code

- 根 `CLAUDE.md` 保持宪法级简洁。
- 用 [skills / slash commands](https://code.claude.com/docs/en/slash-commands) 管理重复工作流。
- 用 [subagents](https://code.claude.com/docs/en/sub-agents) 管理项目级角色。
- 用 [hooks](https://code.claude.com/docs/en/hooks) 处理必须执行的低层约束。
- 用 [settings](https://code.claude.com/docs/en/settings) 管理 permissions deny 与项目级 hook 入口。
- Agent teams 只作为后续升级项，不作为当前基线。

### 社区信号

- 高信号社区仓库开始同时维护 `AGENTS.md`、`CLAUDE.md`、`.claude/`、`.codex/`，例如 [fcakyon/claude-codex-settings](https://github.com/fcakyon/claude-codex-settings)。
- 社区共识是：根文件要短、技能要窄、hooks 要克制、memory 要分层。
- 2026-03-09 Anthropic 发布了基于 agent teams 的 review 能力，但更适合后期成熟代码库，不适合当前阶段。

## 项目级结论

这个仓库现在不需要“更强的智能体”，而需要“更强的制度化上下文”。
