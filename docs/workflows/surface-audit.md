# Surface Audit

更新日期：`2026-03-29`

## 目的

审计 active surface，控制文档膨胀、重复规则和错误的控制面升级。

`governance-surface-audit` 这个旧文件名与
`run_governance_surface_diagnostic.sh`
这个旧脚本名只作为 compatibility alias 保留。
若需要显式 shared-writeback 命名，
可使用 `run_shared_writeback_surface_diagnostic.sh`
这个桥接 alias；
canonical 名称统一收敛到 `surface audit` /
`run_surface_diagnostic.sh`，
不把 `governance` 重新抬回默认产品层。

默认周期性入口按仓库模式区分：

- source repo:
  - `./scripts/run_surface_diagnostic.sh --mode source`
  - `./scripts/audit_entropy_budget.sh`
- consumer / dogfood repo:
  - `./scripts/run_surface_diagnostic.sh --mode consumer`

## 审计对象

本仓库把以下对象统称为 `active surface`：

1. `md` 文档
2. `templates`
3. `skills`
4. `commands`
5. `hooks`
6. `rules`
7. `scripts`

## 核心原则

1. 不是所有规则都应该写成 md
2. 只有 `skills + scripts + contracts` 属于默认 capability / control surface
3. 不是所有规则都值得升级成 hooks 或 rules
4. 规则越重要、越高频、越机械，越应该向更硬的控制面迁移
5. 任何长期不触发、不被引用、不被执行的 md，都是裁剪候选
6. 审计脚本本身也属于 active surface，不能默认永远正确
7. active surface 是 working set，不是 evidence dump
8. 同一主题默认只应有一个 active canonical entry

## Entropy Budget Gate

source repo 的 active surface
除了人工 audit，
还必须过一层机械 budget gate。

当前默认 contract：

- `references/contracts/active-surface-entropy-budget-v1.toml`

当前默认 gate：

- `./scripts/audit_entropy_budget.sh`

规则：

1. budget 按 active source 计数，
   默认不把 `references/archive/`
   计入 source working set
2. budget breach 不是“提醒”，而是进入 `compaction-only mode`
3. `compaction-only mode` 默认只允许 `compress / merge / archive / delete`，
   或必须的 bug fix、contract tightening、把 prose rule 下沉到更硬 control surface
4. 若要提高 budget，
   必须显式修改 contract，
   并附 reviewable rationale；
   不允许靠连续小提交静默抬高
5. `run_surface_diagnostic.sh`
   继续负责暴露热点；
   `audit_entropy_budget.sh`
   负责把热点升级成
   可阻断的 source gate

## Promotion Matrix

### 保持为 md

适用：

- 宪法级原则
- 长期边界
- 需要大量判断的高层规则

### 升级为 skill

适用：

- 高频、结构化、可复用的工作流

### 降级为 command alias

适用：

- 只是为了更快触发已有 skill
- 不承载独立逻辑

### 升级为 hook / rule

适用：

- 必须每次执行的底层约束
- 例如：危险命令拦截、禁止破坏性 git 操作、必须落盘的格式校验

## 文档瘦身规则

每次 audit 都必须评估：

1. 这个 md 的 owner 是谁
2. 它解决什么问题
3. 它由什么触发
4. 最近一次被实际引用是什么时候
5. 它是否和其他文件重复
6. 它应该被：
   - keep
   - compress
   - merge
   - archive
   - delete
   - promote

额外必须过一轮 `survivor test`：

1. 这个文件当前到底承什么重
2. 如果删除它，默认读取顺序会失去哪个唯一入口
3. 它是否只是 archive lineage 的重复转述
4. 它是否可以被更小的 survivor doc 吸收
5. 它是否已经失去默认读者，只剩历史保存价值

若不能证明它在 active surface 上承重，默认进入：

1. `compress / merge`
2. `archive`
3. 或 `delete`

建议先跑一次聚合诊断，再进入人工判断：

- source repo:
  - `./scripts/run_surface_diagnostic.sh --mode source`
  - `./scripts/audit_entropy_budget.sh`
- consumer / dogfood repo:
  - `./scripts/run_surface_diagnostic.sh --mode consumer`

## Audit-the-Auditors

每月至少一次深度审计必须额外检查：

1. 当前审计脚本是否覆盖最新的目录结构和文档类型
2. 哪些检查仍然是静态枚举，应该升级为模式发现
3. 哪些检查只验证“文件存在”，却没有覆盖语义漂移
4. 新增 canonical doc 类型或控制面后，脚本是否同步更新
5. 哪些脚本已经失真，应修改或删除

## Freshness Audit

对以下主题，默认视为 `volatile`：

1. 外部快变事实
2. 规则 / 工具最新能力
3. 社区 best practice
4. 最新新闻和时间敏感判断

这类内容如果没有：

- `Verification date`
- `Sources reviewed`
- `Conflicting sources`

就不应该直接进入正式决策。

## 边界

hooks 不能完美证明 agent 做了足够的 web search。

当前能做的是：

1. 用流程和模板强制要求 freshness 字段
2. 用 review gate 阻止没有证据的结论进入正式决策
3. 用 skills 提高检索动作的触发概率
4. 只有在需要 provider-specific UX alias 时才保留 commands
5. 用 hooks / rules 处理那些真正能被机械校验的底层规则

## Audit 输出

每次 surface audit 至少产出：

1. keep list
2. compress / merge list
3. archive / delete list
4. promote-to-skill list
5. demote-to-command-alias list
6. promote-to-hook / rule list
7. freshness failures
8. script coverage gaps
9. next experiments
10. survivor failures
11. active-surface budget hotspots
12. budget status
13. whether compaction-only mode is active
