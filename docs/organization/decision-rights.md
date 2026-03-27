# Decision Rights

更新日期：`2026-03-22`

## Founder 必须拍板的事项

1. 使命改变或产品方向改变。
2. 阶段性 go / pause / kill。
3. 风险豁免与高权限自动化升级。
4. 新增关键角色或删除关键流程。
5. 第一阶段产品楔子和资产范围改变，例如从 `BTC-only` 扩张到更多资产。

## Founder 默认不参与的事项

1. 日常 requirements 拆解。
2. 日常实现讨论与技术选型争论。
3. 普通部门内部 review。
4. 已批准 vision 内的日常优先级微调。

## Chief of Staff 可自主决定的事项

1. 当前阶段 owner 分配。
2. 会议 cadence 与汇报节奏。
3. 文档模板的采用与淘汰。
4. 什么内容需要先返工再上报 Founder。
5. 已批准 vision 内的日常 requirements meeting 是否召开、由谁主持、如何分发到部门。

## Product Thesis Lead 可自主决定的事项

1. 本阶段只验证哪一个命题。
2. 哪些问题属于非目标。
3. 哪个 use case 先做。
4. 决策包中的推荐方案与备选方案。
5. 在 Founder 已批准的 vision 边界内，如何把产品愿景翻译成内部需求。

## Knowledge & Memory Lead 可自主决定的事项

1. 文档分类和命名规范。
2. 哪些文档是 source of truth。
3. 何时归档、如何归档。
4. 决策日志与研究索引格式。

## Workflow & Automation Lead 可自主决定的事项

1. 采用哪些 project-level agents / skills / hooks / commands。
2. 哪些脚本进入项目默认基线。
3. 哪些工作流是只读、草稿态、可执行态。
4. 哪些 MCP / plugin 进入观察名单，哪些暂缓。

## Risk & Quality Lead 可自主决定的事项

1. 质量门是否通过。
2. 哪些自动化必须回退到手动。
3. 哪些 artifact 不达标、必须返工。
4. 哪些工作不能继续推进，直至风险澄清。

## Compounding Engineering Lead 可自主决定的事项

1. 日报、retro、checkpoint 的标准格式与节奏。
2. 哪些流程问题值得进入 process audit。
3. 哪些社区实践值得进入观察、研究或试点。
4. 哪些 playbook、skill、hook、ritual 需要提出优化建议。
5. Founder governance 会议的议程和预读材料结构。

## Compounding Engineering Lead 必须升级的事项

1. 需要改变公司级治理结构或关键阶段门。
2. 需要引入新的高权限自动化范式。
3. 需要调整 Founder review 方式或 demo gate。
4. 需要改变跨部门 owned paths 或核心接口协议。
5. 需要改变 Chief of Staff 的承诺管理或部门间协作责任分配。

## Chief of Staff 关于会议与执行的职责

1. 负责产出 company daily digest。
2. 负责在 Founder 会议后把跨部门承诺和 owner 落实为执行计划。
3. 负责监督部门 leader 的改进计划是否按约推进。

## Department Leads 可自主决定的事项

1. 本部门内部 memo、SOP、检查清单格式。
2. 在既有 charter 内如何完成本部门职责。
3. 需要向哪个相邻部门发起 handoff。
4. 哪些输入质量不足，必须退回上游。
5. 本部门 `workspace/` 子树内的内容组织与迭代。

## Department Leads 必须升级的事项

1. 要改变跨部门接口协议。
2. 要改变 Founder 已批准的策略、风险约束或阶段目标。
3. 要新增高权限自动化或外部数据接入方式。
4. 发现当前部门 charter 已经不适配实际工作。
5. 需要改动公司级规范文件或其他部门 owned paths。

## Founder 输入物料的升级规则

1. Founder 输入先进入 `Learning & Evolution Department`。
2. 该部门可以决定：丢弃、观察、进入研究、进入试点建议。
3. 如果要让 Founder 输入升级为正式策略或正式流程变更，必须经过：
   - Strategy Research review
   - Risk review
   - Chief of Staff 汇总
4. 若涉及北极星、风险豁免或资源重分配，最终由 Founder 拍板。

## 升级规则

1. 角色间争议先由 Chief of Staff 裁决。
2. 如果争议触及使命、风险豁免、预算或高权限自动化，升级给 Founder。
3. 任何未经回写到 `.harness/workspace/decisions/log` 的决定无效。

## Owned Paths Policy

1. 部门线程主写路径为 `.harness/workspace/departments/<department>/`.
2. 公司级 `.harness/workspace/` 仅允许 append-only 写入。
3. `docs/`、根 `CLAUDE.md`、根 `AGENTS.md` 只允许治理层角色修改。
