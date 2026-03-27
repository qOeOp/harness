# Codex Delta

更新日期：`2026-03-24`

## 目的

记录 Codex 相对于 [agent-operator-contract.md](../agent-operator-contract.md) 的 provider-specific delta。

本文件只记录 Codex 特有差异，不复述共性 operator rules。

## 适用面

当前仓库里与 Codex 直接相关的 adapter surface 主要是：

1. `AGENTS.md`
2. `.codex/config.toml`
3. `.codex/agents/`
4. [`.agents/skills/harness/roles/`](../../../roles)

当前 `.codex/agents/` 应视为 generated projection，而不是手工正文。

## Codex-Specific Operating Notes

### 1. Freshness Enforcement Is Documentation-Led

当前 Codex 侧没有与 Claude `UserPromptSubmit` 对等的项目级 prompt hook 约束面。

因此对 `volatile-by-default` 主题，Codex 主要依赖：

1. canonical routing
2. agent instructions
3. source note / URL linkage
4. explicit verification-mode honesty

这意味着 Codex 侧不能假装拥有不存在的自动拦截层。

### 2. Subagent Use Should Stay Bounded

Codex 支持 agent delegation，但默认不应固定 fan-out。

建议：

1. 小改动
   - 主线程单 review，或主线程 + 1 个风险向 reviewer
2. 中等改动
   - 主线程 + 2 个并行 reviewer
3. 高风险或跨层改动
   - 根据 [code_review.md](../code_review.md) 的 relevant dimensions 动态扩展 reviewer

不要把 review dimensions 误写成固定数量的 reviewer。

### 3. Worktree Escalation Is For Real Parallel Write Threads

Codex 的只读 sidecar exploration 不需要默认升级成独立 worktree。

只有在出现真实并行写入、长回合实现、或隔离实验时，才应走：

1. [`new_worktree.sh`](../../../scripts/new_worktree.sh)
2. [worktree-parallelism.md](../worktree-parallelism.md)

### 4. State Mutation Must Prefer Repo Scripts

Codex 在本仓库里修改运行态时，应优先走正式脚本，而不是直接 patch state files：

1. [`work_item_ctl.sh`](../../../scripts/work_item_ctl.sh)
2. [`upsert_work_item_progress.sh`](../../../scripts/upsert_work_item_progress.sh)
3. [`update_work_item_fields.sh`](../../../scripts/update_work_item_fields.sh)

### 5. Missing Adapter Capability Should Produce Honest Output

如果 Codex 当前 adapter surface 缺少某个能力，例如：

1. 项目级 hook
2. 已配置好的 project-scoped MCP
3. 某种稳定 automation surface

则正确做法是：

1. 明确说明当前缺口
2. 产出 reviewable artifact 或 adapter proposal
3. 不要把 provider-specific 偏好包装成 repo-wide truth

## 非目标

本文件不定义：

1. 仓库级 operator contract
2. 跨 agent 的 review standard
3. Claude / Gemini delta
4. 公司 OS 的 canonical semantics
