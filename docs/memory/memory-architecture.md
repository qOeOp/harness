# Memory Architecture

更新日期：`2026-03-23`

## 设计原则

- 长期规范不应和短期任务状态混放。
- 运行中的结论必须能追溯到来源。
- 临时上下文可以丢，决策依据不能丢。
- 当前生效 truth 与历史快照必须分离。

## Layer 0: Constitution

作用：最稳定的组织规则与工具边界。

文件：

- `.harness/entrypoint.md`
- `CLAUDE.md`
- [docs/charter/company-charter.md](../charter/company-charter.md)

## Layer 1: Canonical Operating Docs

作用：组织结构、工作流、模板、目录规则。

文件：

- [docs/organization/org-chart.md](../organization/org-chart.md)
- [docs/organization/decision-rights.md](../organization/decision-rights.md)
- [docs/workflows/decision-workflow.md](../workflows/decision-workflow.md)
- [docs/workflows/document-routing-and-lifecycle.md](../workflows/document-routing-and-lifecycle.md)
  - 当前作为 detailed routing / lifecycle workflow source

## Layer 2: Operational Memory

作用：当前项目真实状态与可追溯记录。

文件：

- `.harness/workspace/current`
- `.harness/workspace/status/snapshots`
- `.harness/workspace/status/digests`
- `.harness/workspace/status/process-audits`
- `.harness/workspace/decisions/log`
- `.harness/workspace/research/sources`
- `.harness/workspace/intake/inbox`
- `.harness/workspace/intake/triage`

## Layer 3: Active Working Set

作用：本周或本轮运行中的 brief、research memo、decision pack。

目录：

- `.harness/workspace/briefs`
- `.harness/workspace/departments`

对于交易产品本身，后续应采用额外的三层记忆：

1. raw trade retros
2. pattern compactions
3. active trap library

它们的作用不同，不能混成一份巨型上下文直接喂给决策 agent。

## Layer 4: Archive

作用：过期但仍需可追溯的历史文件。

目录：

- `.harness/workspace/archive`

## Writeback Rules

1. 新结论先进入 memo / decision pack。
2. Founder 拍板后，新增一条 decision log entry，而不是改总表。
3. 阶段状态新增一条 snapshot，而不是并行改一个 current-state 文件。
4. 公司日报新增一条 digest，retro 新增一条 process audit。
5. 来源新增或评级变化时，新增或更新单独 source note。
6. 过期 artifact 不删除，移动到 archive。

目录生命周期与 current/archive 路由见：

- `.harness/entrypoint.md`
- [docs/workflows/document-routing-and-lifecycle.md](../workflows/document-routing-and-lifecycle.md)

## 禁止事项

1. 不要把所有长期知识塞进 `CLAUDE.md`。
2. 不要把临时 brainstorming 当成 canonical truth。
3. 不要出现多个 source of truth。
4. 不要让多个线程同时编辑公司级共享总表文件。
