# Harness Framework And Dogfood Layering Spec v2

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Status: founder-ready
- Supersedes:
  - [Harness Framework And Dogfood Layering Spec v1](/Users/vx/WebstormProjects/trading-agent/.agents/skills/harness/references/archive/harness/2026-03-25-harness-framework-and-dogfood-layering-spec-v1.md)

## Divergent Hypotheses

1. 继续让 `trading-agent` 同时承载 framework source、dogfood runtime、以及所有实例资产。
2. 彻底不在当前仓保留任何本地 `harness` 技能子仓，只讨论远程 package/skill。
3. 锁定极简最终形态：
   - repo 技能目录中的 `harness` 技能是连接远程 `harness-framework` 的干净子仓，只承载 clean harness skill/package
   - `trading-agent` 是 dogfood consumer repo
   - 所有实例态、运行态、decision/brief/state/log 都只在 repo-local `.harness/`

## First Principles Deconstruction

1. 你要的不是“更多分层文件”，而是最终可见形态足够简单。
2. 对 dogfood repo 而言，真正需要长期共存的只有两类东西：
   - framework skill source carrier
   - repo-local instance workspace
3. 只要 framework source 与 instance state 混放，reviewer 最终就会看不清：
   - 哪些是 framework product
   - 哪些是 consumer runtime truth
   - 哪些只是一次运行生成的学习资产
4. Hosted Kernel 的核心没有变：
   - framework kernel 在外部 skill/package carrier
   - repo 内只落运行态 `.harness/`
5. 对当前 dogfood 仓来说，最简洁的物理形态就是：
   - 技能目录里的 `harness` 子仓只放 clean harness skill/package
   - `.harness/` 只放 repo-local instance/workspace

## Convergence To Excellence

采纳第 `3` 条。

## Final Target

最终抽离完成后，当前仓库要能被一眼理解成：

```text
trading-agent/
  .agents/skills/harness/   # remote-linked clean framework skill subrepo
  .harness/            # all repo-local runtime and instance artifacts
  AGENTS.md            # root overlay / redirect only
  CLAUDE.md            # root overlay / redirect only
  GEMINI.md            # root overlay / redirect only
```

## Canonical Meanings

### `.agents/skills/harness/`

定位：

`clean framework skill source carrier`

只允许包含：

1. harness skill/package 本体
2. bootstrap / update / doctor / repair carriers
3. kernel docs and contracts
4. portable schemas
5. provider-native carriers
6. release / fixture / acceptance assets

禁止包含：

1. product-specific vision
2. repo-local decisions
3. repo-local briefs
4. repo-local logs
5. repo-local work state
6. dogfood run outputs

### `.harness/`

定位：

`repo-local runtime and instance workspace`

只允许包含：

1. project context
2. decisions
3. briefs
4. state
5. logs
6. runs
7. local overrides
8. runtime metadata such as install/lock/compatibility

当前已落盘的最小 scaffold：

1. `.harness/README.md`
2. `.harness/install.toml`
3. `.harness/compatibility.toml`
4. `.harness/migration-inventory.toml`
5. `.harness/workspace/`

禁止包含：

1. clean framework source
2. reusable skill/package source of truth
3. remote release packaging concerns

## Hosted Kernel Reminder

这版不是在放弃 Hosted Kernel。

最终 consumer runtime 仍然是：

`harness skill/package in framework carrier + repo-local .harness workspace`

这里只是把 dogfood repo 的物理分层也压成最简单可审阅的样子：

1. 一个 clean `harness` skill 子仓
2. 一个 repo-local `.harness` 工作区

## Root Entry Rule

root `AGENTS.md / CLAUDE.md / GEMINI.md` 仍然只做 overlay / redirect。

它们不承载：

1. framework source
2. instance state
3. long-form workflow truth

它们只负责把 agent 引到：

1. framework carrier 所需入口
2. repo-local `.harness/` runtime truth

## Dogfood Rule

`trading-agent` 的职责仍然是 dogfood/canary consumer。

这意味着：

1. 所有真实运行生成的资产都留在 `.harness/`
2. 任何 dogfood run 的 raw output、scorecard、checkpoint、decision 都不写进 `.agents/skills/harness/`
3. framework 只吸收被提炼后的 clean contracts / schema / carrier

## Migration Rule

从当前仓抽离时，判断标准非常简单：

### Move to `.agents/skills/harness/`

如果一个文件回答的是：

`所有 repo 通用的 harness source / skill / contract / carrier 应该长什么样`

它属于 `.agents/skills/harness/`。

### Keep in `.harness/`

如果一个文件回答的是：

`这个 repo 在实际运行中产生了什么状态、决策、brief、日志、checkpoint、run`

它属于 `.harness/`。

## Anti-Entropy Rule

最终 reviewer 不应再面对：

1. framework source 与 runtime truth 混在一个目录树
2. dogfood artifact 冒充 framework product
3. framework 子仓里出现 instance-generated files

最终 reviewer 只需理解两件事：

1. `.agents/skills/harness/` 是干净的 harness skill/package
2. `.harness/` 是当前仓库所有实例态与工作区

## Acceptance Bar

这一版 layering 只有同时满足以下条件才算完成：

1. `.agents/skills/harness/` 是连接远程 `harness-framework` 的 clean carrier
2. 当前仓所有实例态文件都进入 `.harness/`
3. root entry 只剩 overlay / redirect 责任
4. reviewer 不再需要横跨 framework source 与 runtime state 做考古

## Residual Risk

1. 当前仓还没真正创建远程连接的 `.agents/skills/harness/` 子仓
2. 当前 repo 的大量旧 artifact 仍然在 `workspace/`，还没迁入 future `.harness/`
3. `.harness/migration-inventory.toml` 还未被脚本化执行
