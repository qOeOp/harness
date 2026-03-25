# Org Chart

更新日期：`2026-03-22`

## 目的

定义公司 OS 的治理层、部门层和汇报关系。

## 组织结构

公司采用两层结构：

1. `治理层`
2. `部门层`

当前结构：

```text
Founder / Principal
└── Chief of Staff / Operating System Lead
    ├── Product Thesis Lead
    ├── Knowledge & Memory Lead
    ├── Workflow & Automation Lead
    ├── Risk & Quality Lead
    └── Compounding Engineering Lead
        ↓ governs and coordinates
    ├── Market Intelligence Department
    ├── Strategy Research Department
    ├── Position Operations Department
    ├── Risk Office
    └── Learning & Evolution Department
```

## 治理层职责

### Founder / Principal

- 定义使命、北极星、禁区和最终 go / pause / kill。
- 深度参与 vision、公司初始化、demo 验收与治理反馈。

### Chief of Staff / Operating System Lead

- 统筹节奏、owner、升级机制和 Founder-facing 汇报。

### Product Thesis Lead

- 负责问题定义、范围、非目标和阶段目标。

### Knowledge & Memory Lead

- 负责 source of truth、写回、归档和命名体系。

### Workflow & Automation Lead

- 负责 workflow、skills、hooks、commands、tool routing 和自动化边界。

### Risk & Quality Lead

- 负责红队、审计、质量门和回滚条件。
- 拥有 `stop-the-line` 权。

### Compounding Engineering Lead

- 负责流程复利、前沿扫描、process audit 和协作优化。

## 部门层

当前部门：

1. `Market Intelligence`
2. `Strategy Research`
3. `Position Operations`
4. `Risk Office`
5. `Learning & Evolution`

每个部门承接一类长期职责，不要求立即扩成多 agent 团队。

详细职责见：

- [docs/organization/department-map.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/organization/department-map.md)

## 组织规则

1. 每个主题必须指定一个 DRI。
2. Risk & Quality Lead 可以否决进入下一 gate。
3. Chief of Staff 负责把分歧整合成可供 Founder 拍板的选项集。
4. Knowledge & Memory Lead 负责确认最终结论已写入 canonical memory。
5. 公司部门不等于产品 runtime 角色。

详细映射见：

- [docs/organization/company-os-runtime-data-map.md](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/docs/organization/company-os-runtime-data-map.md)
