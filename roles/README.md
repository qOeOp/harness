# Canonical Roles

更新日期：`2026-03-27`

## 目的

本目录只保存 `harness` 自身的默认项目管理 / 治理团队基线。

当前内置角色：

1. `general-manager`
2. `product-thesis-lead`
3. `knowledge-memory-lead`
4. `workflow-automation-lead`
5. `risk-quality-lead`
6. `compounding-engineering-lead`
7. `runtime-role-manager`

任何用户域、行业域、项目域的专属角色都不应写入这个 source repo。
如果某个 consumer repo 在复利 review 后证明需要新增角色，应把它创建到：

`/.harness/workspace/roles/`

而不是回写到本仓库。

## Roles Are Not Skills

`roles/*` 定义责任主体，不定义能力 bundle。

一个 baseline role 通常会组合多个 `skills/*`：

1. `General Manager / Chief of Staff`
   - 常用 `founder-brief`, `meeting-router`, `decision-pack`, `research`
2. `Product Thesis Lead`
   - 常用 `vision-meeting`, `requirements-meeting`, `brainstorming-session`, `research`
3. `Knowledge & Memory Lead`
   - 常用 `research`, `memory-checkpoint`, `daily-digest`, `decision-pack`
4. `Workflow & Automation Lead`
   - 常用 `capability-scout`, `research`, `os-audit`, `process-audit`
5. `Risk & Quality Lead`
   - 常用 `acceptance-review`, `decision-pack`, `research`
6. `Compounding Engineering Lead`
   - 常用 `retro`, `process-audit`, `governance-meeting`, `capability-scout`, `os-audit`

这是一组默认 affinity，不是硬权限。

## 文件格式

每个 role 文件使用统一 `frontmatter v1`：

1. YAML frontmatter metadata
2. `## Canonical Instructions` 或 `## Runtime Instructions` 正文

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

1. `slug` 是 role identity
2. `claude_*` 和 `codex_*` 当前仅作为兼容期 metadata 保留
3. source repo 内置角色正文使用 `## Canonical Instructions`
4. consumer runtime 新建角色沿用同一 schema，但正文标题使用 `## Runtime Instructions`

可选 skill affinity keys：

- `default_skills`
- `secondary_skills`

说明：

1. 这两个字段表达默认路由 affinity，不表达硬权限
2. 当前为了兼容 shell-native 审计与编辑脚本，值使用逗号分隔的 skill slug，而不是 YAML 数组
3. 若值不存在，统一写 `none`

可选 policy 扩展 keys：

- `policy_allowed_entrypoints`
- `policy_allowed_actions`
- `policy_mutation_actions`
- `policy_write_roots`
- `policy_forbidden_roots`
- `policy_required_artifact_type`
- `policy_required_stage`

说明：

1. 默认角色可以不声明 policy 扩展
2. 一旦声明任一 `policy_*` key，就必须把整组 policy keys 写全
3. 高信任执行角色应把这些字段视为可机读的 canonical enforcement truth

## Current Rule

1. `roles/` 只保存 `harness` 默认 PM / governance baseline
2. 本仓库不再维护 provider-owned generated role mirrors
3. consumer repo 的领域角色属于 runtime-local surface，路径是 `.harness/workspace/roles/`
4. role 变更后只跑 schema audit，不再同步任何 provider mirror
5. runtime role mutation 的 canonical 执行入口是 `scripts/runtime_role_manager.sh`

审计命令：

```bash
./scripts/audit_role_schema.sh
```

打印 role 设计模板：

```bash
./scripts/new_role.sh --print-template
```

初始化 source repo 内置 role：

```bash
./scripts/new_role.sh \
  --slug example-lead \
  --claude-description "Claude-facing description" \
  --codex-description "Codex-facing description"
```

初始化 consumer runtime role：

```bash
./scripts/runtime_role_manager.sh \
  --consumer-runtime dogfood \
  --stage post-acceptance-compounding \
  --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md \
  create \
  --slug research-dispatch-lead \
  --claude-description "Consumer-local runtime role" \
  --codex-description "Consumer-local runtime role"
```

推荐先用这份模板准备参数：

```bash
cat docs/templates/role-design-brief.md
```

推荐工作流：

1. 先由 LLM 或人工填写 `Role Design Brief`
2. 先判断它是 source baseline role，还是 consumer runtime role
3. source baseline role 才能写入 `roles/`
4. consumer runtime role 必须写入 `.harness/workspace/roles/`
5. 脚本默认自动跑 `audit_role_schema.sh`

编辑 source role：

```bash
./scripts/edit_role.sh --slug workflow-automation-lead --print-current
```

```bash
./scripts/edit_role.sh \
  --slug workflow-automation-lead \
  --claude-description "Updated Claude-facing description" \
  --codex-description "Updated Codex-facing description"
```

编辑 consumer runtime role：

```bash
./scripts/runtime_role_manager.sh \
  --consumer-runtime dogfood \
  --stage post-acceptance-compounding \
  --proposal .harness/tasks/WI-0001/closure/...-role-change-proposal.md \
  edit \
  --slug research-dispatch-lead \
  --claude-description "Updated runtime role description"
```

审计 consumer runtime role：

```bash
./scripts/runtime_role_manager.sh \
  --consumer-runtime dogfood \
  audit --quiet
```

## 边界

1. source repo 的 canonical role source 只定义 `harness` 默认 PM / governance 团队
2. consumer runtime role 解决的是某个 repo 的局部运行需要，而不是 framework baseline
3. provider-specific delta 继续放在 `docs/workflows/provider-deltas/`
4. 若未来想把某个 runtime role 升级为 source baseline，必须先证明它是跨项目、跨用户域、跨多轮复利都稳定成立的通用角色
5. `runtime-role-manager` 是 source baseline role，但它只负责执行 `.harness/workspace/roles/` 的 canonical role mutation，不负责决定是否长出新 role
6. 当高信任角色声明 `policy_*` frontmatter 时，wrapper 必须按这些字段执行机械检查，不能只靠说明文字
