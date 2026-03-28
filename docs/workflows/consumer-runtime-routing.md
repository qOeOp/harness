# Consumer Runtime Routing

更新日期：`2026-03-27`

## 目的

把“某个 consumer runtime 在哪里”从裸路径参数，收敛成更安全、可广播、可审计的名字路由。

## 问题

直接传：

`--consumer-runtime-root /absolute/path/to/repo`

虽然明确，但也容易让调用看起来像“任意目录写入”。

对高信任入口，更推荐把 consumer runtime 当成一个已登记的地址：

`--consumer-runtime <name>`

## 设计结论

1. `consumer runtime route table` 是 user-owned integration。
2. 它不是 source repo contract，也不是 consumer runtime contract。
3. source repo 只提供解析脚本和推荐格式，不维护任何 live mapping。
4. 裸 `--consumer-runtime-root` 保留为低级逃生口；常规调用优先用名字路由。

## 默认地址簿

默认地址簿路径：

`$HOME/.harness/consumer-runtime-routes.tsv`

可通过环境变量覆盖：

`HARNESS_CONSUMER_RUNTIME_ROUTE_TABLE=/custom/path/routes.tsv`

也可以在命令上显式覆盖：

`--consumer-runtime-table /custom/path/routes.tsv`

## 格式

TSV，每行至少两列：

1. `consumer-runtime name`
2. `consumer repo root absolute path`
3. 可选备注

示例：

```tsv
# consumer-runtime<TAB>consumer-repo-root<TAB>optional-notes
dogfood	/Users/vx/WebstormProjects/trading-agent	Daily sandbox
research	/Users/vx/WebstormProjects/research-hub	Frontier experiments
```

## 推荐命令

打印地址簿模板：

```bash
./scripts/resolve_consumer_runtime_root.sh --print-example
```

列出已登记 runtime：

```bash
./scripts/resolve_consumer_runtime_root.sh --list
```

解析某个名字对应的 root：

```bash
./scripts/resolve_consumer_runtime_root.sh --consumer-runtime dogfood
```

用名字路由执行 runtime role mutation：

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

## 安全规则

1. 路由解析出来的 root 仍必须是合法的 consumer runtime。
2. 对 runtime role mutation，目标 runtime 还必须已启用相应的 shared writeback / role-extension 模式。
3. 名字路由只是把“公司地址”从裸路径升级成已登记入口，不会放松现有 proposal / stage / write-root 校验。
4. 若你在自动化里需要目标 runtime，优先广播 runtime name，而不是广播裸绝对路径。
