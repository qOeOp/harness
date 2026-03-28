# Internal Research Routing

更新日期：`2026-03-28`

## 目的

把 external research 变成 repo/task 内部路由，而不是某个上游角色的专属入口。

## 适用背景

内部绝大多数 research 需求来自：

1. `general-manager` 的需求拆解
2. role 之间的 handoff
3. 风险审查
4. brainstorming 后的候选想法收敛
5. 工具链和流程控制面优化

因此 research 必须是内部路由，不是 Founder 或其他上游输入的直达执行入口。

## 何时必须先 dispatch

满足任一条件，就必须先创建 `research dispatch`：

1. 主题属于 `volatile-by-default`
2. 讨论要从 brainstorming 升级成 requirements / decision
3. 某个角色需要另一个角色先补最新外部证据
4. 风险或质量门指出“当前证据过时或不足”

## 路由规则

`general-manager` 或当前主持角色负责 dispatch。

dispatch 必须回答：

1. 这是不是 `volatile` 议题
2. 谁是 `research owner`
3. 需要什么类型的外部来源
4. 需要什么时间窗口
5. 交付给谁
6. 交付完成前，下游流程是否 blocked

## 标准产物

dispatch 不是聊天记录，而是一个单独 artifact：

- 默认路径：`.harness/tasks/<task-id>/attachments/<date>-<slug>-research-dispatch.md`
- 只有显式启用共享写回后，才允许 promote 到 `.harness/workspace/research/dispatches/<date>-<slug>.md`
- 模板： [docs/templates/research-dispatch.md](../templates/research-dispatch.md)

默认 artifact routing 见 [task-artifact-routing.md](./task-artifact-routing.md)。

## 路由出口

一个 `research dispatch` 只有 3 种合法结果：

1. `satisfied`
   - 已有 fresh source note / 官方 URL / research memo 足够支撑下游流程
2. `blocked`
   - 当前缺外部信息，不能进入正式判断
3. `not-needed`
   - 经过判断，这其实不是 `volatile` 议题

## 与正式 artifact 的关系

后续 artifact 应尽量回指其 dispatch：

1. `Research Memo`
2. `Decision Pack`
3. `Requirements Meeting Brief`

这样最终决策人和审计者能看到：

1. 这次外部 research 是谁先派发的
2. 是不是先 research 再 decision
3. 哪些结论曾经被 `blocked by freshness`
