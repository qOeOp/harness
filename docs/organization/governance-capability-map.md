# Governance Capability Map

更新日期：`2026-03-28`

## 目的

把 `root / skills / roles / workstreams` 的关系讲清楚，避免把能力、责任主体和协作投影混成一层。

## Core Model

`harness` 不是一棵单树，而是两套正交结构：

1. 协作投影
   - `company -> optional workstream -> role -> agent instance`
2. 能力图
   - `skills/*` 被多个 role 横向复用

## Canonical Layering

### Root

root 是宪法层、共享底座和总入口。

它负责：

1. `SKILL.md`
   - 总路由、总入口、root-level mental model
2. `docs/`
   - 全局 workflow、组织结构、操作规则
3. `references/`
   - contracts、specs、长期 canonical truth
4. `roles/`
   - baseline role definitions
5. `scripts/`
   - 共享基础设施与高层控制入口

它不负责：

1. 承载单个 capability 的专用 templates / refs / scripts
2. 镜像一套与 `skills/*` 重复的 capability surface

### Skills

`skills/*` 是能力实体。

每个 skill 应尽量自包含：

1. `SKILL.md`
2. `manifest.toml`
3. `refs/`
4. `templates/`
5. `scripts/`
6. `evals/` if needed

如果某份 template / ref / script 只服务一个 skill，就不应放回 root。

### Roles

`roles/*` 是责任主体，而不是能力包。

一个 role：

1. 对某类结果负责
2. 默认会消费多种 skill
3. 不应和某个单 skill 一一绑定

### Workstreams

workstream 是 cross-task coordination projection，而不是 source repo 的默认内置目录树。

默认 baseline 仍然是 task / role / capability。

只有在 `advanced governance mode` 的 consumer runtime 中，才按需 materialize runtime-local workstreams / roles。

## Skill Taxonomy

当前 skills 更适合按治理能力分组，而不是硬排成一条线性流程。

### Intake And Framing

1. `founder-brief`
2. `meeting-router`
3. `brainstorming-session`
4. `vision-meeting`

### Discovery And Evidence

1. `research`
2. `capability-scout`

### Scope And Decision

1. `requirements-meeting`
2. `decision-pack`
3. `acceptance-review`

### Memory And Writeback

1. `memory-checkpoint`
2. `daily-digest`

### Governance And Compounding

1. `governance-meeting`
2. `process-audit`
3. `os-audit`
4. `retro`

## Baseline Roles And Default Skill Affinities

这些不是硬权限，而是默认 affinity。

| Baseline Role | Default Skills |
| --- | --- |
| `general-manager` | `founder-brief`, `meeting-router`, `decision-pack`, `research` |
| `product-thesis-lead` | `vision-meeting`, `requirements-meeting`, `brainstorming-session`, `research` |
| `knowledge-memory-lead` | `research`, `memory-checkpoint`, `daily-digest`, `decision-pack` |
| `workflow-automation-lead` | `capability-scout`, `research`, `os-audit`, `process-audit` |
| `risk-quality-lead` | `acceptance-review`, `decision-pack`, `research` |
| `compounding-engineering-lead` | `retro`, `process-audit`, `governance-meeting`, `capability-scout`, `os-audit` |
| `runtime-role-manager` | no primary skill bundle; executes policy-governed runtime role mutation |

## Suggested Runtime Workstream Families

这些是常见 family，不是 source repo 的 built-in workstream truth。

| Runtime Workstream Family | Typical Runtime Roles | Typical Skills |
| --- | --- | --- |
| `product-discovery` | researcher, BA, product manager | `research`, `brainstorming-session`, `vision-meeting`, `requirements-meeting` |
| `delivery` | frontend engineer, backend engineer, integration engineer | consumes project/domain skills plus `decision-pack` and `memory-checkpoint` as needed |
| `quality` | reviewer, tester, acceptance owner | `acceptance-review`, `research`, `process-audit` |
| `memory-ops` | memory steward, documentation operator | `memory-checkpoint`, `daily-digest`, `research` |
| `automation-enablement` | workflow operator, tooling/platform owner | `capability-scout`, `os-audit`, `process-audit` |

## Design Rules

1. root 越高层越简洁，skills 越低层越自包含
2. skill 粒度应小于 role，role 粒度应小于 workstream projection
3. 组织结构是树，能力结构是图
4. 不要把某个 runtime-local workstream 误写成 source repo baseline truth
5. 不要把单个 role 和单个 skill 永久绑定成同义词
