# Governance Surface Audit

更新日期：`2026-03-24`

## 目的

审计公司的治理表面，控制文档膨胀、重复规则和错误的控制面升级。

默认周期性入口按仓库模式区分：

- source repo:
  - `./scripts/run_governance_surface_diagnostic.sh --mode source`
- consumer / dogfood repo:
  - `./.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh --mode consumer`

## 治理表面

本公司把以下对象统称为 `governance surface`：

1. `md` 文档
2. `templates`
3. `skills`
4. `agents`
5. `commands`
6. `hooks`
7. `rules`
8. `scripts`

## 核心原则

1. 不是所有规则都应该写成 md。
2. 只有 `agents + skills` 属于 canonical capability surface。
3. 不是所有规则都值得升级成 hooks 或 rules。
4. 规则越重要、越高频、越机械，越应该向更硬的控制面迁移。
5. 任何长期不触发、不被引用、不被执行的 md，都是裁剪候选。
6. 审计脚本本身也属于治理表面，不能默认永远正确。

## Promotion Matrix

### 保持为 md

适用：

- 宪法级原则
- 长期边界
- 需要大量判断的高层规则

### 升级为 skill

适用：

- 高频、结构化、可复用的工作流
- 例如：`meeting`、`daily-digest`、`retro`

### 降级为 command alias

适用：

- 只是为了更快触发已有 skill
- 不承载独立逻辑

### 升级为 hook / rule

适用：

- 必须每次执行的底层约束
- 例如：危险命令拦截、禁止破坏性 git 操作、必须落盘的格式校验

### 升级为 agent

适用：

- 长期稳定、职责清晰、需要持续存在的角色

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

建议先跑一次聚合诊断，再进入人工判断：

- source repo:
  - `./scripts/run_governance_surface_diagnostic.sh --mode source`
- consumer / dogfood repo:
  - `./.agents/skills/harness/scripts/run_governance_surface_diagnostic.sh --mode consumer`

## Audit-the-Auditors

每月至少一次深度审计必须额外检查：

1. 当前审计脚本是否覆盖最新的目录结构和文档类型
2. 哪些检查仍然是静态枚举，应该升级为模式发现
3. 哪些检查只验证“文件存在”，却没有覆盖语义漂移
4. 新增部门、工具适配层、current truth 或 canonical docs 后，脚本是否同步更新
5. 哪些脚本已经失真，应修改或删除

当发生以下任一事件时，必须提前触发一次 `audit-the-auditors`：

1. 新增部门
2. 新增工具适配层
3. 新增 canonical doc 类型
4. 最近两次 audit 重复报出同类漏检
5. Founder 或治理层明确认为文档系统开始变脏

## Freshness Audit

对以下主题，默认视为 `volatile`：

1. 市场资讯
2. 实时价格
3. 规则/工具最新能力
4. 社区 best practice
5. 最新新闻和时间敏感判断

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

每次 governance surface audit 至少产出：

1. keep list
2. compress / merge list
3. archive / delete list
4. promote-to-skill list
5. demote-to-command-alias list
6. promote-to-hook / rule list
7. freshness failures
8. script coverage gaps
9. next experiments
