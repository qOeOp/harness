# Codex Worktree Convergence Matrix

更新日期：`2026-03-27`

## 背景

`harness` 当前存在 13 个由 Codex 自动化生成的并行 worktree。它们最初全部从同一个基线提交 `f9db829` 发散，而且在收敛前都处于 `detached HEAD + 未提交改动` 状态。

这意味着它们不是“链式迭代”，而是“同基线平行重写”。

## 已执行的止血动作

1. 所有 13 个 `detached` worktree 都已经转成命名分支。
2. 每个 worktree 的脏改动都已经固化为单独快照提交。
3. 当前主工作区 `main` 的未提交 diff 已备份到：
   - `/Users/vx/.codex/tmp/harness-main-working-tree-20260327-before-convergence.patch`
   - `/Users/vx/.codex/tmp/harness-main-untracked-20260327-before-convergence.txt`

## First Principles

1. `framework carrier` 与 `consumer runtime` 必须分离。
2. 收敛不是把 13 份 patch 平均合并，而是选一个集成主线，再吸收少量真独特点。
3. 直接把 `.harness/` runtime scaffold 合入当前 framework source，会把仓库身份搞混。
4. 优先吸收“边界澄清、路径推导、状态机完整性”这类结构性增益，不优先吸收表层文案漂移。

## 分支快照清单

| worktree | snapshot branch | commit | 主要主题 | 建议动作 |
| --- | --- | --- | --- | --- |
| `0a6f` | `codex/converge-snapshot-0a6f-20260327` | `5d14653` | 核心 work-item 脚本小幅改写 | `Preserve only`，不作为 keeper |
| `23a5` | `codex/converge-snapshot-23a5-20260327` | `a76966d` | work-item 脚本改写 + `update_work_item_fields.sh` | 吸收 `update_work_item_fields.sh` 设计，其余仅参考 |
| `4db5` | `codex/converge-snapshot-4db5-20260327` | `e803103` | carrier 文档/脚本修正 + hardening audit memo | 保留 audit memo，脚本层只做对照 |
| `4e14` | `codex/converge-snapshot-4e14-20260327` | `bafc9d6` | framework-carrier 边界澄清、README/入口修正、路径库尝试 | 作为高优先吸收源之一 |
| `4f2a` | `codex/converge-snapshot-4f2a-20260327` | `7e05a1e` | 在 source repo 内大规模引入 `.harness/` runtime scaffold | `Do not merge directly` |
| `59e9` | `codex/converge-snapshot-59e9-20260327` | `44eee98` | 最小 runtime bootstrap + board scaffold | 仅保留 `bootstrap_runtime_workspace.sh` 思路，不直接合并整体 |
| `607e` | `codex/converge-snapshot-607e-20260327` | `1b5ad3c` | task-flow 脚本修正 + skills 调整 + `finalize_work_item.sh` | 作为高优先吸收源之一 |
| `73cc` | `codex/converge-snapshot-73cc-20260327` | `1da67c3` | 脚本共用路径库 `lib_harness.sh` | 仅作路径抽象参考 |
| `7a88` | `codex/converge-snapshot-7a88-20260327` | `3981b3f` | `.claude/` + `.codex/` projection 批量同步 | 需要和主工作区未跟踪 adapter surface 去重后再决定 |
| `8b0f` | `codex/converge-snapshot-8b0f-20260327` | `ddd2af3` | carrier/runtime 边界文档 + `lib_harness.sh` | 文档信号强，脚本实现可被更细粒度路径库替代 |
| `a2a4` | `codex/converge-snapshot-a2a4-20260327` | `a6816c9` | `lib_harness_paths.sh` + task-flow 脚本修正 | 作为高优先吸收源之一 |
| `b159` | `codex/converge-snapshot-b159-20260327` | `80ce6e0` | `.claude/` projection + `lib_harness_paths.sh` 路线 | 作为 provider projection 吸收源之一 |
| `ba8e` | `codex/converge-snapshot-ba8e-20260327` | `daf896e` | 核心 work-item 脚本另一版小幅改写 | `Preserve only`，不作为 keeper |

## 主题聚类

### Cluster A: work-item 核心脚本分叉

成员：

- `0a6f`
- `23a5`
- `73cc`
- `8b0f`
- `a2a4`
- `ba8e`

