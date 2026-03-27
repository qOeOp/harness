# Volatile Research Default

更新日期：`2026-03-24`

## 目的

规定哪些主题默认必须接入 fresh external sources，而不能只靠内部知识库。

## 默认规则

以下主题默认视为 `volatile-by-default`：

1. 市场、行情、宏观、新闻、监管变化
2. Claude Code / Codex / MCP / hooks / skills / rules / plugins 的最新能力
3. 社区 best practice、开源仓库、博客、近期方法论
4. 任何带有“最近、最新、今天、现在、前沿、best practice、流行”的话题

对这些主题：

1. 默认不能只基于内部文档回答
2. 默认不能只基于模型现有知识回答
3. 默认应当先做 web search / 官方文档检索 / source note 采集

## Internal-only 例外

以下情况允许 `Verification mode: internal-only`：

1. Founder 明确在做 vision lock
2. 公司内部治理结构讨论
3. 本地目录、权限、worktree、文档组织这类纯仓库内问题
4. 仅对已有内部结论做重写、压缩、归档

但只要结论触碰外部事实，就应升级为 `mixed` 或 `web-verified`。

## 工具层落点

## 适用范围

`UserPromptSubmit` 只覆盖 Founder 或人类直接发起的入口。

但公司更常见的运行场景是：

1. 部门内部自己讨论
2. agent 之间互相 review
3. Chief of Staff 主持内部 requirements / decision loop
4. Compounding / Workflow / Learning 围绕外部工具链和社区实践自治优化

因此：

`volatile research default` 必须同时作用于：

1. Founder -> company 的入口
2. agent -> agent 的自治讨论
3. department -> department 的 handoff
4. decision pack / research memo / meeting brief 这类正式 artifact

## Internal Route

公司内部默认通过 `research dispatch` 路由 external research，而不是依赖 Founder `/command`。

见：

- [docs/workflows/internal-research-routing.md](./internal-research-routing.md)
- [docs/templates/research-dispatch.md](../templates/research-dispatch.md)

## 自治 Agent 默认规则

凡是自治讨论触碰 `volatile-by-default` 主题，不允许直接闭门收敛。

必须先做下面 4 件事中的前 2 件，才能进入正式判断：

1. 显式识别这是 `volatile` 议题
2. 指定 `research owner`
3. 生成或刷新 source note
4. 再进入 brainstorming / requirements / decision

如果暂时没有 fresh external sources：

1. 只能输出 `exploratory`
2. 或明确标记 `blocked by freshness`
3. 不能包装成正式结论
4. 不能直接升级成流程变更、策略变更或 Founder-facing 决策包

## Topic Owner Mapping

不同类型的 `volatile` 议题，默认由不同 owner 先接网：

1. 市场、价格、新闻、宏观、监管
   - 默认 owner：`Market Intelligence Department`
2. BTC thesis、setup、多时间框架判断需要的最新市场证据
   - 默认 owner：`Strategy Research Department`
   - 但应优先复用 `Market Intelligence` 的 source notes
3. Claude Code / Codex / MCP / hooks / skills / rules / workflow 的最新能力
   - 默认 owner：`Workflow & Automation Lead`
4. 社区 best practice、vibe coding、compound engineering、多 agent 治理
   - 默认 owner：`Compounding Engineering Lead`
5. Founder 输入的文章、视频、交易思路、外部策略物料
   - 默认 owner：`Learning & Evolution Department`

## Freshness Windows

不是所有外部来源都要求同样的时间敏感度。

默认窗口：

1. 实时市场、价格、新闻、监管
   - 需要同日或当轮访问记录
2. 工具能力、社区 best practice、开源仓库动态
   - 默认 14 天内重新核查
3. 官方文档、长期稳定的 evergreen 材料
   - 默认 30 天内重新核查

超过窗口但仍想使用：

1. 必须在 artifact 里明确写出旧来源为何仍可用
2. 或补一次新的 external verification

### Claude Code

Claude 具备 `UserPromptSubmit`、`SubagentStart` 这类 hooks 能力。

但当前仓库不再把提醒型 hooks 作为 canonical 依赖，而是主要依赖：

1. canonical docs
2. `skills`
3. artifact freshness gate
4. research dispatch / source-note discipline

如果未来重新启用提醒型 hooks，它们也只应被视为 optional adapter，而不是唯一控制面。

### Codex

当前没有和 Claude `UserPromptSubmit` 完全等价的 repo-local prompt hook。

因此 Codex 侧继续依赖：

1. 根级操作规约
2. skills / workflows
3. artifact freshness gate
4. custom agents 自带的 `research-first` 指令

## Artifact Rule

凡是声称使用外部来源的 artifact，必须：

1. 写 `Verification mode`
2. 写 `Sources reviewed`
3. 至少引用一个 URL 或 `.harness/workspace/research/sources/` 下的 source note

Source note 必须包含：

1. `Source`
2. `URL`
3. `Type`
4. `Accessed date`
5. `Trust level`
6. `Notes`

## Hard Truth

这套机制仍然不能数学上证明“搜得足够深、判断一定最优”。

它能做的是：

1. 降低只靠内部记忆闭门讨论的概率
2. 让缺乏外部验证的结论无法伪装成“已验证”
3. 让外部信息进入组织时留下可追溯痕迹
