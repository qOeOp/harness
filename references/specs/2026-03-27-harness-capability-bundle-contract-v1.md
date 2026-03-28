# Harness Capability Bundle Contract v1

- Status: proposed
- Date: 2026-03-27
- Scope: define a capability-bundle model for `harness` so that instructions, templates, references, and task-specific scripts can be packaged as one bounded capability without turning every capability into a permanent agent identity
- Related:
  - [references/layering.md](../../references/layering.md)
  - [references/runtime-workspace.md](../../references/runtime-workspace.md)
  - [references/top-level-surface.md](../../references/top-level-surface.md)
  - [docs/project-structure.md](../../docs/project-structure.md)
  - [docs/workflows/agent-operator-contract.md](../../docs/workflows/agent-operator-contract.md)
  - [roles/README.md](../../roles/README.md)
  - [references/contracts/capability-bundle-manifest-v1.toml](../../references/contracts/capability-bundle-manifest-v1.toml)

## Problem Statement

当前 `harness` 已经明确把 source repo 分成：

1. `skills/`
2. `roles/`
3. `docs/`
4. `scripts/`
5. `references/`

这保证了制度、执行器、合同与运行时真相的边界清晰，但也带来一个实际问题：

同一能力的说明、模板、脚本、参考材料往往分散在多个目录里。

结果是：

1. 能力发现成本偏高
2. 能力边界不够实体化
3. agent 在执行时更容易过早读入无关上下文
4. 并行委派时缺少稳定的 capability-level contract

## Divergent Hypotheses

### Hypothesis A: Keep Flat Surfaces

继续保持今天的结构：

1. `skills/` 只做入口说明
2. `docs/` 放所有模板和 workflow
3. `scripts/` 放所有执行器
4. 调度器自行拼接上下文

优点：

1. 迁移成本最低
2. 共享脚本容易复用

缺点：

1. 能力不成形
2. 路由需要跨目录追踪
3. 很难形成 capability-level 权限与输出契约

### Hypothesis B: One Capability = One Permanent Agent

把每个能力做成一个完整 agent 实体：

1. agent prompt
2. 绑定工具
3. 绑定模板
4. 绑定脚本
5. agent 自己承接上下文和结果

优点：

1. 实体感最强
2. 隔离感最强

缺点：

1. 把“能力”和“身份”耦合在一起
2. 容易长出过多 agent / role
3. 评估、授权、版本化成本快速上升
4. 任务状态容易滑回 agent 私有上下文，而不是外置 artifact

### Hypothesis C: One Capability = One Bundle, Agent Is Runtime

把一个能力打包成 `capability bundle`：

1. `SKILL.md` 作为 capability overview
2. `manifest.toml` 作为机读 contract
3. `refs/` 放细节参考
4. `templates/` 放正式模板
5. `scripts/` 放 capability-local executors
6. `evals/` 放 smoke cases 与 failure modes

agent 不再是 capability 的持久身份，而是按任务动态加载 bundle 的运行时实例。

优点：

1. 保留实体化能力边界
2. 不把状态塞回 agent
3. 更容易做按需加载与并行委派
4. 更符合 source repo / runtime 分层

缺点：

1. 需要新 contract
2. 需要逐步迁移现有 skill 与 docs 引用

## First Principles Deconstruction

先去掉行业比喻，只保留最硬的约束。

### User Need

用户真正要的不是“目录像面向对象”。

用户真正要的是：

1. 某项能力能被快速发现
2. 某项能力的边界足够清晰
3. 执行该能力时尽量少污染主上下文
4. 结果能稳定写回外部系统，而不是留在聊天里
5. 必要时能安全并发

### Logical Constraints

1. `harness` 已明确区分 source repo 与 `.harness/` runtime；不能把运行时真相重新塞回 source repo 或 agent 私有记忆
2. `role` 在本系统中承载的是 identity、policy、stage 与 write boundary，不应被每个能力重复复制
3. 并发只有在 `write scope` 清楚、owned paths 清楚、结果 contract 清楚时才成立
4. tool 调用与脚本执行应尽量让大体量结果落盘，再返回轻引用，而不是把大块文本搬进主上下文
5. provider-specific subagent syntax 不应成为 canonical contract
6. 默认 handoff 必须是最小必要、结构化、可审计的
   capability packet，而不是 full parent transcript 的整包继承
7. 长任务与 worker run 必须带显式 budget / termination boundary，
   不能把“模型自己会停”当成 contract

### Non-Negotiable Truths

