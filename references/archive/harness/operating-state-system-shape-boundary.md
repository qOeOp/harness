# Operating State System Shape Boundary

- Date: 2026-03-23
- Status: draft
- Owner: Chief of Staff
- Verification date: 2026-03-23
- Verification mode: mixed
- Sources reviewed:
  1. .agents/skills/harness/references/archive/harness/operating-state-system-brief.md
  2. .agents/skills/harness/references/archive/harness/harness-capability-matrix.md
  3. .agents/skills/harness/references/archive/harness/2026-03-23-coding-agent-operating-skeleton-research-memo.md
  4. https://github.github.com/gh-aw/patterns/projectops/
  5. https://github.github.com/gh-aw/introduction/overview/
  6. https://github.github.com/gh-aw/reference/compilation-process/
  7. https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/triaging-an-issue-with-ai

## Decision

`Operating State System v1` 应该借 `GitHub ProjectOps` 的 **shape**，但不应把 GitHub Projects 或 `gh-aw` 直接当成本地 state system 的主本体。

换句话说：

1. 借 `board / fields / safe transition / status update` 的设计语言
2. 不借 `GitHub-hosted project` 作为唯一 source of truth
3. 仍由本仓库自己拥有公司语义、work item schema 和部门参与矩阵

## Why now

我们已经确认：

1. 当前最大缺口是 `State`
2. `GitHub ProjectOps` 是当前最强的外部状态/看板 shape 参考
3. 如果不先划清“借什么、不借什么”，后面很容易直接把外部平台抽象反向塑形到公司语义层

## What To Borrow From ProjectOps

### 1. Board-first visibility, item-first storage

可借：

1. 用 board 回答“现在有什么工作、卡在哪里”
2. 用字段表达状态，而不是靠文件目录表达状态
3. 用派生视图服务不同角色

这和我们当前的 `work-item-first, board-derived` 完全一致。

### 2. Structured fields

可借的字段 shape：

1. `status`
2. `priority`
3. `effort`
4. `date`
5. `iteration`
6. `health summary`

对我们来说，直接启发的是：

1. `status`
2. `priority`
3. `due_review_at`
4. `last_updated`
5. `current_blocker`

### 3. Safe outputs / controlled transitions

ProjectOps 的重要启发不是 board 本身，而是：

1. agent 不直接任意写入系统
2. 通过受控动作更新状态
3. write 权限与 reasoning 权限分离

对我们 v1 的直接启发：

1. 不手工维护 board
2. 状态迁移应走脚手架而不是自由编辑
3. 未来可以把 `transition_work_item.sh` 视为本地 safe transition

### 4. Status updates as first-class output

ProjectOps 支持 project status update。

可借点：

1. 公司运行状态要有可读摘要
2. board 不只是列表，还要能生成 health update

对我们来说，这意味着：

1. `company board` 不只是列事项
2. 后续 `refresh_boards.sh` 应产出状态摘要
3. `Founder board` 本质上是高密度 status update 视图

## What We Must Own Ourselves

### 1. Company semantics

GitHub Projects 不会替我们定义：

1. Founder operating model
2. Chief of Staff 的职责
3. 部门语义
4. 部门之间的协作责任

这些必须继续由公司 OS 自己拥有。

### 2. Work item types

ProjectOps 适合通用项目管理，但不会替我们定义：

1. `vision`
2. `governance`
3. `company-init`
4. `research`
5. `department-task`
6. `demo`

这些类型直接影响部门参与、Founder 升级和资产绑定，不能外包。

### 3. Department participation matrix

这是我们最关键的自有层：

1. 哪类事项默认拉哪些部门
2. 哪些部门是 `required`
3. 哪些只是 `optional`
4. 哪些不该参与

ProjectOps 没法替你定义这一层。

### 4. Artifact linkage

我们现在已经有：

1. briefs
2. research memos
3. decision packs
4. process audits
5. snapshots
6. source notes

这些资产如何绑定到 work item，是我们自己的设计，不是 GitHub Projects 的职责。

### 5. Current / archive routing

`.harness/workspace/current`、`.harness/workspace/archive`、append-only memory、decision log 这些生命周期纪律，是我们当前 repo harness 的核心资产，不能被外部 board 取代。

## What Not To Borrow Yet

### 1. Do not use GitHub Projects as source of truth

原因：

1. 当前阶段强调 `local-first`
2. worktree 内可独立运行、可审计、可版本化更重要
3. 一上来把本体放到外部系统，会削弱 repo-local harness

### 2. Do not adopt `gh aw` workflows as our primary operating engine

原因：

1. `gh-aw` 更适合自动化 GitHub repository workflows
2. 我们现在设计的是公司运行态主骨架，不是 GitHub-hosted automation mesh
3. 当前阶段直接引入会把注意力拉向平台接入，而不是先把本地 schema 做稳

### 3. Do not copy GitHub’s field catalog blindly

比如：

1. `effort`
2. `sprint`
3. `roadmap dates`

这些字段是否真的有价值，要等我们先跑通最小 internal task loop 再决定。

## Recommended Borrow/Own Split

| Layer | Borrow | Own |
| --- | --- | --- |
| Board shape | `ProjectOps` 的 board / field / status update 思路 | `company / founder / department` 三类 board 的具体含义 |
| State fields | `status / priority / date / iteration / health` 这些通用字段思路 | `founder_escalation / department participation / artifact status` |
| Transitions | `safe outputs` 的受控写入思想 | `transition_work_item.sh` 的本地规则 |
| Ownership | 项目管理对象的 DRI 思路 | Founder / Chief of Staff / department lead 的权责结构 |
| Views | 多视图服务不同角色 | Founder board 的高密度决策面 |

## V1 Boundary

如果按阶段纪律推进，v1 只应收以下内容：

1. 本地 `work item` 文件本体
2. 本地 `company board / founder board / department board`
3. 最小字段：
   - `status`
   - `priority`
   - `owner`
   - `objective`
   - `ready_criteria`
   - `done_criteria`
   - `required_departments`
   - `founder_escalation`
   - `current_blocker`
   - `linked_artifacts`
   - `last_transition_event`
4. 受控脚手架：
   - `new_work_item`
   - `transition_work_item`
   - `refresh_boards`
   - `audit_state_system`
   - append-only `transition events`
   - per-work-item `hash chain`

## Risks

1. 如果借得太少，我们会继续闭门造状态层
2. 如果借得太多，我们会让 GitHub 的项目管理抽象反向塑造公司 OS
3. 如果一开始就把 GitHub Projects 接成主本体，local-first discipline 会被破坏

## Recommendation

下一步不该讨论“要不要直接上 GitHub Projects”，而该先拍板这一句：

**ProjectOps 只提供 shape，不提供 semantic authority。**

也就是说：

1. `shape borrowed`
2. `semantics owned`
3. `state local-first`
4. `GitHub sync optional later`
