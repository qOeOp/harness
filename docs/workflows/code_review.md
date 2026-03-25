# Code Review

## Purpose

本文件定义仓库级、agent-neutral 的 code review contract。

适用于：

1. human reviewer
2. Codex
3. Claude
4. Gemini
5. 仓库内任何 review skill、command、subagent topology

本文件定义 review standard，不定义 provider-specific orchestration。

## Review Objective

默认 review mode 是 risk-first review。

优先关注：

1. correctness
2. behavioral regression
3. state and data integrity
4. security and trust boundary
5. verification gap
6. maintainability risk

不优先关注：

1. style-only commentary
2. 无明确用户或系统影响的偏好争论
3. 没有 plausible failure path 的纯猜测性担忧

## Scope

本 contract 适用于：

1. pull request review
2. pre-merge review
3. self-review before handoff
4. review of agent-generated patches
5. governance / state-system code review

本 contract 不替代：

1. implementation planning
2. product direction debate
3. architecture decision record
4. provider-specific review workflow

## Review Severity

### P0

必须阻断的问题，可能导致：

1. security exposure
2. destructive data or state corruption
3. irreversible workflow damage
4. primary execution path broken
5. false canonical writeback
6. unsafe permission expansion

### P1

高概率在真实路径上造成严重影响的问题，例如：

1. realistic path 上的 incorrect behavior
2. recovery / resume path broken
3. invalid state transition
4. 高风险操作缺少必要 protection
5. 应当阻断 merge 的明显 regression

### P2

重要但不必然阻断的问题，例如：

1. edge-case correctness gap
2. 重要路径上的 test or verification gap
3. 近中期可能制造 defect 的 maintainability issue
4. 容易造成 operator mistake 的行为或边界不清

### P3

低风险改进项，例如：

1. clarity improvement
2. local cleanup with low regression risk
3. non-critical consistency improvement

## Review Dimensions

按改动范围和受影响路径动态激活相关维度，不要求每次 review 平均覆盖所有维度。

### 1. Correctness And Behavioral Regression

检查：

1. 实现是否真的匹配宣称行为
2. 现有路径是否发生 silent behavior change
3. edge case 和 error handling 是否被破坏
4. 新引入的 assumption 是否有明确 enforcement

### 2. State And Data Integrity

检查：

1. state mutation 是否 explicit、versioned、recoverable
2. append-only rule 是否被破坏
3. transition、cleanup、writeback 是否仍然一致
4. 是否可能制造 stale、partial、contradictory state

### 3. Security And Trust Boundary

检查：

1. permission 是否扩大
2. dangerous command 或 data access 是否更易误用
3. secret、credential、sensitive path 是否被暴露
4. trust boundary 是否仍然 explicit、reviewable

### 4. Performance, Concurrency, And Recovery Risk

检查：

1. 是否引入明显 performance 或 scaling hotspot
2. concurrent 或 repeated execution 是否会破坏 correctness
3. retry 是否安全
4. interrupt、resume、recovery 行为是否仍然成立

### 5. Verification And Observability

检查：

1. 是否有足够 test、check 或其他 validation
2. failure 是否可检测
3. log、artifact、evidence 是否足够定位问题
4. 作者声称的 verification 是否真的覆盖变更路径

### 6. Maintainability, Boundaries, And Operator Clarity

检查：

1. responsibility 是否保持清晰分离
2. naming 和 module boundary 是否仍然精确
3. 是否提高未来出错概率
4. operator-facing behavior 或文档是否需要同步更新

## Evidence Standard

每条 finding 应尽量包含：

1. issue 在哪里
2. 为什么这是一个真实风险
3. 会触发什么 failure mode
4. 证据是什么
5. 哪种 fix direction 或 validation 可以降低不确定性

优先：

1. concrete file reference
2. execution-path reasoning
3. practical reproduction step
4. test、script、official doc 引用

避免：

1. 模糊不适感
2. 纯 style opinion
3. 没有 plausible impact path 的空泛担忧

## Blocking Rules

出现以下任一情况，应 request changes 或 block：

1. 存在 unresolved P0 或 P1
2. behavior-changing patch 缺少足够 verification
3. state mutation 或 transition 变更缺少 integrity / recovery confidence
4. permission、trust-boundary、destructive operation 变更缺少 explicit rationale
5. canonical 或 founder-facing artifact 宣称已验证，但证据不足
6. reviewer 无法识别真实受影响路径，因为 patch 或上下文不完整

## Output Format

默认输出顺序：

1. findings，按 severity 排序
2. open questions or assumptions
3. residual risk or testing gap
4. brief summary，仅在有价值时提供

如果没有 findings：

1. 必须明确说 no findings
2. 若仍有 residual risk 或 verification limit，也必须显式说明

## What Reviewers Should Not Do

不要：

1. 在 code review 中重写 product scope
2. 不给 concrete failure risk 就要求 architecture rewrite
3. 因 style-only preference 阻断变更
4. 在 evidence 不足时伪装成确定性判断
5. 把 tool-specific workflow preference 写成 repo-wide standard

## Deliberately Not Defined Here

本文件刻意不定义：

1. 应该 spawn 多少 subagent
2. review 应该 sequential 还是 parallel
3. provider-specific command、hook、slash command
4. MCP server topology
5. file ownership or delegation topology

这些属于 operator playbook 和 provider adapter layer，而不是 canonical review contract。
