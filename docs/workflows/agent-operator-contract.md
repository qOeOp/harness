# Agent Operator Contract

更新日期：`2026-03-28`

## 目的

定义本仓库中所有 coding agent 共用的 operator-level operating rules。

适用于：

1. Codex
2. Claude
3. Gemini
4. 后续新增的其他 coding agent provider

本文件是 `agent-neutral operator contract`，不是某个 provider 的 adapter 手册。

## 与其他文件的边界

1. 仓库级 first hop、routing 与 active truth
   - 在 framework source repo 中，先看 `SKILL.md`、`references/layering.md` 与 `references/runtime-workspace.md`
   - 在 materialized consumer runtime 中，先看 `.harness/entrypoint.md`
   - 详细 workflow source 再看 [document-routing-and-lifecycle.md](./document-routing-and-lifecycle.md)
2. 跨 agent 的 review contract
   - 见 [code_review.md](./code_review.md)
3. tool adapter capability 边界
   - 见 [tool-adapter-capability-map.md](./tool-adapter-capability-map.md)
4. volatile external research 默认规则
   - 见 [volatile-research-default.md](./volatile-research-default.md)
5. internal research dispatch 协议
   - 见 [internal-research-routing.md](./internal-research-routing.md)
6. worktree 并行规则
   - 见 [worktree-parallelism.md](./worktree-parallelism.md)
7. state / recovery / interrupt 协议
   - 先看 [document-routing-and-lifecycle.md](./document-routing-and-lifecycle.md)
   - 见 [work-item-recovery-protocol.md](./work-item-recovery-protocol.md)
   - 见 [work-item-interrupt-protocol.md](./work-item-interrupt-protocol.md)

本文件定义共性 operator rules，不定义 provider-specific command、hook、subagent syntax、MCP 安装方式或 config 格式。

这些差异应下沉到 `docs/workflows/provider-deltas/`，并只作为次级参考。

当前至少包括：

1. [provider-deltas/codex.md](./provider-deltas/codex.md)
2. [provider-deltas/gemini.md](./provider-deltas/gemini.md)

## Current Stage Bias

当前仓库阶段是 `pre-code`。

因此默认偏向：

1. 强 routing
2. 强 state hygiene
3. 强 verification honesty
4. 轻自动化
5. 轻 orchestration

不要因为某个 provider 支持 subagent、automation、MCP，就默认把这些能力全部打满。

## Default Operating Loop

所有 coding agent 的默认执行顺序是：

1. 先走 canonical routing，而不是先扫全仓库
2. 先识别当前 work item、state、artifact 边界
3. 再判断当前任务属于：
   - internal-only
   - volatile external
   - code change
   - governance / state mutation
4. 再决定：
   - 本地处理
   - parallel delegation
   - 外部检索
   - 独立 worktree
5. 完成后必须给出：
   - verification result
   - residual risk
   - 必要的 state / artifact writeback

## Decision Framework

每次正式执行前，至少应显式判断以下 5 个维度：

1. `Freshness`
   - 是否触碰 `volatile-by-default`
2. `Write scope`
   - 是否会改动 canonical docs、state、task-local code、consumer-local extensions、shared append-only memory
3. `Coupling`
   - 当前任务是否高度依赖即时上下文和连续推理
4. `Parallelism value`
   - 是否真的存在可独立并行的问题分解
5. `Verification burden`
   - 是否需要 tests、checks、review、official docs、source note 才能成立

如果这 5 个维度里任何一项不清楚，不要先写实现。

## Local-First Rule

默认优先本地处理。

以下情况优先由主线程本地完成：

1. 下一步被某个结果直接阻塞
2. 任务高度耦合，短时间内频繁改判断
3. 需要跨多个文件快速来回阅读和整合
4. 写入范围尚不稳定
5. 风险判断本身就是本轮核心工作

不要把最关键、最阻塞的下一步机械地外包给并行执行单元。

## Delegation Rule

只有在任务满足“边界清楚、产出明确、不会与当前主路径写冲突”时，才使用并行 delegation。

适合 delegation 的任务：

1. 针对代码库的具体、只读问题探索
2. 与主线程当前步骤不重叠的 sidecar research
3. 有明确 owned path 的局部实现
4. 并行验证、并行 review、并行风险扫描

不适合 delegation 的任务：

1. 当前主线程立刻依赖答案的 blocking task
2. 写入范围未定、owner 未定的改动
3. 需要反复来回切换假设的开放式问题
4. 只是为了显得“multi-agent”而做的 fan-out

委派时必须明确：

1. task goal
2. owned files 或只读范围
3. 预期输出
4. 是否允许写文件
5. 何时主线程需要等待结果

如果当前 provider 不支持并行 delegation，则按同样原则顺序执行，不要强行模拟第二套治理语义。

## External Context Rules

凡是触碰以下主题，默认视为 `volatile-by-default`：

1. Codex / Claude / Gemini / MCP / hooks / skills / workflow 的最新能力
2. 社区 best practice
3. 开源仓库近期动态
4. 新闻、监管、服务状态、定价或其他时间敏感外部事实

对这些主题：

