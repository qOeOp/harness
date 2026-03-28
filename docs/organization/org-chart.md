# Org Chart

更新日期：`2026-03-28`

## 目的

定义 `harness` 当前默认内置的 baseline roles，以及它与 consumer runtime 的边界。

## 默认组织结构

当前 source repo 只内置一层 baseline roles：

```text
Founder / Principal
└── General Manager / Chief of Staff
    ├── Product Thesis Lead
    ├── Knowledge & Memory Lead
    ├── Workflow & Automation Lead
    ├── Risk & Quality Lead
    ├── Compounding Engineering Lead
    └── Runtime Role Manager
```

这里不再内置任何特定行业、特定项目、特定用户域的默认部门。

默认 baseline role 并不与单个 skill 一一对应。

关系应理解为：

1. `skills/*` 是能力 bundle
2. `roles/*` 是责任主体
3. role 默认消费多个 skill
4. department 只在 runtime 中按需组合多个 role

## 角色职责

### Founder / Principal

- 定义使命、北极星、禁区和最终 go / pause / kill。
- 只在方向、验收和高风险升级时深度介入。

### General Manager / Chief of Staff

- 把 Founder 意图收敛成单一问题和执行边界。
- 指派 owner、组织节奏、整合 dissent，并决定何时升级。

### Product Thesis Lead

- 负责问题定义、范围收缩、非目标和阶段命题。

### Knowledge & Memory Lead

- 负责 source of truth、writeback、归档与记忆卫生。

### Workflow & Automation Lead

- 负责 workflow、skills、scripts、tool routing 和自动化边界。

### Risk & Quality Lead

- 负责红队、验收、质量门和 stop-the-line。

### Compounding Engineering Lead

- 负责 process audit、frontier scan 和复利改进。

### Runtime Role Manager

- 负责根据已批准的 role change proposal 执行 runtime-local role 的创建、编辑和审计。
- 只写 `.harness/workspace/roles/`，不回写 source baseline role，也不接管 provider-specific agent 文件。

## Optional Runtime Workstreams

如果某个 consumer repo 在 `advanced governance mode` 下反复出现稳定分工，才可以按需长出 runtime-local workstream / role。

这类角色：

1. 不属于 source repo 默认团队
2. 必须写入 `.harness/workspace/roles/`
3. 由复利 review 证明必要性后，再由 `Runtime Role Manager` 创建

详细边界见：

- [docs/organization/department-map.md](./department-map.md)
- [docs/organization/company-os-runtime-data-map.md](./company-os-runtime-data-map.md)
- [docs/organization/governance-capability-map.md](./governance-capability-map.md)

## 组织规则

1. 每个主题必须指定一个 DRI。
2. `Risk & Quality Lead` 可以否决进入下一 gate。
3. `General Manager / Chief of Staff` 负责把分歧整合成可供 Founder 拍板的选项集。
4. `Knowledge & Memory Lead` 负责确认最终结论已写回 canonical memory。
5. consumer runtime 的临时或长期角色，不反向定义 source repo 的默认组织图。
6. `Runtime Role Manager` 只负责执行 runtime role mutation，不负责自行判断是否该扩角色。
