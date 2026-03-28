# Project Structure

更新日期：`2026-03-28`

## Repo Identity

这个仓库是 `harness` 的 implementation source repo，也是 `agent execution substrate` 的 canonical source。

它负责六类东西：

1. `/harness` 入口与 root repo map
2. `skills/` 能力包
3. `roles/` 与 workflow docs 提供的责任 / 路由基线
4. `references/` 下的 runtime contract
5. `scripts/` 下的执行器、验证器与审计入口
6. 可恢复、可验证、可追踪的读取与写回边界

它不直接承载：

1. 任意 consumer repo 的 live task runtime truth
2. root `AGENTS.md / CLAUDE.md / GEMINI.md` 的默认产品入口语义
3. 任何 provider-owned surface 的默认接管逻辑
4. 任何公司 / workstream / board 类型的默认产品组织图

## Product Layers

当前产品叙事只保留三层：

1. `repo map`
   - 默认 `/harness` 进入后优先理解的 source surface
   - 由 `SKILL.md`、`skills/`、`roles/`、`docs/`、`references/`、`scripts/` 组成
2. `task-record runtime`
   - materialized `.harness/` 任务执行层
   - 关注 scoping、state、resume、attachments、closure
3. `verification / observability / control`
   - tests、audit、freshness、review、trace correlation、approval、policy、permission boundary
   - 属于 substrate 的默认部分，不是事后附加

## Source Repo Layout

当前 source-of-truth 目录：

- `SKILL.md`
  - 根 skill 入口
- `skills/`
  - 可复用 skill 包
- `roles/`
  - `harness` 内置责任主体与默认路由基线
- `scripts/`
  - runtime、audit、source maintenance 脚本
- `docs/`
  - workflow、charter、memory 与 templates
- `references/`
  - active references、runtime contracts、implementation-adjacent specs 与历史资料

## Runtime Contract

`harness` 的默认 runtime root 仍然是 `.harness/`，但它不再被视为前置安装物。

只有当任务需要跨回合追踪、恢复、reviewable artifact 或决策回写时，才按需 materialize。

默认最小 runtime 应围绕：

- `tasks/`
  - task 目录本体，内部承载 `task.md`、`attachments/`、`closure/` 与 `history/transitions/`
- `locks/`
  - 受控状态写入时的运行时锁
- `manifest.toml`
  - repo-local runtime metadata

source repo 不保留 live `.harness/`。

source repo 只保留：

- runtime contract
- runtime materializer
- smoke-chain validation

当前最小链路由以下脚本负责：

- `scripts/materialize_runtime_fixture.sh`
- `scripts/run_state_validation_slice.sh`

补充边界：

- provider conversation / response / thread state 属于 transport state，不属于默认 runtime truth
- 若确需恢复 in-flight execution，可在 `task.md` 的 `## Recovery` 或 `history/` 里记录 `response_id`、`thread id`、`stream cursor`、`trace id`
- 这些 execution handles 只服务 reconnect / resume / trace correlation，可替换、可过期

共享写回说明：

- `.harness/workspace/*` 只用于显式 promote 的共享记录面
- 它可以承载 `research/dispatches`、`research/sources`、`decisions/log`、`status/snapshots` 这类共享记录
- 它不是默认 runtime 主骨架，更不是公司 / workstream 组织树

如果某个 consumer repo 需要新增 repo-local role，应写到：

- `.harness/workspace/roles/`
  - consumer-local runtime role definitions
  - 优先通过 `./scripts/new_role.sh --consumer-runtime <name>` 创建
  - 不回写到 framework source repo 的 `roles/`

## Design Rule

所有文件都要先回答一个问题：

它属于 `core task runtime`、`verification/control surface`、`internal plumbing`，还是根本不该存在。

如果三边都不属于，就不该存在于 canonical surface。
