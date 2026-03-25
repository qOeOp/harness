# Canonical Roles

更新日期：`2026-03-24`

## 目的

本目录是公司 OS 的 canonical agent / role source。

这里定义：

1. 角色 slug
2. Claude projection metadata
3. Codex projection metadata
4. 角色的 canonical instructions

provider-specific files 只是投影，不再手工双写正文。

## 文件格式

每个 role 文件使用统一 `frontmatter v1`：

1. YAML frontmatter metadata
2. `## Canonical Instructions` 正文

固定 metadata keys：

- `schema_version`
- `slug`
- `claude_file`
- `claude_name`
- `claude_description`
- `claude_tools`
- `claude_model`
- `codex_file`
- `codex_name`
- `codex_description`
- `codex_model`
- `codex_reasoning_effort`
- `codex_sandbox_mode`
- `codex_nicknames`

其中：

1. `slug` 是 canonical role identity
2. `claude_*` 和 `codex_*` 只承载最小 projection metadata
3. role 语义、边界、must-read 和 volatile 默认动作都应写在 `## Canonical Instructions`

## Projection Rules

1. Claude projection 输出到 `.claude/agents/*.md`
2. Codex projection 输出到 `.codex/agents/*.toml`
3. Gemini 当前不默认投影 agent files
4. 任何 provider projection 都必须由脚本生成，不手工维护

同步命令：

```bash
./.agents/skills/harness/scripts/sync_agent_projections.sh
```

专门审计命令：

```bash
./.agents/skills/harness/scripts/audit_role_schema.sh
```

初始化新 role：

```bash
./.agents/skills/harness/scripts/new_role.sh --print-template

./.agents/skills/harness/scripts/new_role.sh \
  --slug example-lead \
  --claude-description "Claude-facing description" \
  --codex-description "Codex-facing description"
```

推荐先用这份模板准备参数：

```bash
cat docs/templates/role-design-brief.md
```

或直接：

```bash
./.agents/skills/harness/scripts/new_role.sh --print-template
```

然后再初始化 canonical role：

```bash
./.agents/skills/harness/scripts/new_role.sh \
  --slug example-lead \
  --claude-description "Claude-facing description" \
  --codex-description "Codex-facing description"
```

推荐工作流：

1. 先由 LLM 或人工填写 `Role Design Brief`
2. 再用 `new_role.sh` 初始化 canonical role
3. 如有需要，补全 `## Canonical Instructions`
4. 脚本默认会自动同步 projections 并跑 `audit_role_schema.sh`

编辑已有 role：

```bash
./.agents/skills/harness/scripts/edit_role.sh --slug workflow-automation-lead --print-current

./.agents/skills/harness/scripts/edit_role.sh \
  --slug workflow-automation-lead \
  --claude-description "Updated Claude-facing description" \
  --codex-description "Updated Codex-facing description"
```

`edit_role.sh` 只改 canonical role，并默认自动同步 projections 与 role audit。

## 边界

1. canonical role source 定义角色语义与 projection metadata
2. provider-specific delta 继续放在 `docs/workflows/provider-deltas/`
3. 若未来建立 Gemini agent projection，先更新 canonical role source 和同步脚本，再启用 `.gemini/agents/`
