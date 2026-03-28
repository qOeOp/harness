# Volatile Research Default

更新日期：`2026-03-28`

## 目的

规定哪些主题默认必须接入 fresh external sources，而不能只靠内部知识库。

## 默认规则

以下主题默认视为 `volatile-by-default`：

1. 新闻、政策、监管、价格、发行版、事故、服务状态等快速变化事实
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
2. repo 内部路由、权限、文档组织与 runtime contract 讨论
3. 本地目录、权限、worktree、文档组织这类纯仓库内问题
4. 仅对已有内部结论做重写、压缩、归档

但只要结论触碰外部事实，就应升级为 `mixed` 或 `web-verified`。

## 适用范围

`volatile research default` 同时作用于：

1. 上游输入 -> task loop 的入口
2. agent -> agent 的自治讨论
3. role -> role 的 handoff
4. decision pack / research memo / meeting brief 这类正式 artifact

## Internal Route

默认通过 `research dispatch` 路由 external research，而不是依赖某个上游角色的专属 `/command`。

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
4. 不能直接升级成流程变更或需要最终决策人确认的正式决策包

## Topic Owner Mapping

不同类型的 `volatile` 议题，默认由不同 owner 先接网：

1. 工具链能力、adapter、automation、provider 行为
   - 默认 owner：`Workflow & Automation Lead`
2. 社区 best practice、治理方法、compound engineering、多 agent 协作实践
   - 默认 owner：`Compounding Engineering Lead`
3. 产品范围、用户问题、外部业务事实、竞品或项目依赖事实
   - 默认 owner：由 `general-manager` 指派
   - 若重复出现，才考虑创建 runtime-local research role
4. Founder 提供的外部材料、链接、案例或观点
   - 默认 owner：`general-manager`
   - 交由 `Product Thesis Lead` 与 `Knowledge & Memory Lead` 协同 triage

## Freshness Windows

默认窗口：

1. 实时或高频变化事实
   - 需要同日或当轮访问记录
2. 工具能力、社区 best practice、开源仓库动态
   - 默认 14 天内重新核查
3. 官方文档、长期稳定的 evergreen 材料
   - 默认 30 天内重新核查

超过窗口但仍想使用：

1. 必须在 artifact 里明确写出旧来源为何仍可用
2. 或补一次新的 external verification

## Artifact Rule

凡是声称使用外部来源的 artifact，必须：

1. 写 `Verification mode`
2. 写 `Sources reviewed`
3. 至少引用一个 URL、`.harness/tasks/<task-id>/attachments/sources/` 下的 source note，或显式 promote 后的 `.harness/workspace/research/sources/` source note

Source note 必须包含：

1. `Source`
2. `URL`
3. `Type`
4. `Accessed date`
5. `Trust level`
6. `Notes`

默认 artifact routing 见 [task-artifact-routing.md](./task-artifact-routing.md)。

## Hard Truth

这套机制仍然不能数学上证明“搜得足够深、判断一定最优”。

它能做的是：

1. 降低只靠内部记忆闭门讨论的概率
2. 让缺乏外部验证的结论无法伪装成“已验证”
3. 让外部信息进入组织时留下可追溯痕迹
