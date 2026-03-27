# Decision Rights

更新日期：`2026-03-27`

## Founder 必须拍板的事项

1. 使命改变或产品方向改变。
2. 阶段性 go / pause / kill。
3. 风险豁免与高权限自动化升级。
4. 把 consumer runtime role 升级成 source repo baseline role，或删除现有 baseline role。
5. runnable demo 的最终验收，或任何跨越已批准产品边界的交付。

## Founder 默认不参与的事项

1. 日常 requirements 拆解。
2. 日常实现讨论与技术选型争论。
3. 普通内部 review。
4. 已批准 vision 内的日常优先级微调。

## General Manager / Chief of Staff 可自主决定的事项

1. 当前阶段 owner 分配。
2. 会议 cadence 与汇报节奏。
3. 文档模板的采用与淘汰。
4. 什么内容需要先返工再上报 Founder。
5. 是否需要新建 consumer runtime role，还是继续由 baseline 团队兼任。

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
4. 决策日志、研究索引和 closure artifact 的格式。

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
4. 哪些 playbook、skill、script、ritual 需要提出优化建议。
5. 哪些重复工作已值得 promotion 为 runtime-local role。
6. 在 accepted task 的复利 review 后，是否需要提交 `Role Change Proposal` 并调用 `Runtime Role Manager` 执行。

## Runtime Role Manager 可自主决定的事项

1. 在已批准 proposal 范围内，如何创建、编辑和审计 `.harness/workspace/roles/<slug>.md`。
2. role file 的命名、frontmatter 合法性和 schema 合规性。
3. 是否因 proposal 缺失、写边界越权或 schema 非法而拒绝执行并升级。

## Optional Runtime Role Owners 可自主决定的事项

仅当 `advanced governance mode` 已启用且该角色已经 materialize 时：

1. 在既有 charter 内如何完成本角色职责。
2. 需要向哪个相邻角色发起 handoff。
3. 哪些输入质量不足，必须退回上游。
4. 本角色 runtime-local artifacts 的组织方式。

## Optional Runtime Role Owners 必须升级的事项

1. 要改变跨角色接口协议。
2. 要改变 Founder 已批准的产品边界、阶段目标或风险约束。
3. 要新增高权限自动化或外部数据接入方式。
4. 需要改动 source repo 的 canonical docs、baseline roles 或 shared contracts。
5. 需要把自己 promotion 成 source repo 的默认基线角色。

## Founder 输入物料的升级规则

1. Founder 输入默认先进入 `General Manager / Chief of Staff`。
2. 由其决定：丢弃、观察、进入研究、进入试点建议。
3. 默认优先复用 baseline 团队处理，而不是立刻新建 runtime role。
4. 如果该类输入反复出现并证明需要独立 owner，应在 accepted task 的复利 review 中提出 `Role Change Proposal`。
5. proposal 获得通过后，由 `Runtime Role Manager` 在 `.harness/workspace/roles/` materialize runtime-local role。
6. 若涉及北极星、风险豁免或资源重分配，最终仍由 Founder 拍板。

## 升级规则

1. 角色间争议先由 `General Manager / Chief of Staff` 裁决。
2. 如果争议触及使命、风险豁免、预算或高权限自动化，升级给 Founder。
3. 任何未经 writeback 到 task-local artifacts 或显式 governance memory 的决定无效。

## Owned Paths Policy

1. runtime-local role 定义文件路径是 `.harness/workspace/roles/<slug>.md`。
2. 公司级 `.harness/workspace/` 只允许 append-only 写入。
3. `SKILL.md`、`docs/`、`roles/`、`references/contracts/` 只允许治理基线角色修改。
4. runtime role mutation 必须先有 `Role Change Proposal`，再通过 `scripts/runtime_role_manager.sh` 执行。
