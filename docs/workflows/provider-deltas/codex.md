# Codex Delta

更新日期：`2026-03-28`

## 目的

记录 Codex 相对于 [agent-operator-contract.md](../agent-operator-contract.md) 的 provider-specific delta。

本文件只记录 Codex 特有差异，不复述共性 operator rules。

## 适用面

当前仓库里与 Codex 直接相关的 adapter surface 主要是：

1. `AGENTS.md`
2. `.codex/config.toml`
3. `.codex/agents/`
4. [`roles/`](../../../roles)

其中：

1. consumer repo 里的 `AGENTS.md`、`.codex/config.toml` 与 `.codex/agents/` 都属于 user-owned/provider-owned surface，harness 不负责生成或修改
2. 本仓库 `roles/` 仍是 canonical role source

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

默认 handoff 应是最小必要、结构化、可审计的 capability packet，而不是把 parent context 整包 fork 给 worker。

推荐最小 handoff：

1. capability / bundle slug
2. owned files 或只读范围
3. output contract
4. write boundary
5. budget / stop boundary

不要默认传递：

1. full parent session transcript
2. full system prompt
3. 未裁剪的临时上下文

只有当下一步确实被同一段上下文阻塞时，才把 full-context fork 当成升级动作，而不是默认动作。

### 3. Worktree Escalation Is For Real Parallel Write Threads

Codex 的只读 sidecar exploration 不需要默认升级成独立 worktree。

只有在出现真实并行写入、长回合实现、或隔离实验时，才应走：

1. [`new_worktree.sh`](../../../scripts/new_worktree.sh)
2. [worktree-parallelism.md](../worktree-parallelism.md)

### 4. State Mutation Must Prefer Repo Scripts

Codex 在本仓库里修改运行态时，应优先走正式脚本，而不是直接 patch state files：

1. [`work_item_ctl.sh`](../../../scripts/work_item_ctl.sh)
2. [`upsert_work_item_recovery.sh`](../../../scripts/upsert_work_item_recovery.sh)
3. [`update_work_item_fields.sh`](../../../scripts/update_work_item_fields.sh)

### 5. Autonomy Budget Must Be Explicit

当前 Codex adapter surface 不会自动替你 enforce repo-level
`max turns / iterations`、timebox、tool budget 或 kill semantics。

因此：

1. 长任务或 worker run 启动前，要在 task、`## Recovery`
   或 delegation brief 中写出显式 budget / stop boundary
2. budget 命中、cancel、kill 或 timebox 触发时，要落成 transition、recovery 更新或 reviewable artifact
3. 不要把“模型自己会停”误当成 runtime contract

### 6. Missing Adapter Capability Should Produce Honest Output

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
4. `harness` 的 canonical semantics
