# Project Structure

更新日期：`2026-03-26`

## Repo Identity

这个仓库是 `harness` 的 implementation source repo。

它只负责三类东西：

1. `core task runtime` 的 canonical logic
2. 可选的 `advanced governance mode` 设计与材料
3. source-maintainer 侧的 contracts、references、scripts 与 audits

它不直接承载：

1. 任意 consumer repo 的 live task runtime truth
2. root `AGENTS.md / CLAUDE.md / GEMINI.md` 的默认产品入口语义
3. 任何 provider-owned surface 的默认接管逻辑

## Product Layers

当前产品叙事只保留两层：

1. `core task runtime`
   - 默认 `/harness` 进入的任务执行层
   - 关注 scoping、state、resume、attachments、closure
2. `advanced governance mode`
   - 用户显式升级后才出现的组织治理层
   - 关注 cadence、roles、escalation、cross-task coordination

另有一层内部面：

1. `internal plumbing`
   - source repo 维护、archive hygiene、audit、diagnostic、runtime scaffold verification
   - 对用户来说不是主入口
   - 包括 runtime scaffold 与 smoke-chain verification
   - 以及 user-owned consumer runtime route table 的解析脚本

## Source Repo Layout

当前 source-of-truth 目录：

- `SKILL.md`
  - 根 skill 入口
- `skills/`
  - 可复用 skill 包
- `roles/`
  - `harness` 内置 PM / governance baseline role source
- `scripts/`
  - runtime、audit、source maintenance 脚本
- `docs/`
  - workflow、charter、organization 与 templates
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

迁移期说明：

- `task`、`recovery` 与 transition history 的 canonical source of truth 已收敛到 task 目录
- `.harness/workspace/state/transitions/` 只保留给 legacy fallback 读取，不再是默认写入面

只有在用户显式升级到 `advanced governance mode` 时，才值得扩到更重的公司治理树。

此时如果某个 consumer repo 需要新增 repo-local role，应写到：

- `.harness/workspace/roles/`
  - consumer-local runtime role definitions
  - 优先通过 `./scripts/new_role.sh --consumer-runtime <name>` 创建
  - 裸路径只作为低级逃生口：`--consumer-runtime-root <consumer-repo>`
  - 不回写到 framework source repo 的 `roles/`

## Design Rule

所有文件都要先回答一个问题：

它属于 `core task runtime`、`advanced governance mode`、`internal plumbing`，还是根本不该存在。

如果三边都不属于，就不该存在于 canonical surface。
