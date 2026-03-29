# Agent Operator Contract

更新日期：`2026-03-29`

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

本文件定义共性 operator rules，
不定义 provider-specific command、hook、subagent syntax、
MCP 安装方式或 config 格式。

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

## Control Surface Rule

会改变默认行为基线的文本面，不应被当成“只是文案”。

至少包括：

1. `README / SKILL.md / rules / role`
2. prompt object / managed policy
3. model snapshot、tool contract（tool name / description / argument schema / output contract）与 runtime code revision 的绑定关系

默认要求：

1. 这类 instruction surface 应视为 versioned control surface
2. `README`、`SKILL.md`、subagent prompt、prompt object
   默认属于 steerability surface，
   不是单独足以承担 hard enforcement 的 policy gate
3. 若某条规则的违规成本高，
   必须继续下沉到 hooks、managed policy、tool approval、
   allowlist、typed schema 或 wrapper 机械检查
4. promote 前要有 reviewable diff
5. 若改动会改变 agent 行为、路由、permission 或恢复边界，
   需要同步跑对应 deterministic gate、replay fixture 或 eval slice
6. 不要在 live session 里让 instruction surface 隐式漂移

不要因为某个 provider 支持 subagent、automation、MCP，就默认把这些能力全部打满。

## Prompt Shape Stability Rule

`prompt shape / runtime config surface`
不是 task truth，
但它决定长任务里的 cache、compaction
与行为稳定性。

默认要求：

1. static instructions、examples、tool name / description / argument schema / output contract、image descriptors、
   sandbox / cwd / approval metadata 一起构成 prompt shape / runtime config surface
2. 长回合里应尽量保持 exact-prefix 稳定，
   不把 prompt shape stability
   误当成纯性能优化
3. 新的 task delta、tool observation
   与最新 user intent
   默认追加在尾部，
   不静默回写早前前缀
4. mid-run 动态切换 model snapshot、
   改 tool 集合或枚举顺序、
   变更 sandbox config、
   approval mode、cwd
   或其他会破坏前缀稳定性的配置，
   默认应视为显式 boundary /
   transition，
   而不是静默漂移
5. active run 默认应绑定其启动时的
   runtime code revision、tool contract、
   prompt bundle / policy snapshot
6. 跨部署允许 old / new revision
   并存直到 run 完成、迁移
   或 fail closed，
   不做静默 hot-swap

## Skill Trust Boundary

`remote / marketplace / user-supplied skill`
默认先视为潜在不可信的
instruction + code surface。

默认要求：

1. 未经过 curate / review / version pin 前，
   不进入 executable catalog，
   也不应获得默认 capability grant
2. “终端用户可选”或 provider 可发现，
   不等于 repo 的 security baseline
3. 若要评估外部 skill，
   先把它当 research / pilot 输入，
   输出先落成 source note、decision pack
   或其他 reviewable artifact
4. 未审阅的 external skill
   不应直接注入高优先级
   instruction / policy layer

## Observability Capture Rule

observability / replay 默认服务的是解释执行、关联证据与调试，
不是把 prompt、工具输入输出和模型内容
再复制成第二套高敏感语料库。

默认要求：

1. 完整 prompt、instruction、tool payload 与 model output 默认不采集
2. 内容级捕获必须显式 opt-in，而不是静默默认开启
3. 优先记录 artifact path、evidence reference、object handle 或 content hash；若 tool output 体积大、可分页或高保真，默认让 tool contract 优先返回 handle / locator / page token，不把大 blob 直接塞回上下文
4. source / provenance metadata 例如 `tool`、`human approval`、`external evidence`、`framework note` 应独立于 message / transcript / trace display surface 保留，不要在转换视图时把信任来源抹平
5. tracing backend 不应承担第二份 canonical task memory 的职责
6. 若 runtime 默认开启内建 tracing 或 agent SDK tracing，必须显式声明 capture policy、redaction policy 与 disable path；不要假设 vendor default 天然满足 least-data，也不要与外部 instrumentation 双重上报或默默复用冲突语义
7. trace correlation 最好走协议元数据透传，例如 `traceparent` / `baggage` 与 `tool_use` / `tool_result` `_meta`，不只依赖 transport log 或 vendor-side 拼接

## Default Operating Loop

所有 coding agent 的默认执行顺序是：

