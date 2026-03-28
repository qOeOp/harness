# Frontier Practices 2026

调研日期：`2026-03-22`

## 研究范围

- OpenAI Codex / Codex CLI / AGENTS.md / custom agents / skills / rules / review / non-interactive workflows
- Claude Code / CLAUDE.md / skills / subagents / hooks / settings / agent teams
- 高信号社区实践：跨工具仓库结构、battle-tested settings、上下文分层

## Repo Alignment Note

这份文档记录的是 external frontier patterns，
不直接定义当前 `harness` source repo 的 canonical entry。

当前 source repo 的 first hop 是：

1. `README.md`
2. `SKILL.md`
3. `references/`
4. `docs/workflows/`

而 `AGENTS.md / CLAUDE.md / .codex/ / .claude/ / .gemini/`
只属于 consumer repo 的 provider-owned adapter surface，
不是这个 source repo 的默认产品入口。

## Divergent Hypotheses

1. 一个超长总提示词就足够。
2. 先做复杂 memory 和 orchestration，后面再补治理。
3. 先建立 provider-neutral control surfaces：短入口、capability bundles、canonical docs、验证边界与按需 adapter，再逐步扩大自动化。

## First Principles Deconstruction

- 上下文是稀缺资源，不应该把所有规则常驻在一个大 prompt 里。
- “必须发生”的约束不该只依赖模型自觉，应尽量落到 hooks、rules、权限边界和模板。
- 空项目最先需要的是治理可复现、文档可审计、记忆可追溯，而不是复杂多 agent 编排。
- 并行 agent 只在任务独立、边界清晰、文件隔离时有效。

## Convergence

我们采纳第 3 条路线。

### 现在就采用

1. `README.md` + `SKILL.md` + canonical references 作为 source repo 入口
2. `skills/*` capability bundles 与 `roles/*` routing baseline
3. scripts / contracts / audits 作为默认 enforcement boundary
4. task-local writeback、recovery 与 verification loops
5. provider-owned adapter surface 只在 consumer repo 按需出现
6. Git 作为并行与审计底座

### 暂缓采用

1. 复杂 agent teams
2. 高权限无人值守写操作
3. 复杂动态上下文注入
4. 过早的 CI 自动实现
5. 过度依赖“智能 memory bank”而忽视 canonical docs
6. 在 source repo 里生成 provider-specific mirrors
7. 把 remote / marketplace / user-supplied skill
   直接当成默认可信基线

## 采用策略摘要

### Codex

- [AGENTS.md 指南](https://developers.openai.com/codex/guides/agents-md)、[Subagents](https://developers.openai.com/codex/subagents)、[Skills](https://developers.openai.com/codex/skills)、[Rules](https://developers.openai.com/codex/rules) 与 [Configuration Reference](https://developers.openai.com/codex/config-reference)
  主要用于理解 Codex 的 provider adapter 能力边界。
- 对当前 `harness` source repo，
  canonical first hop 仍是 `README.md`、`SKILL.md`
  与 canonical references，
  不是 `AGENTS.md` 或 `.codex/`
- 若某个 consumer repo 选择接入 Codex adapter，
  其 `AGENTS.md`、`.codex/config.toml`
  与 `.codex/agents/`
  应保持 user-owned / project-owned，
  不回写成 source repo 的 canonical surface
- capability bundle 的 canonical source
  仍是本仓库的 `skills/*`，
  而不是 provider-managed mirror

### Claude Code

- [skills / slash commands](https://code.claude.com/docs/en/slash-commands)、[subagents](https://code.claude.com/docs/en/sub-agents)、[hooks](https://code.claude.com/docs/en/hooks) 与 [settings](https://code.claude.com/docs/en/settings)
  主要用于理解 Claude 的 adapter 设计空间。
- `CLAUDE.md` 与 `.claude/*`
  若存在，也应属于 consumer repo 的 provider-owned surface，
  不是本 source repo 的默认入口
- hooks / settings 的启发应该下沉到 scripts、
  contracts 与 audit，而不是在本仓库复制一套 provider mirror
- Agent teams 只作为后续升级项，不作为当前基线。

### 社区信号

- 高信号社区仓库经常同时维护 `AGENTS.md`、`CLAUDE.md`、`.claude/`、`.codex/`，例如 [fcakyon/claude-codex-settings](https://github.com/fcakyon/claude-codex-settings)；
  这说明 consumer repo adapter surface 很常见，
  但不等于 framework source repo
  也应把它们升格为 canonical entry
- 社区共识是：根文件要短、技能要窄、hooks 要克制、memory 要分层。
- remote / marketplace / user-supplied skill
  默认要先经过 curate / review / version pin，
  才适合进入 executable catalog
- 2026-03-09 Anthropic 发布了基于 agent teams 的 review 能力，但更适合后期成熟代码库，不适合当前阶段。

## 项目级结论

这个仓库现在不需要“更多 provider mirror”或“更强的智能体表演”，
而需要更强的 provider-neutral institutional context、
更窄的 canonical entry、
更硬的 verification / control surfaces。
