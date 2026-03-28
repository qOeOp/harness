# Harness Charter

更新日期：`2026-03-28`

## 定位

本仓库当前定义为：

> 一个以 `/harness` 触发的 agent execution substrate：提供 agent-readable repo map、minimal resumable task runtime、deterministic validation/gates + evals、observability/replay，以及清晰的 control surfaces。

## 当前阶段目标

1. 建立默认可用的 `core task runtime`
2. 把 `/harness` 收敛为零安装仪式的主入口
3. 建立跨会话恢复、任务追踪与 artifact writeback 的最小闭环
4. 把验证、审计、approval、policy 和 permission boundary 做实
5. 把组织投影层移出 active canonical surface

## 当前产品方向

当前阶段产品愿景已经收敛到：

1. 第一阶段产品定义为 `invoke-first harness`
2. 第一阶段核心价值不是功能堆叠，而是：
   - `/harness` 立刻可用
   - 任务级别的 problem definition、tracking、resume 与 closure
   - 只有在任务值得持久化时才自动 materialize `.harness/`
   - 低侵入、可删除、可归档的 repo-local truth
   - control surfaces 默认内建，而不是事后补丁

## Founder Operating Model

Founder 当前深度参与的事项只有：

1. vision 定调
2. 关键方向拍板
3. runnable demo 验收
4. 高风险升级审批

Founder 当前不参与：

1. 日常 requirements 拆解
2. 日常实现讨论
3. 普通执行 review
4. 细粒度任务派工

## 当前阶段非目标

1. 不把用户域、行业域的专属角色内置进 framework source repo
2. 不把组织投影层默认压到每个 `/harness` 任务上
3. 不搭全自动高权限 agent orchestra
4. 不在没有清晰 artifact 规范前引入复杂 CI 自动化
5. 不把 provider-owned surface 或分发细节当成产品入口
6. 不在 active source 里保留 company / workstream 叙事作为 canonical model

## 工作守则

1. 一个主题一个 owner
2. 反对意见必须制度化存在
3. 任何决策必须带证据、反证、风险与 tradeoff
4. 没有回写 memory 的口头共识无效
5. 默认先证明任务级价值，再允许 runtime 增长
6. 自动化默认从低风险动作开始，权限逐层放大

## 钢铁纪律

1. 任何 stage 没做到极致，不进入下一 stage
2. AI 的文档和代码产出速度极快，因此速度不是进度指标，稳定度才是
3. 默认先把 task protocol 做锋利，再谈共享写回或本地扩展
4. 执行本身通常只占很小一部分时间；前置问题定义、state hygiene 与 writeback 如果草率，后面只会把错误更快放大
5. 任何“先让 repo 接入，再证明使用价值”的提议，默认视为高风险提议
6. 如果发现当前层基础不稳，必须 `stop-the-line`，回到当前层补强，而不是继续叠下一层

## 当前阶段解释

当前仓库仍处于 `pre-code`。

这意味着：

1. 当前最重要的进度不是开始写业务代码，而是把默认 `/harness` 入口、任务状态模型、恢复协议与 writeback 闭环做稳
2. 共享写回、consumer-local roles 与其他扩展面都不再主导产品叙事
3. 只有当当前 stage 的规则、入口、边界和回写机制已经稳定，才允许进入下一层
4. 任何“看起来推进很快”的动作，如果削弱了阶段稳定性，都会被判定为负进度