1. 状态应外置到 `.harness/tasks/*/task.md` 与 task-local artifacts
2. 能力边界应可机读，不应只靠 prose
3. agent identity 与 capability definition 必须分离
4. 主线程默认仍应 local-first
5. 并发是优化手段，不是默认产品语义

## Instruction vs Enforcement Boundary

`SKILL.md`、bundle-local prompt 片段、
router metadata 与 prompt object
属于 capability 的 steerability surface。

这意味着：

1. 它们会改变默认行为，因此必须 versioned、可 review
2. 但它们本身不是自动获得最高优先级的 enforced policy channel
3. 若某条规则的违规成本高，
   必须继续下沉到 managed policy、tool approval、
   allowlist、typed schema 或 wrapper 检查

## Remote Bundle Trust Boundary

`remote / marketplace / user-supplied skill`
默认先视为潜在不可信的
instruction + code surface。

这意味着：

1. 未经过 curate / review / version pin 前，
   不应进入 executable catalog
2. provider 能发现、
   或终端用户可选，
   不等于 repo 的 security baseline
3. 评估 external bundle 时，
   默认先把它当 research / pilot 输入，
   而不是直接 promote 成 canonical capability surface

## Convergence to Excellence

基于以上约束，收敛结论如下：

1. 拒绝 `Hypothesis A`
   - 因为它解决不了“能力不成形”的核心问题
2. 拒绝 `Hypothesis B`
   - 因为它过度绑定 capability 与 agent identity，会把系统推向 role/agent 爆炸
3. 接受 `Hypothesis C`
   - capability 做实体
   - agent 做运行时
   - state 做外置 artifact

这也是本 contract 的核心判断：

`最佳设计不是“每个能力一个永久 agent”，而是“每个能力一个 bundle，agent 按需加载 bundle 并在必要时派生 worker”。`

## Challenge to the Naive Agent-Per-Capability Model

以下直觉应被明确挑战：

`执行特定任务就是派特定 agent。`

这条规则只有在以下条件同时成立时才应触发：

1. 任务可清楚切成独立子问题
2. 输出 contract 明确
3. 写入范围互不冲突
4. 并行收益高于协调成本

默认情况下，更稳的执行顺序应是：

1. 主线程识别任务
2. 加载相关 capability bundle
3. 本地执行或调用 bundle 脚本
4. 只有在 sidecar research、并行验证、或 owned path 局部实现时才派 worker agent

## Canonical Entity Model

系统内四个概念必须分开：

1. `role`
   - 身份、权限、stage、policy
2. `capability bundle`
   - 某个能力的 instructions、templates、refs、scripts、evals
3. `agent instance`
   - 某次任务中的执行单元，可为主线程或 worker
4. `task record`
   - `.harness/tasks/<task-id>/task.md` 与其附件，承载正式状态与产物

## Canonical Bundle Layout

source repo 内，一个 capability bundle 的推荐形态：

```text
skills/<bundle-slug>/
  SKILL.md
  manifest.toml
  refs/
  templates/
  scripts/
  evals/
```

规则：

1. `SKILL.md`
   - 面向 agent 的 capability overview
   - 只保留高信号 routing、when-to-use、read-order、output expectation
2. `manifest.toml`
   - capability 的机读 contract
   - 记录边界、权限、默认产物、入口与委派策略
3. `refs/`
   - capability-specific workflow、background、rubric
4. `templates/`
   - capability-specific artifact templates
5. `scripts/`
   - capability-specific executors 或 thin wrappers
6. `evals/`
   - smoke cases、failure modes、acceptance checks

## Loading Model

capability bundle 的 canonical loading 顺序：

1. 先读 `manifest.toml`
2. 再读 `SKILL.md`
3. 只在确实需要时读 `refs/`、`templates/`、`evals/`
4. 只在需要执行时调用 `scripts/`

默认不应：

1. 一开始递归读完整个 bundle
2. 把脚本源码整段塞进上下文
3. 把历史输出粘贴回主线程上下文

## Execution Model

默认模式：

1. 单主线程 agent
2. 动态加载一个或多个 capability bundle
3. 结果优先写入 task-local artifacts
4. 聊天中只保留摘要、路径、结构化结果

并发模式：

1. 主线程是 manager
2. worker agent 不是 capability 本体，只是 capability 的运行时执行者
3. worker 接收：
   - bundle slug
   - owned files 或只读范围
   - output contract
   - write permission boundary
   - budget / stop boundary
