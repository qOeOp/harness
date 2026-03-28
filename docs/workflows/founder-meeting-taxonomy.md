# Founder Meeting Taxonomy

更新日期：`2026-03-24`

## 目的

区分 Founder 与公司之间不同类型会议的路由目标、默认主持人与升级边界。

## 会议类型

Founder 与公司之间当前存在 5 类正式会议：

1. `Governance Meeting`
2. `Vision Meeting`
3. `Acceptance Review`
4. `Requirements Meeting`
5. `Brainstorming Session`

## 会议总览

| 会议类型 | 默认主持 | Founder 默认在场 | 触发问题 | Canonical output / workflow |
| --- | --- | --- | --- | --- |
| `governance` | `Compounding Engineering Lead` | 是 | 公司现在运行得怎样，哪些流程和协作该改 | governance brief、minutes、improvement directions；详见 `founder-governance-meeting-loop.md` |
| `vision` | `Product Thesis Lead` | 是 | 我们到底在做什么，边界和非目标是否要变 | vision brief、thesis changes、Founder decision |
| `acceptance` | `Chief of Staff` | 是 | 当前 demo 是否达到 Founder 验收门槛 | acceptance decision、Founder feedback、follow-up directions |
| `requirements` | `Chief of Staff` | 默认否 | 已批准 vision 在当前阶段该翻译成哪些需求 | scoped requirements brief、acceptance criteria、workstream tasking |
| `brainstorming` | 视主题而定 | 可选 | 还不拍板，只发散候选方向与实验 | candidate ideas、hypotheses、candidate experiments |

## Routing Boundaries

### `governance`

适用：

1. 公司运行状态
2. 跨 workstream 摩擦
3. ritual、hook、rule、workflow 的调整
4. 需要 Founder 拍板的治理问题

不适用：

1. 改产品愿景
2. 验收 demo
3. 日常 requirements 拆解

详细流程见：

- [docs/workflows/founder-governance-meeting-loop.md](./founder-governance-meeting-loop.md)

### `vision`

适用：

1. 产品定义、北极星、边界、非目标
2. Founder 直觉与研究结论之间的收敛
3. 阶段性产品方向变更

### `acceptance`

适用：

1. runnable demo 验收
2. Founder 对当前切片做 go / rework / pause 判断

### `requirements`

适用：

1. 把已批准 vision 翻译成阶段需求
2. 收敛范围、验收标准、demo 边界

关键边界：

1. 默认是内部会议，不默认需要 Founder 在场。
2. 只有当讨论触碰已批准 vision 边界时，才升级给 Founder。
3. Founder 通常只看 requirements 的结果，不看拆解过程。

### `brainstorming`

适用：

1. 还不拍板的探索
2. 候选切口、问题方向、组织改进方案发散

关键边界：

1. brainstorming 不是决策。
2. 输出只能进入候选池。
3. 若要进入正式执行，必须回到 research / review / decision 流程。

## Router Rule

canonical meeting router 是 `meeting-router` skill。

推荐默认类型：

1. 如果主题是“公司现在运行得怎么样”，默认 `governance`
2. 如果主题是“我们这个产品到底要做什么”，默认 `vision`
3. 如果主题是“这版 demo 能不能给 Founder 验收”，默认 `acceptance`
4. 如果主题是“这一版该做哪些功能”，默认 `requirements`
5. 如果主题是“先发散看看”，默认 `brainstorming`

若主题同时覆盖多个类型，优先级如下：

1. `vision`
2. `acceptance`
3. `governance`
4. `requirements`
5. `brainstorming`

这条优先级用于避免一个 `meeting-router` 输出同时混入“改愿景”和“做治理复盘”。

## Freshness Gate

不是所有 meeting 都需要先做 web search，但凡涉及以下 `volatile` 主题，就不能只靠现有记忆达成正式结论。

该规则适用于：

1. Founder-facing meeting
2. workstream 内部讨论
3. agent-to-agent brainstorming
4. internal requirements / review / decision session

凡是正式结论，不区分是不是 Founder 在场。

涉及以下 `volatile` 主题时，都必须遵守同样的 freshness discipline：

1. 外部快变事实，例如新闻、监管、服务状态、定价或实时数据
2. Claude Code / Codex / MCP / tools 的最新能力
3. 社区 best practice、开源仓库、博客里最近流行的方法
4. 法规、规则、产品定价、版本能力这类明显会变化的信息

这类 meeting 必须遵守：

1. 在形成正式结论前，先做 freshness check
2. 输出中必须标明：
   - `Verification date`
   - `Verification mode`
   - `Sources reviewed`
   - `What remains unverified`
3. 如果只是 brainstorming，可以先发散，但所有外部事实性主张都必须打上 `needs freshness check`
4. 没过 freshness gate 的外部判断，不能直接升级为正式决策或流程变更

`Verification mode` 只允许三种值：

1. `internal-only`
   - 只基于 Founder 输入、已有内部文档、历史决策
   - 不能伪装成已经做过 web verification
2. `web-verified`
   - 结论主要基于当轮 web / 官方来源验证
3. `mixed`
   - 同时基于内部判断和外部最新来源

详细的研究路由和治理输入，分别见：

- [docs/workflows/internal-research-routing.md](./internal-research-routing.md)
- [docs/workflows/founder-governance-meeting-loop.md](./founder-governance-meeting-loop.md)
- [docs/workflows/process-compounding-cadence.md](./process-compounding-cadence.md)