判断：

1. 这些分支几乎都重写了同一组 `scripts/*work_item*` 文件。
2. 不能直接多路合并；必须先选统一的路径抽象方案。
3. 在这个 cluster 内，`a2a4` 的 `lib_harness_paths.sh` 比 `73cc/8b0f` 的 `lib_harness.sh` 更细粒度，也更符合 SRP。
4. `23a5` 独有的 `update_work_item_fields.sh` 是真增量，值得单独吸收。

结论：

- keeper 思路：`a2a4`
- 补充吸收：`23a5`
- 档案保留：`0a6f`、`73cc`、`8b0f`、`ba8e`

### Cluster B: framework-carrier 边界与文档收口

成员：

- `4db5`
- `4e14`
- `607e`

判断：

1. 这三条线最接近当前 `main` 的修改面。
2. 它们都在修正“当前仓库到底是 framework carrier 还是 consumer runtime”这个根问题。
3. 其中 `4e14` 更像入口与仓库身份澄清。
4. `607e` 更像 task-flow 完整性补丁，尤其是 `finalize_work_item.sh`。
5. `4db5` 的高价值主要在 audit memo，而不是直接作为代码 keeper。

结论：

- keeper 思路：`main` 作为实际集成主线，优先吸收 `4e14` 与 `607e`
- 档案保留：`4db5`

### Cluster C: 把 runtime scaffold 直接种进 source repo

成员：

- `4f2a`
- `59e9`

判断：

1. 这两条线的共同逻辑是“让当前 repo 直接长出 `.harness/` runtime surface”。
2. 这和 `8b0f` 明确提出的 `framework carrier != consumer runtime` 边界相冲突。
3. 从第一性原理看，当前 repo 作为 framework source，应该描述 runtime contract，而不是默认承载完整 runtime state。

结论：

- 不直接合并 `4f2a`
- 不直接合并 `59e9`
- 仅保留其中可拆出的 bootstrap 思路，后续放到 consumer repo 或安装流程里实现

### Cluster D: provider projection 同步

成员：

- `7a88`
- `b159`

判断：

1. 这两条线都在批量投影 `.claude/` surface。
2. `7a88` 还额外引入了 `.codex/agents/*.toml`，覆盖面更全。
3. `b159` 同时走了 `lib_harness_paths.sh` 路线，脚本边界更清晰。
4. 当前 `main` 已经存在未跟踪的 `.claude/` 与 `.codex/`，说明这一块不能盲合，必须先和主工作区去重。

结论：

- provider projection keeper 思路：以 `b159` 的脚本边界为准
- 如果需要 `.codex` projection，再从 `7a88` 选择性吸收

## 单一收敛判断

当前最稳妥的收敛主线不是任意一个 snapshot branch，而是：

1. 以当前 `main` 工作区作为唯一集成主线
2. 先吸收 `4e14`、`607e`、`a2a4`
3. 再选择性吸收 `23a5`、`b159`
4. 明确拒绝直接合入 `4f2a`、`59e9`

原因：

1. `main` 已经是当前最广的人工/自动混合集成面。
2. `4e14 + 607e + a2a4` 组合，分别覆盖身份边界、task-flow 完整性、路径抽象。
3. 这条组合比“直接采用最大分支 `4f2a`”更克制，也更符合仓库当前真实身份。

## 推荐吸收顺序

1. 从 `a2a4` 提炼路径库方案，统一 carrier/source/runtime 路径推导。
2. 从 `607e` 吸收 `finalize_work_item.sh` 与 task-flow 完整性修补。
3. 从 `4e14` 吸收 README / entrypoint / framework-carrier 边界澄清。
4. 从 `23a5` 吸收 `update_work_item_fields.sh`。
5. 对照 `b159` 与 `7a88`，只保留需要的 provider projection。
6. `4db5`、`4f2a`、`59e9`、`0a6f`、`73cc`、`8b0f`、`ba8e` 只作为档案与回溯来源。

## 禁止动作

1. 不要把 13 个 snapshot branch 轮流 merge 到 `main`。
2. 不要把 `4f2a` 或 `59e9` 整体 cherry-pick 到 framework source。
3. 不要继续让自动化在没有命名分支和集成节拍的情况下再开新 worktree。
