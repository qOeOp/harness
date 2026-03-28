# Department Map

更新日期：`2026-03-28`

## 目的

说明 `advanced governance mode` 下何时应该创建 runtime-local workstream / role，以及它们与 source repo 默认责任 / 路由基线的关系。

## 默认结论

1. source repo 不内置固定行业部门。
2. 默认只有 source repo baseline roles。
3. 只有在某类工作反复出现、输入输出稳定、handoff 成本持续存在时，才值得创建 runtime-local role。

## 创建门槛

新增 runtime-local role 之前，至少要满足：

1. 已有多个回合的实际工作证明它不是一次性任务。
2. 已存在清晰的输入、输出、owner 和 upgrade 规则。
3. 继续让默认 baseline roles 兼任，已经造成明显摩擦。
4. 复利 review 明确建议把该职责实体化。
5. 由 `Runtime Role Manager` 执行实际 role file mutation。

## 常见的可选 workstream

| Workstream | Mission | Key Inputs | Key Outputs | Default Owner Before Promotion |
| --- | --- | --- | --- | --- |
| `research-dispatch` | 承接需要外部验证的专门研究任务 | research dispatch、source requests、volatile topics | source notes、research memo、evidence bundle | `General Manager / Chief of Staff` 指派 |
| `delivery` | 承接实现、集成、handoff 与落地推进 | scoped requirements、task plan、acceptance target | code / docs / artifacts、handoff notes | `General Manager / Chief of Staff` |
| `acceptance` | 承接高密度 review、gate 和返工意见 | runnable slice、acceptance brief、risk notes | accept / rework / pause verdict | `Risk & Quality Lead` |
| `memory-ops` | 承接高频 writeback、archive 和 doc hygiene | decision pack、research outputs、closure artifacts | doc updates、decision log、archives | `Knowledge & Memory Lead` |
| `intake-triage` | 承接 Founder 输入或多来源新增事项的统一入口 | inbox items、links、ideas、feedback | discard / observe / research / pilot decisions | `General Manager / Chief of Staff` |

这些只是常见模式，不是默认必须存在的 built-in 部门。

## 创建位置

一旦决定实体化，角色文件必须创建在 consumer repo：

`/.harness/workspace/roles/`

推荐命令：

```bash
./scripts/new_role.sh \
  --consumer-runtime dogfood \
  --slug research-dispatch-lead \
  --claude-description "Consumer-local runtime role" \
  --codex-description "Consumer-local runtime role"
```

## Founder 输入入口

Founder 输入默认先进入：

`General Manager / Chief of Staff -> triage -> dispatch to existing baseline roles -> accepted-task compounding review -> Runtime Role Manager materializes runtime-local role if repetition proves it necessary`

详细流程见：

- [docs/workflows/founder-intake-evolution-loop.md](../workflows/founder-intake-evolution-loop.md)

## 与产品 runtime 的边界

runtime-local role 不等于用户可见产品角色，也不等于必须长期存在的部门。

详细映射见：

- [docs/organization/company-os-runtime-data-map.md](./company-os-runtime-data-map.md)
