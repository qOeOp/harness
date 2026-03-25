# Project Structure

更新日期：`2026-03-25`

> 注意：
> 当前仓库仍处于两代结构并存的过渡态。
> canonical 功能性 surface 只允许三种命运：
> 1. 并入 `.agents/skills/harness/`
> 2. 并入 `.harness/`
> 3. 删除
>
> 顶层 provider adapter 是唯一例外：
> `.claude/`、`.codex/`、`.gemini/` 允许继续保留为薄 adapter。

## 顶层目录

下列条目分为：

1. `当前仍存在`
2. `最终目标去向`

- `README.md`: 仓库总览
- `.harness/entrypoint.md`: 当前 canonical first hop
- `.agents/skills/harness/docs/workflows/document-routing-and-lifecycle.md`: detailed routing / lifecycle workflow source，已并入 `harness`
- `CLAUDE.md`: Claude redirect stub，转发到 `.harness/entrypoint.md`
- `AGENTS.md`: AGENTS redirect stub，转发到 `.harness/entrypoint.md`
- `GEMINI.md`: Gemini redirect stub，转发到 `.harness/entrypoint.md`
- `docs/`: 已删除；由 `.agents/skills/harness/docs/` 完全接管
- `workspace/`: 已删除；由 `.harness/workspace/` 完全接管
- `.claude/`: Claude provider adapter，最终保留为顶层薄 adapter
- `.codex/`: Codex provider adapter，最终保留为顶层薄 adapter
- `.gemini/`: Gemini provider adapter（当前只保留 settings；workspace skills 直接消费 `.agents/skills/` alias；custom agents 仍未启用），最终保留为顶层薄 adapter
- `.agents/skills/`: 当前 canonical skill source；`harness/` 已创建为唯一目标 carrier，最终压缩为单一 `.agents/skills/harness/`
- `.agents/skills/harness/scripts/`: 当前唯一脚本与审计入口，已并入 `harness`
- `.harness/`: 新建中的 repo-local runtime workspace，最终承接当前实例态与运行态

说明：

1. 公司 OS 的 canonical capability surface 收敛为 `single harness skill source + repo-local .harness runtime`
2. `.claude/`、`.codex/`、`.gemini/` 当前仍是 provider adapters，最终继续保留为顶层薄 adapter
3. `commands`、`hooks` 若存在，只是 adapter，不是 canonical truth
4. `.claude/skills/` 当前是物理 projection 副本，不是软链接
5. `.agents/skills/harness/` 已存在，当前作为最终 skill carrier 的先行 scaffold

## 最终收口目标

### Move Into `.agents/skills/harness/`

- 无剩余顶层 source 候选

已完成：

- `docs/ -> .agents/skills/harness/docs/`
- `scripts/ -> .agents/skills/harness/scripts/`
- 现有并列 skill 目录 -> `.agents/skills/harness/skills/`
- `codex/ -> .agents/skills/harness/references/provider-adapters/codex/`
- `.agents/roles/ -> .agents/skills/harness/roles/`

### Keep As Top-Level Provider Adapters

- `.claude/`
- `.codex/`
- `.gemini/`

### Move Into `.harness/`

- 无剩余顶层 runtime 候选
- 已完成：
  - `workspace/ -> .harness/workspace/`
  - `departments/ -> .harness/workspace/departments/`

### Delete

- 不属于 clean skill source、也不属于 repo-local runtime 的功能性目录

## `.agents/skills/harness/docs/`

- `charter/`: 使命、阶段边界、原则
- `organization/`: org chart、decision rights
- `workflows/`: 决策与 review 流程
- `memory/`: 记忆架构说明
- `research/`: 前沿实践与技术调研
- `templates/`: 标准化输出模板

## .harness/workspace/departments/

每个部门目录的标准结构：

- `README.md`: 本部门职责与 owned paths
- `AGENTS.md`: canonical 局部指令
- `CLAUDE.md`: Claude 局部镜像入口
- `GEMINI.md`: Gemini 局部镜像入口
- `charter.md`: 部门章程
- `interfaces.md`: 输入输出协议
- `workspace/`: 本部门运行态文档

推荐子结构：

- `workspace/intake/`
- `workspace/memos/`
- `workspace/outputs/`
- `workspace/reports/daily/`
- `workspace/reports/retros/`

## `.harness/workspace/`

repo-local runtime workspace 的主要目录：

- `current/`: 当前稳定 truth
- `briefs/`: in-flight brief 与必要 redirect stub
- `departments/`: 各部门 runtime workspace 与本地 charter/interface
- `intake/`: inbox / triage
- `research/`: dispatches / sources
- `decisions/log/`: append-only 决策落账
- `status/`: digests / process-audits / snapshots / demos
- `state/`: items / boards / transitions / progress / board-refreshes
- `runs/`: dogfood / evolution run
- `archive/`: repo-local 历史快照