1. 不要只靠模型记忆或仓库旧文档收敛
2. 优先使用 fresh official docs、MCP、source note
3. 若需要进入正式 artifact，优先先走 `research dispatch`
4. 若 fresh evidence 缺失，应标记：
   - `exploratory`
   - 或 `blocked by freshness`

当外部上下文可通过结构化工具接入时，优先顺序应为：

1. official docs / official APIs / MCP
2. official URLs
3. repository source notes
4. broader web search

如果 official source 与 community source 冲突：

1. official source 优先
2. community source 只能作为补充，不应单独成为 formal recommendation 的基础

## Worktree Rules

遵守 `one-thread-one-worktree`，但不要把每个并行执行单元都升级成独立 worktree。

默认：

1. 同一主线程内的只读探索或轻量 sidecar，不必新建 worktree
2. 存在真实并行写入、长回合实现、或独立实验分支时，才新建 worktree
3. 多个并行写线程不能共享同一 worktree
4. 公司级规范文件和 provider adapter 目录默认属于高敏感写入面，应谨慎授权

以下情况必须考虑独立 worktree：

1. 两个线程将并行修改不同子树
2. 某个线程需要长时间运行和多次提交
3. 某个实验可能污染主工作目录
4. Founder 或 reviewer 需要独立 inspect 一个隔离中的变更包

## Write Boundary Rules

coding agent 不得把聊天输出当成 canonical state mutation。

涉及正式 write 时，必须区分：

1. `canonical docs`
   - 允许修改，但应谨慎，避免把 adapter 规则写成 `harness` 真相
2. `state items / transitions / recovery`
   - 必须优先走正式脚本与协议，不手工伪造状态
3. `append-only memory`
   - 允许新增 artifact，但不应偷偷重写历史
4. `reviewable artifact`
   - 当风险较高或判断未封板时，优先产出 memo、dispatch、decision pack、inbox item，而不是直接改 canonical truth
5. `runtime role mutation`
   - 必须先有 `Role Change Proposal`
   - 再通过 `scripts/runtime_role_manager.sh` 写 `.harness/workspace/roles/`
   - wrapper 必须消费 role frontmatter 里的 `policy_*` 字段做机械检查

对 state mutation，优先使用：

1. [work_item_ctl.sh](../../scripts/work_item_ctl.sh)
2. `start / pause / resume / complete` 相关脚本
3. `upsert_work_item_recovery.sh`
4. `update_work_item_fields.sh`
5. provider execution handle 只作为 recovery / trace correlation 的辅助字段，不作为状态机真相

不要：

1. 手工 patch `.harness/tasks/*/task.md` 或 legacy `.harness/workspace/state/items/*.md` 伪造状态迁移
2. 跳过 transition event 直接宣称状态已变更
3. 在 founder-facing 或 canonical artifact 中包装未验证结论

## Verification Rules

任何实质性输出都必须回答：

1. 我改了什么
2. 我如何验证
3. 还有什么没验证
4. 剩余风险是什么

对 code change：

1. 能跑 tests/checks 就跑
2. 不能跑时必须明确说明原因
3. review 应遵守 [code_review.md](./code_review.md)

默认至少区分三层验证：

1. `result-level`
   - tests、checks、freshness gate、review 是否通过
2. `trace-level`
   - decision、tool calls、handoff、retry、interrupt 是否可解释、可回放
3. `state-level`
   - transitions、locks、writeback、derived views 是否满足 runtime contract

对 volatile external conclusion：

1. 必须有 official URL、fresh source note、或明确 external verification
2. formal artifact 必须写 `Verification mode`

对长回合任务：

1. 若任务不会在本轮自然收口，优先刷新 progress artifact
2. 会话结束前，不要把恢复信息只留在聊天里

## Reviewable-Artifact Bias

当满足以下任一条件时，默认优先产出 reviewable artifact，而不是直接改 canonical state：

1. 结论仍依赖 external freshness
2. 结论需要 Founder / Risk / manual review
3. 改动会扩大 trust boundary 或 permission surface
4. 编排方案仍在试验期
5. 当前只是提出 workflow / tooling 建议，而非已批准实施项

合法的 reviewable artifact 包括：

1. research dispatch
2. research memo
3. decision pack
4. requirements meeting brief
5. inbox item
6. review comment / review summary
7. role change proposal

## Stop-The-Line Conditions

出现以下任一情况，应暂停推进并先补控制面：

1. 当前 source of truth 不清楚
2. 当前问题属于 `volatile`，但 fresh evidence 缺失
3. 写入边界不清楚，不知道该写 canonical 还是 artifact
4. 并行线程会修改同一路径
5. state transition 需要发生，但正式脚本或 expected version 缺失
6. reviewer 或 operator 无法说明自己的验证覆盖了什么
7. 当前 proposal 只是 provider-specific 偏好，却被包装成 repo-wide truth

## Provider Deltas

provider-specific 差异只应记录在对应 delta 文件中。

当前路径：

1. [provider-deltas/codex.md](./provider-deltas/codex.md)

## Hard Truth

coding agent 的价值不在“看起来更像一个自治组织”，而在：

1. 更快进入真实任务对象
2. 更诚实地区分已验证与未验证
3. 更安全地并行
4. 更稳定地恢复

如果一个 workflow 不能强化这四点，它就只是更复杂的表面。
