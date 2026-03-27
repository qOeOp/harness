# Harness: Gemini 导读

欢迎来到 `harness`。

把它想成一家纪律严明、运转高效的虚拟公司更准确，而不是一堆零散脚本。Gemini 在这里不是“会话里想起什么就做什么”的全能助理，而是在固定制度、状态机、审计链和写回规则下工作的执行者。

## 1. 这家公司长什么样

1. [SKILL.md](/Users/vx/WebstormProjects/harness/SKILL.md)
   - 总前台，告诉你先按公司的规矩办事
2. `roles/*.md`
   - 岗位说明书，定义谁负责什么、不能做什么
3. `skills/*/SKILL.md`
   - SOP，定义什么时候产出什么文档
4. `docs/workflows/*.md`
   - 公司制度，定义 gate、路由、打断和审计
5. `scripts/*.sh`
   - 执行部门，真正去改状态、写账本、跑校验
6. `.harness/`
   - consumer repo 里按需生成的 runtime

## 2. v2 runtime 心智

`task.md` 是唯一任务真相。

最小 runtime 现在是：

```text
.harness/
  manifest.toml
  entrypoint.md
  README.md
  tasks/
    WI-xxxx/
      task.md
      attachments/
      history/transitions/
  locks/
```

这意味着：

1. `task.md` 是唯一任务真相
2. Recovery 与主状态同文件共存
3. `archived` 用状态字段表达
4. board 不是默认真相，只是可选 projection

## 3. 一张工单怎么跑

主状态流：

`backlog -> planning -> ready -> in-progress -> review -> done -> archived`

补充分支：

1. 任意执行中可进 `paused`
2. 任意阶段可进 `killed`

`task.md` 里除了 `Status` 之外，还会记录：

1. `Assignee / Worktree / Claimed at / Lease version`
2. `Current stage owner / Current stage role / Next gate`
3. `Decision / Review / QA / UAT / Acceptance status`
4. `## Recovery`
5. `Linked attachments`

## 4. Recovery 怎么做

命令名还是：

```bash
./scripts/upsert_work_item_recovery.sh <WI-xxxx> "<current-focus>" "<next-command>" "[recovery-notes]"
```

Recovery 只回答三件事：

1. 当前在做什么
2. 下一条命令是什么
3. 补充恢复说明

## 5. Attachments 放哪里

task-local 正式材料默认都走 `attachments/`：

1. research dispatch
2. research memo
3. decision pack
4. checkpoint
5. source note

都需要显式 `--work-item <WI-xxxx>`。

只有显式 `--promote-governance`，且 runtime 已进入 governance mode，才允许写到 `.harness/workspace/*`。

## 6. 你最常用的命令

```bash
./scripts/work_item_ctl.sh status --json --all
./scripts/work_item_ctl.sh start --json company
./scripts/work_item_ctl.sh pause --expected-from-status in-progress --expected-version <v> --interrupt-marker risk-review-required <WI-xxxx>
./scripts/work_item_ctl.sh resume --expected-version <v> <WI-xxxx>
./scripts/work_item_ctl.sh close --json --target-status review --work-item <WI-xxxx> company
./scripts/query_work_items.sh --status in-progress --assignee gemini
```

## 7. 纪律底线

1. 不要手工 patch `task.md` 伪造状态
2. 不要把 query 结果或 board 当成账本
3. 不要依赖隐式当前任务
4. 不要让聊天上下文代替 Recovery
5. 先让 task-record runtime 稳，再谈治理投影和复杂自动化
