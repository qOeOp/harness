# Worktree-First Parallelism

更新日期：`2026-03-22`

## 收敛结论

本仓库采用：

`company-level monorepo + department bounded contexts + one-thread-one-worktree`

而不是：

- 多线程共享同一个工作目录
- 多个部门直接互改对方文件
- 用一个共享日志文件承接所有并行写入

## 基本规则

1. 一个 thread 对应一个 `git worktree`。
2. 一个部门线程主写一个部门子树。
3. 公司级 `workspace/` 只允许 append-only 写入。
4. 跨部门协作通过 artifact handoff，不通过直接修改对方目录。

## Branch 命名

推荐：

`codex/<department>-<task>`

例如：

- `codex/market-intelligence-source-registry-v1`
- `codex/strategy-research-thesis-loop-v1`

## Worktree 路径

推荐放在仓库外层：

`../harness-worktrees/<department>-<task>`

原因：

1. 不污染主仓库
2. 并行线程更容易隔离
3. 便于清理

前提：

- 仓库必须已经有首个 commit，否则 `git worktree` 无法建立新工作树。

## Owned Paths

### 公司级

- `docs/`
- 根 `CLAUDE.md`
- 根 `AGENTS.md`
- `.claude/`
- `.codex/`
- `.agents/skills/`

这些只能由治理层或被明确授权的线程修改。

### 部门级

- `.harness/workspace/departments/<department>/`

部门线程默认只写自己的目录。

### 共享 append-only

- `.harness/workspace/intake/inbox/`
- `.harness/workspace/intake/triage/`
- `.harness/workspace/research/sources/`
- `.harness/workspace/decisions/log/`
- `.harness/workspace/status/snapshots/`

这些目录允许多个线程同时新增文件，但不鼓励频繁改同一个已有文件。

## 跨部门流程

1. 在自己部门目录完成研究或产出。
2. 输出写成 memo / proposal / handoff note。
3. 如需进入公司级 memory，则新增一条 append-only entry。
4. 如需对方部门响应，则在对方部门的 intake 或 handoff 文档中以新文件形式提交。

## 禁止事项

1. 不要多个 thread 共享同一 worktree。
2. 不要部门线程直接重写公司级规范文件。
3. 不要让多个线程并行编辑同一份总表。