4. worker 返回：
   - concise summary
   - artifact path
   - 或结构化结果

默认不应传给 worker：

1. full parent session transcript
2. full system prompt
3. 未裁剪的临时 scratch context

只有在下一步明确被同一段上下文直接阻塞时，才升级成更厚的上下文继承，并在 handoff 中说明理由。

## Budget / Termination Boundary

capability bundle 允许自治执行，但不允许无界自治。

默认要求：

1. 长任务至少声明一项 `max turns / iterations`、wall-clock timebox、tool / write budget、pause / cancel / kill semantics
2. budget 命中、cancel、kill、timebox 触发，
   必须写回 task history、recovery 或 reviewable artifact
3. 预算信息服务 control surface，不应只藏在聊天里

## Writeback Model

capability bundle 不拥有长期状态。

正式 writeback 只能进入：

1. `.harness/tasks/<task-id>/task.md`
2. `.harness/tasks/<task-id>/attachments/`
3. `.harness/tasks/<task-id>/closure/`
4. 明确允许的 `.harness/workspace/*`
5. 被 policy 允许的 source repo path

bundle 只能声明默认写入根，不能私自扩张 write roots。

补充边界：

1. 若 bundle 运行需要 cache、tool home、isolated adapter env 一类 operational support state，
   可以把 `.harness/runtime/*` 作为显式 write root
2. 这类 support root 不是 canonical task truth，也不是默认 artifact path
3. `default_artifact_path` 仍应指向 task-local artifact 或显式允许的共享写回面

## Example Manifest

```toml
schema_version = 1
bundle_slug = "research"
bundle_version = 1
bundle_kind = "task-skill"
summary = "Route volatile research work into dispatch and memo outputs."
owner_role = "knowledge-memory-lead"
scope = "source-baseline"
maturity = "stable"
context_strategy = "artifact-first"
delegation_mode = "manager-optional"

entrypoints = ["chat", "work-item"]
activation_modes = ["explicit", "router"]
allowed_tools = ["read", "write", "shell", "web"]
read_roots = ["skills/research/", "references/"]
write_roots = [".harness/tasks/<task-id>/attachments/", ".harness/runtime/research/"]
forbidden_roots = ["roles/", ".harness/workspace/roles/"]
output_modes = ["artifact-path", "summary"]
default_artifact_type = "research-dispatch"
default_artifact_path = ".harness/tasks/<task-id>/attachments/"
lazy_load_paths = ["refs/", "templates/", "scripts/"]
operation_modes = ["dispatch", "memo"]
```

## Migration Guidance

迁移应按能力逐个进行，而不是一次性重排全仓库。

推荐顺序：

1. 先挑高价值、高频、边界清楚的 skill
2. 为其补 `manifest.toml`
3. 把强耦合模板迁到 bundle-local `templates/`
4. 把强耦合补充文档迁到 bundle-local `refs/`
5. 保留通用模板和共享 shell lib 在全局层

## Compatibility Shim Rule

兼容 shim 只允许作为迁移期的短暂过渡层。

规则：

1. canonical 顶层 skill 只能有一个 bundle 入口
2. `dispatch`、`memo`、`review` 这类 operation mode 不应长期占据独立顶层 skill 名称
3. 一旦活跃文档、脚本、校验已改到 canonical bundle 语义，旧 shim 必须删除
4. 不允许把迁移期 shim 长期包装成与 canonical bundle 并列的一等 skill

## What Should Stay Global

以下内容仍应保持全局，不应被 capability bundle 私有化：

1. `scripts/lib_*.sh`
   - 共享 shell 基础设施
2. `scripts/work_item_ctl.sh`
   - 高层状态入口
3. `roles/`
   - baseline role definitions
4. `references/contracts/`
   - 全局 contract truth
5. `docs/workflows/provider-deltas/`
   - provider-specific delta

## Non-Goals

1. 不把每个 capability 变成永久 agent 身份
2. 不在 source repo 中保存运行时私有状态
3. 不强制每个 bundle 都有独立 role
4. 不把 provider-specific subagent config 当成 canonical contract
5. 不把“并发”当成默认语义

## Acceptance Criteria

本 contract 只有在满足以下条件时才算成功：

1. 新 capability 能以单目录表达其局部边界
2. agent 可以先读 manifest，再按需加载其余内容
3. 大输出可以外置到 artifact，而不是堆积到主上下文
4. 并发委派可以只传递 bundle ref 和 output contract
5. role、bundle、agent instance、task record 四者边界保持清晰
