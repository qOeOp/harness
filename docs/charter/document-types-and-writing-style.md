# Document Types And Writing Style

更新日期：`2026-03-28`

## 目的

统一 `harness` canonical docs 的类型边界和写作风格，避免把推导过程错误地写进常驻规则文档。

## 文档类型

### 1. Canonical Docs

适用：

- `docs/charter/`
- `docs/organization/`
- `docs/workflows/`
- `docs/memory/`
- 根 `README.md`
- 根 `SKILL.md`
- 部门级 `README.md` / `charter.md` / `interfaces.md`

作用：

- 表达当前生效的规则、边界、路由、职责和制度

写法要求：

1. 直接写结论和规则
2. 用稳定标题，例如：
   - 目的
   - 适用范围
   - 角色与职责
   - 规则
   - 输入
   - 输出
   - 禁止事项
3. 强调可执行性和可查找性
4. 尽量短，避免故事化叙述

禁止：

1. `Divergent Hypotheses`
2. `First Principles Deconstruction`
3. `Convergence to Excellence`
4. `问题定义`
5. `第一性原则`
6. `关键判断`

这些内容不属于 canonical docs。

### 2. Decision And Brief Artifacts

适用：

- `.harness/tasks/<task-id>/attachments/`
- `.harness/tasks/<task-id>/closure/`
- `.harness/workspace/briefs/`
- `.harness/workspace/decisions/log/`
- `.harness/workspace/status/snapshots/`
- Founder-facing meeting briefs

作用：

- 保留推导、取舍、上下文、拍板结果和阶段状态
- 默认先贴着 task 写；只有明确需要跨任务可见性时才 promote 到 governance surface

写法要求：

1. 可以包含推导过程
2. 可以解释为什么采取某个路径
3. 需要明确日期、状态、是否 superseded

### 3. Research Artifacts

适用：

- `.harness/workspace/research/`
- `docs/research/`

作用：

- 保存调研结果、来源、争议点、未知数

写法要求：

1. 允许有推导过程和研究框架
2. 允许比较多个方案
3. 必须带 freshness 信息和来源

## 判断规则

如果一个文档的主要作用是：

1. 告诉人“现在规则是什么”
   - 它是 canonical doc
2. 告诉人“为什么这次这么决定”
   - 它是 decision/brief artifact
3. 告诉人“外部资料说明了什么”
   - 它是 research artifact

## Canonical Docs 的正确风格

正确：

- 短
- 直
- 稳定
- 可检索
- 可执行

错误：

- 把 reasoning template 留在常驻规则文档里
- 一份规则文档同时承担“辩论记录 + 制度说明”
- 为了完整而把历史推导过程长期保留在 active rules 中

## 瘦身策略

当 canonical doc 里出现推导腔时：

1. 删掉推导标题
2. 只保留当前生效结论
3. 若推导有保留价值，迁到：
   - decision log
   - brief
   - research note

## 审计

使用：

1. `./scripts/audit_doc_style.sh`

它会检查 canonical docs 中是否残留禁止标题。
