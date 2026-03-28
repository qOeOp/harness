# Tool Adapter Capability Map

更新日期：`2026-03-28`

## 目的

定义 `harness` framework source 在 Claude / Codex / Gemini 之间的统一语义层与 provider-specific adapter 边界。

## Canonical Capability Surface

只有以下两类对象属于 `harness` execution substrate 的 canonical capability layer：

1. `agents`
   - 表示稳定角色、职责边界与可并行执行单元
   - canonical contract 是 `roles/` 下的角色 slug、职责语义与 canonical instructions，而不是某个 provider 的文件格式
2. `skills`
   - 表示可复用、可渐进披露的能力包
   - canonical source 当前收敛为 `skills/`

补充约束：

1. consumer repo 的 `AGENTS.md / CLAUDE.md / GEMINI.md` 与 `.claude/ / .codex/ / .gemini/` 属于 user-owned/provider-owned surface，harness 不生成、不修改、不校验
2. 真正硬约束下沉到 `scripts/`、audit、CI、tool permissions 与 canonical docs
3. 任何关键能力都不能只活在某个 provider 的 `command` 或 `hook` 里
4. consumer runtime 的名字路由 / 地址簿同样属于 user-owned integration，不属于 runtime contract

## Adapter-Only Surface

以下对象允许存在，但不属于 canonical capability surface：

1. `commands`
   - 只是 UX alias / trigger shortcut
   - 不允许承载独立业务逻辑
2. `hooks`
   - 只是 lifecycle automation / event guardrail
   - 不允许成为唯一 source of truth
3. provider config
   - 例如 `.claude/settings.json`、`.codex/config.toml`、`.gemini/settings.json`

## Adapter Rules

新能力默认按以下顺序设计：

1. 先判断它是不是 `skill`
2. 再判断是否需要一个 `agent` 角色长期持有这类职责
3. 若只是为了更快触发，再加 `command` alias
4. 若确实需要事件驱动自动拦截或自动注入，再加 `hook`
5. 若没有 deterministic script / audit backing，不允许只靠 hook 实现关键控制

## Provider Boundary Matrix

| Surface | Canonical meaning | Claude | Codex | Gemini | 当前仓库策略 |
| --- | --- | --- | --- | --- | --- |
| Root entry | user/provider-owned routing memory | optional | optional | optional | harness 不接管 |
| Skills | reusable capability packages | provider may discover user-installed skill | provider may discover user-installed skill | provider may discover user-installed skill | `skills/` 为 canonical source；安装位置不属于 runtime contract |
| Agents | role / execution units | provider-owned | provider-owned | provider-owned | `roles/` 为 canonical source；不维护 repo-local provider mirrors |
| Commands | UX alias only | 可选 | 可选 | 可选 | 不再视为一等层 |
| Hooks | event automation only | 可选，能力最强 | 当前公开面未见同级 project-local hooks | 可选 | 不再视为一等层 |
| Scripts / audits | deterministic enforcement | 通用 | 通用 | 通用 | execution substrate 真正硬控制面 |

## Current Repository Read

截至 `2026-03-25`，当前 source repo 的真实状态是：

1. `skills/` 是 canonical skill layer
2. `roles/` 是 canonical agent / role layer
3. consumer runtime 只拥有 `.harness/`
4. skill 如何安装、provider 如何发现，是 user-owned integration 问题，不属于 runtime contract
5. Gemini custom subagents 仍是 experimental，因此更不应写成默认投影面

因此本轮设计不是追求“文件数量对称”，而是追求：

`canonical meaning 对称 + adapter 厚度诚实`

## Migration Rules

1. 新增能力时，先落 `skills/`，不要先写 provider-specific command
2. 新增 source baseline role 时，先落 `roles/`；新增 consumer runtime role 时，写到 `.harness/workspace/roles/`，都不要先写 provider-specific agent file
3. consumer repo 的 provider 文件一律视为 user-owned；harness 不得写入
4. 现有 `commands` 若只是调用 skill，应在后续迁移中优先删除
5. 现有 `hooks` 若只是注入提醒，应优先迁移到 canonical docs、skills、scripts 或 audit
6. 只有在 provider-specific hook 明显带来事件级确定性收益时，才继续保留

## 禁止事项

1. 不要把 `commands` 写成第二套 workflow 真相
2. 不要把 `hooks` 写成唯一规则来源
3. 不要为了追求三家表面对称而复制无意义配置
4. 不要把 provider-specific 原语误写成 `harness` 的基础概念
