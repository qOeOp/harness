# Company OS / Product Runtime / Data Map

更新日期：`2026-03-27`

## 目的

区分 `Company OS`、`consumer runtime` 和 `data layer`，避免把 source repo 的默认治理团队误写成某个行业的固定组织结构。

## 三层定义

1. `Company OS`
   - `harness` 默认内置的项目管理 / 治理团队
   - 负责 problem definition、decision、writeback、workflow、quality gate 和 compounding
2. `Consumer Runtime`
   - 某个 repo 为自身运行需要按需 materialize 的角色、workstream 和 artifact
   - 可以创建 runtime-local role，但不反向定义 framework baseline
3. `Data Layer`
   - runtime 读取和写回的 task、artifact、decision、retro 和 source-note 对象

## 核心原则

1. 默认 baseline 是 PM / governance team，而不是行业组织图。
2. 不是每个 consumer runtime role 都值得升级成 source repo 的 built-in role。
3. data objects 是第一公民，角色只是围绕这些对象运转。
4. 同一个职责可以先由 baseline 角色兼任，只有反复出现摩擦时才 promotion 成 runtime-local role。

## 三层映射表

| Company OS Owner | Consumer Runtime Role | Primary Data Objects | Notes |
| --- | --- | --- | --- |
| `General Manager / Chief of Staff` | dispatcher / execution coordinator | founder briefs, task plans, decision packs, escalation notes | 默认协调入口，不等于必须长期存在的 runtime agent |
| `Product Thesis Lead` | problem framer | scoped requirements, acceptance criteria, non-goals | 负责把问题定义锋利化 |
| `Knowledge & Memory Lead` | ledger steward | decision logs, source notes, closure artifacts, canonical mappings | 保障 writeback 和 source-of-truth hygiene |
| `Workflow & Automation Lead` | workflow designer / operator | scripts, skills, automation configs, adapter contracts | 设计和维护执行链路 |
| `Risk & Quality Lead` | review gate / acceptance guard | acceptance reviews, risk notes, rollback conditions, dissent records | 负责 stop-the-line |
| `Compounding Engineering Lead` | process auditor | retros, process audits, improvement proposals, frontier scans | 负责复利和制度改进 |
| `Consumer-local runtime role` | repo-specific specialist | repo-specific artifacts defined by that role | 仅在复利 review 证明必要时，创建于 `.harness/workspace/roles/` |

## 推荐 runtime pipeline

```text
trigger
  -> problem definition
  -> research dispatch (if volatile)
  -> implementation / drafting
  -> risk & quality review
  -> decision / acceptance
  -> task-local writeback
  -> periodic compounding review
```

## 推荐数据对象

最小集合建议分成 6 类：

1. `Work Item`
   - task.md、Recovery section、status fields、handoff state
2. `Decision Artifact`
   - founder brief、decision pack、acceptance review
3. `Evidence Artifact`
   - source note、research memo、dispatch output
4. `Execution Artifact`
   - implementation notes、outputs、handoff memo
5. `Closure Artifact`
   - closure summary、archives、postmortem
6. `Compounding Artifact`
   - retro、pattern compaction、improvement proposal、trap check

## 设计边界

1. 不要因为某个 repo 临时创建了 runtime role，就把它升级成 source repo 默认组织角色。
2. 不要让 source repo 的全部治理角色都硬投影成用户可见的产品角色。
3. 第一版应优先保证 `runtime 简洁`，而不是 `组织结构对称`。