1. 先走 canonical routing，而不是先扫全仓库
2. 先识别当前 work item、state、artifact 边界
3. 再判断当前任务属于：
   - internal-only
   - volatile external
   - code change
   - control-surface / state mutation
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

每次正式执行前，至少应显式判断以下 6 个维度：

1. `Freshness`
   - 是否触碰 `volatile-by-default`
2. `Write scope`
   - 是否会改动 canonical docs、state、task-local code、
     consumer-local extensions、shared append-only memory
3. `Coupling`
   - 当前任务是否高度依赖即时上下文和连续推理
4. `Parallelism value`
   - 是否真的存在可独立并行的问题分解
5. `Verification burden`
   - 是否需要 tests、checks、review、official docs、source note 才能成立
6. `Autonomy budget`
   - 是否已经定义 `max turns / iterations`、wall-clock timebox、
     tool / write budget、pause / cancel / kill semantics 之一

如果这 6 个维度里任何一项不清楚，不要先写实现。

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

默认 handoff 载荷应是最小必要、结构化、可审计的 capability packet，而不是 parent session transcript 的整包继承。

最小 packet 至少应包含：

1. bundle slug 或能力名
2. owned paths 或只读范围
3. output contract
4. write permission boundary
5. budget / stop boundary

不要默认继承：

1. full parent session transcript
2. full system prompt
3. 未经筛选的临时 scratch context

若 worker / subagent
会产出大体积、高保真
或结构化结果，
默认先写 task-local artifact，
再只回传 artifact path、
locator、content hash
或 concise summary；
不要让多级 coordinator
用 transcript 做
“口耳相传” copy chain。

只有当下一步明确被同一段上下文直接阻塞时，才升级为更厚的上下文传递，并显式说明原因。

如果当前 provider 不支持并行 delegation，则按同样原则顺序执行，不要强行模拟第二套控制面语义。

## Bounded Autonomy Rule

长任务、长循环、后台执行或 worker run，在启动前都必须先定义显式 budget / termination boundary。

至少要落下一项：

1. `max turns / iterations`
2. wall-clock timebox
3. tool budget 或 write budget
4. pause / cancel / kill semantics

如果这些边界还不清楚：

1. 不要直接开始长自治执行
2. 先补 task / recovery / delegation brief
3. 或先产出 reviewable artifact 再继续

## Resume / Wakeup Rule

`interrupt / resume`、后台 job 唤醒与 async callback
默认都按 checkpoint-relative 的边界理解，
不是 instruction-pointer continuation。

默认要求：

1. resume 后前置代码可能重跑，不要假设 exactly-once execution
2. 边界前的外部副作用必须具备 effect fence，例如 idempotency key、expected version、write intent，或被移到边界之后
3. webhook、queue、async callback 默认按 at-least-once delivery 设计，唤醒链路必须带 dedupe / idempotency 语义
4. 不要把活着的线程、socket、stream 当成跨 session 的 wakeup contract
5. 外部等待必须显式落成 wakeup handle + deadline 或 expiry 的 transition / recovery record，不把“稍后再看”只留在 prose
6. 审批、中断与 async callback 这类恢复点默认带 stable operation id 与 version marker；resume 按 ID 配对，不按显示顺序猜测
7. 若底层 protocol 已返回 `task object / background handle`，例如 `task_id`、poll interval、TTL / expiry、stream cursor、cancel handle，默认复用 receiver-generated handle，不在本地 transcript 外另造 shadow polling state

## Session Continuity Rule

provider / SDK continuation handle
只表示 transport / session continuity，
不等于 instruction continuity。

默认要求：

1. `system / developer / policy / prompt object /
   managed settings`
   默认要显式重放、重绑版本
   或重新注入
2. provider-native reasoning / compaction artifact
   若 provider 要求回传，
   默认只当 verbatim continuation payload，
   不手改、不解析成业务状态，
   不直接晋升为 canonical task truth
3. serialized app / agent / session context
   一旦随 checkpoint、thread、
   HITL pause 或 background job 持久化，
   就应按 persisted data 治理
4. 这类 persisted data
   必须带 schema / format version；
   跨版本恢复时要 migrate 或 fail closed
5. raw secret、raw credential、
   高敏感 token
   不应进入 serialized context；
   默认只保留可替换 handle、
   scope 与 expiry
