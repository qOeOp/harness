# Harness Capability Matrix

- Date: 2026-03-23
- Status: draft
- Owner: Compounding Engineering Lead
- Verification date: 2026-03-23
- Verification mode: mixed
- Sources reviewed:
  1. .agents/skills/harness/references/archive/harness/2026-03-23-coding-agent-operating-skeleton-research-memo.md
  2. .harness/workspace/research/sources/2026-03-23-coding-agent-operating-skeleton-patterns.md
  3. .agents/skills/harness/references/archive/harness/company-harness-map.md
  4. .agents/skills/harness/references/archive/harness/operating-state-system-brief.md

## 目的

按当前最相关的 6 层能力，对比：

1. `Codex`
2. `Claude Code`
3. `Gemini CLI`
4. `OpenHands`
5. `GitHub ProjectOps / Agentic Workflows`
6. `MetaGPT / ChatDev`

判断每层：

1. 谁最强
2. 谁只是 shape reference
3. 我们当前应该借谁

## 六层能力

1. `Entry`
2. `Policy`
3. `Agent-native orchestration`
4. `Repo control surface`
5. `State / boards`
6. `Feedback / review loops`

## 总览矩阵

| Layer | Codex | Claude Code | Gemini CLI | OpenHands | GitHub ProjectOps | MetaGPT / ChatDev | 我们现在该借谁 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Entry` | 强 | 强 | 中 | 中 | 弱 | 弱 | `Codex + Claude + Gemini` |
| `Policy` | 中 | 中 | 中 | 中 | 中 | 弱 | `自定义公司 OS + provider adapters` |
| `Agent-native orchestration` | 强 | 强 | 强 | 中 | 弱 | 强 | `Claude + Codex + Gemini` |
| `Repo control surface` | 强 | 中 | 中 | 强 | 中 | 弱 | `Codex + OpenHands` |
| `State / boards` | 弱 | 弱 | 弱 | 弱 | 强 | 弱 | `GitHub ProjectOps` |
| `Feedback / review loops` | 强 | 中 | 中 | 中 | 强 | 中 | `Codex + GitHub ProjectOps + 自己的 governance loop` |

## Layer-by-Layer Judgment

### 1. Entry

最适合借：

1. `Codex`
2. `Claude Code`
3. `Gemini CLI`

原因：

1. 都支持 repo-local instructions / project-level context
2. 都适合做根入口和部门入口镜像

结论：

这一层我们已经做得比较对，不需要从 OpenHands 或 MetaGPT 借主骨架。

### 2. Policy

没有哪个外部项目能替你定义：

1. Founder operating model
2. 公司部门语义
3. 愿景边界
4. 组织升级规则

结论：

`Policy` 必须自己定义。  
外部只给 shape，不给答案。

### 3. Agent-native orchestration

这一层最值得借的是 provider 原生能力：

1. `Codex`
   - agents
   - skills
   - rules
   - approvals
   - app server / exec / sdk
2. `Claude Code`
   - hooks
   - subagents
   - slash commands
3. `Gemini CLI`
   - hooks
   - subagents
   - skills
   - policy engine

结论：

这一层不要自造新抽象，应该尽量贴着 provider 原生能力做 tool adapter。

### 4. Repo control surface

这一层最值得借：

1. `Codex`
   - repo-local artifacts
   - skills / rules / agent loop integration
2. `OpenHands`
   - `.openhands/setup.sh`
   - `.openhands/pre-commit.sh`
   - repo skills

结论：

我们当前的 scripts / hooks / entrypoints 方向是对的。  
这里不需要重框架，只需要继续变硬。

### 5. State / boards

这是当前最缺，也最明确应该借外部 shape 的层。

最值得借：

1. `GitHub ProjectOps / Agentic Workflows`

原因：

1. 它天然就是 work item / status / board / triage / safe output 体系
2. 这正是我们当前 harness 的核心空白

不该借：

1. `MetaGPT / ChatDev`
2. provider 原生 agent tools

原因：

它们都不是为“公司运行状态主骨架”设计的。

### 6. Feedback / review loops

这层要混搭：

1. `Codex`
   - review / approvals / repo-local artifacts / trace-rich outputs
2. `GitHub ProjectOps`
   - board-driven review / issue triage / status-driven safe operations
3. `我们自己的 governance loop`
   - governance meeting
   - process audit
   - founder acceptance

结论：

反馈层已经有雏形，但要等 state layer 建好后，才能真正挂到 work items 上。

## What Not To Do

1. 不要把 `MetaGPT / ChatDev` 当主骨架
2. 不要期待 `Codex / Claude / Gemini` 自带能力替你完成 state system
3. 不要把 `GitHub ProjectOps` 当公司语义层
4. 不要为了“最先进”把每家 provider 的功能全堆上

## Best Combination For Us

当前最优组合不是单押一个平台，而是：

1. `Company semantics`
   - 自己定义
2. `Entry`
   - Codex / Claude / Gemini 三工具统一镜像
3. `Agent-native orchestration`
   - 优先用各 provider 原生能力
4. `Repo control surface`
   - 借 Codex / OpenHands 的 repo-local harness shape
5. `State / boards`
   - 借 GitHub ProjectOps 的状态字段与 board 思路
6. `Feedback`
   - 自己的 governance + provider-native reviews + board-driven review

## Recommendation

我们现在不该继续发散“还可以用什么功能”，而该聚焦：

1. `State` 层借 GitHub ProjectOps 的 shape
2. `Control` 层继续贴 provider 原生能力
3. `Policy` 和 `Company semantics` 继续自己拥有

## Current Gap Summary

如果按先进 harness 的六层来看，我们当前的差距排序是：

1. `State / boards`
2. `Feedback 挂接到 state`
3. `Repo control surface 的状态脚手架`
4. `Agent-native orchestration 的系统化`

而不是：

1. 再加更多角色
2. 再加更多 md
3. 再追更多 provider 新功能
