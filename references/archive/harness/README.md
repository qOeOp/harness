# Harness Brief Archive

这里存放已经完成使命的 harness / operating-state 推导材料历史快照。

规则：

1. 默认不作为 active working set 入口
2. 若旧路径仍被 append-only artifact 引用，允许 `.harness/workspace/briefs/` 留 redirect stub
3. 当前运行态 truth 仍应优先读 `.harness/workspace/state/`、`.harness/workspace/current/` 和已挂到 work item 的 artifact
