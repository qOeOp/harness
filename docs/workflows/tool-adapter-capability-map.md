# Tool Adapter Capability Map

更新日期：`2026-03-24`

## 目的

定义公司 OS 在 Claude / Codex / Gemini 之间的统一语义层与 provider-specific adapter 边界。

## Canonical Capability Surface

只有以下两类对象属于公司 OS 的一等能力层：

1. `agents`
   - 表示稳定角色、职责边界与可并行执行单元
   - canonical contract 是 `.agents/skills/harness/roles/` 下的角色 slug、职责语义与 canonical instructions，而不是某个 provider 的文件格式
2. `skills`
   - 表示可复用、可渐进披露的能力包
   - canonical source 当前收敛为 `.agents/skills/harness/skills/`

补充约束：

1. 根 `AGENTS.md / CLAUDE.md / GEMINI.md` 只负责 routing，不属于 capability layer
2. 真正硬约束下沉到 `.agents/skills/harness/scripts/`、audit、CI、tool permissions 与 canonical docs
3. 任何关键能力都不能只活在某个 provider 的 `command` 或 `hook` 里

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

## Projection Rules

新能力默认按以下顺序设计：

1. 先判断它是不是 `skill`
2. 再判断是否需要一个 `agent` 角色长期持有这类职责
3. 若只是为了更快触发，再加 `command` alias
4. 若确实需要事件驱动自动拦截或自动注入，再加 `hook`
5. 若没有 deterministic script / audit backing，不允许只靠 hook 实现关键控制

## Provider Projection Matrix

| Surface | Canonical meaning | Claude | Codex | Gemini | 当前仓库策略 |
| --- | --- | --- | --- | --- | --- |
| Root entry | routing only | `CLAUDE.md` redirect | `AGENTS.md` redirect | `GEMINI.md` redirect | 同义镜像 |
| Skills | reusable capability packages | `.claude/skills/` generated projection | 直接消费 `.agents/skills/harness/skills/` | 直接消费 `.agents/skills/harness/skills/` 官方 workspace alias | `.agents/skills/harness/skills/` 为 canonical source；Claude projection 由 `./.agents/skills/harness/scripts/sync_claude_skill_projections.sh` 生成；Codex 与 Gemini 直接消费 canonical |
| Agents | role / execution units | `.claude/agents/*.md` generated projection | `.codex/agents/*.toml` generated projection | `.gemini/agents/*.md`（experimental） | `.agents/skills/harness/roles/` 为 canonical source；Claude/Codex 由 `./.agents/skills/harness/scripts/sync_agent_projections.sh` 生成；Gemini 暂不投影 |
| Commands | UX alias only | 可选 | 可选 | 可选 | 不再视为一等层 |
| Hooks | event automation only | 可选，能力最强 | 当前公开面未见同级 project-local hooks | 可选 | 不再视为一等层 |
| Scripts / audits | deterministic enforcement | 通用 | 通用 | 通用 | 公司 OS 真正硬控制面 |

## Current Repository Read

截至 `2026-03-24`，当前仓库的真实状态是：

1. `.agents/skills/harness/skills/` 是 canonical skill layer
2. `.agents/skills/harness/roles/` 是 canonical agent / role layer
3. `.claude/skills/` 现在只保留从 canonical skill 派生的 projection wrappers
4. `.claude/agents/` 与 `.codex/agents/` 现在都应视为 generated projections，而不是手工正文
5. `.gemini/` 当前只保留 `settings.json` 这类协议入口；workspace skills 直接通过 Gemini 官方支持的 `.agents/skills/harness/skills/` alias 被发现
6. Gemini custom subagents 当前仍是 experimental，且项目级目录是 `.gemini/agents/*.md`；当前虽然已有 `.agents/skills/harness/roles/` canonical source，但 Gemini 仍未进入默认执行面，因此这层暂不默认投影

因此本轮设计不是追求“文件数量对称”，而是追求：

`canonical meaning 对称 + adapter 厚度诚实`

## Migration Rules

1. 新增能力时，先落 `.agents/skills/harness/skills/`，不要先写 provider-specific command
2. 新增 agent role 时，先落 `.agents/skills/harness/roles/`，不要先写 provider-specific agent file
3. Claude/Codex agent projection 通过脚本同步，不再手工双写 agent 正文
4. Claude skill projection 通过脚本同步，不再手工双写 skill 正文
5. Gemini 默认不新增 `.gemini/skills/` projection；只有在未来确实需要 provider-specific metadata，或官方 alias 行为变化时，才单独补 adapter
6. Gemini 默认也不新增 `.gemini/agents/` projection；只有当 Gemini 成为真实执行面且值得启用 experimental subagents 时，才补这层 adapter
7. 现有 `commands` 若只是调用 skill，应在后续迁移中优先删除
8. 现有 `hooks` 若只是注入提醒，应优先迁移到 canonical docs、skills、scripts 或 audit
9. 只有在 provider-specific hook 明显带来事件级确定性收益时，才继续保留

## 禁止事项

1. 不要把 `commands` 写成第二套 workflow 真相
2. 不要把 `hooks` 写成唯一规则来源
3. 不要为了追求三家表面对称而复制无意义配置
4. 不要把 provider-specific 原语误写成公司 OS 的基础概念