6. provider background / pollable response
   若依赖 provider-side stored state
   才能轮询或恢复，
   这仍只是 transport state，
   不是 zero-retention truth；
   默认要显式看待 retention / privacy /
   ZDR 边界
7. subagent memory directory /
   project memory 若会自动注入上下文，
   或隐式放宽工具能力，
   就同时属于 instruction surface、
   persisted data 与 capability grant；
   真正影响恢复、acceptance
   或外部承诺的 durable fact
   仍必须回落到 task truth
   或正式 artifact

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

## Capability Grant Rule

`MCP roots`、OAuth audience / scope、tool allowlist、permission mode
这类会改变 capability grant 或 transport policy 的配置，
应优先落在 config、policy frontmatter 或 typed metadata。

其中 `MCP roots` 更像 attention / discovery scope + operational boundary，不是单独充分的安全边界；client / server 都应显式校验 root 暴露、变更与 path 映射，不把“能看到这个 root”误当成“这个路径就可安全访问”。

不要把这类 grant 藏在：

1. 自由文本 handoff
2. task prose
3. 临时聊天说明

默认要求：

1. 若目标是阻止副作用，默认使用 blocking preflight、tool wrapper 或外层 approval gate；不要把 input / output guardrail 或 parallel guardrail 当成唯一防线
2. guardrail coverage 必须按具体 pipeline 说明；handoff、hosted tool、built-in execution path 可能不走同一 guardrail 链路
3. `MCP OAuth` 默认按 audience-bound token 设计；client 在授权与 token 请求中显式带 `resource`，server 不得把 client token passthrough 给上游 API
4. `roots/list` 等 server-to-client discovery request 只属于 request scope，不自动升级为 durable capability grant 或更宽的 trust boundary
5. 敏感授权默认优先 host-managed auth 或 out-of-band elicitation，而不是把 bearer token 继续透传给上游服务

## Worktree Rules

遵守 `one-thread-one-worktree`，但不要把每个并行执行单元都升级成独立 worktree。

默认：

1. 同一主线程内的只读探索或轻量 sidecar，不必新建 worktree
2. 存在真实并行写入、长回合实现、或独立实验分支时，才新建 worktree
3. 多个并行写线程不能共享同一 worktree
4. canonical source docs 与 provider adapter 目录默认属于高敏感写入面，应谨慎授权

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
6. 慢速 human review / approval / feedback 默认转成
   `paused + interrupt metadata + formal resume transition`，
   不把任务留在隐藏等待态里
7. durable checkpoint 或 serialized runtime support state
   默认必须带显式 schema / format version，
   跨代码版本恢复要 migrate 或 fail closed

不要：

1. 手工 patch `.harness/tasks/*/task.md` 或任何 shared projection 文件来伪造状态迁移
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
   - tests、contracts、schema checks、audits、freshness gate、review 是否通过
2. `trace-level`
   - decision、tool calls、handoff、retry、interrupt、budget hit / stop reason 是否可解释、可回放
3. `state-level`
   - transitions、locks、writeback、derived views 是否满足 runtime contract

默认顺序应是：

1. 先跑 deterministic / code-graded gate
2. 再看 trace grading 或 LLM-graded eval

后者主要服务 diagnosis、回归趋势与轨迹质量判断，不替代 deterministic gate、approval gate 与 human review。

对 tool-using agent，
尽量把评估拆成至少三项：

1. end-state 是否正确
2. tool choice 是否合理
3. argument correctness /
   schema fit 是否正确

不要把这些失败模式
全压成一个 holistic 分数。

除非工具顺序、审批路径或协议交互本身就是 contract，默认不要把 exact trajectory / exact tool sequence 当成硬通过条件；更应检查 end-state、safety invariant、required evidence 与 bounded tool correctness，多组件任务可保留 partial credit。

如果 grader 结论与 deterministic gate 冲突，以显式 contract 与可重复 gate 为准。

对 eval / replay slice：

1. eval bootstrap
   先用 20-50 个来自真实失败、
   真实工单或代表性边界条件的 case
   立起 capability slice，
   不要一开始就追求大而全
2. 每次 trial 默认从干净、隔离环境启动，
   不让 cache、残留文件、
   历史 git 状态或共享资源抖动
   污染结果
3. capability eval 与 regression eval
   默认分层；
   成熟 capability case
   再晋升为 regression sample

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
