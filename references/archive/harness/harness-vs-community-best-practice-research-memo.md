# Research Memo

- Date: 2026-03-23
- Owner: CTO / Workflow & Automation
- Question: Harness vs community best practice research memo
- Scope: Compare this repo's current harness against current official public guidance for coding-agent harnesses, focusing on redundancy and overdesign rather than raw capability.
- Research dispatch: .harness/workspace/research/dispatches/2026-03-23-harness-community-best-practice-comparison.md
- Verification date: 2026-03-23
- Verification mode: mixed
- Freshness level: volatile
- Sources reviewed:
  1. https://openai.com/index/harness-engineering/
  2. https://openai.com/business/guides-and-resources/how-openai-uses-codex/
  3. https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
  4. https://www.anthropic.com/engineering/building-effective-agents
  5. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
  6. https://docs.anthropic.com/en/docs/claude-code/sub-agents
  7. https://docs.anthropic.com/en/docs/claude-code/hooks
  8. .harness/workspace/research/sources/2026-03-23-harness-gap-and-architecture-source-bundle.md
  9. AGENTS.md
  10. docs/workflows/document-routing-and-lifecycle.md
  11. .harness/workspace/state/README.md
  12. .harness/workspace/state/boards/company.md
  13. scripts/work_item_ctl.sh
  14. scripts/select_work_item.sh
  15. scripts/transition_work_item.sh
- Conflicting sources:
  1. OpenAI / Anthropic都强调先从简单、聚焦的 harness 开始。
  2. 但 long-running / high-stakes agent 又要求更强的状态持久化、human checkpoints 和恢复机制。
  3. 冲突点不在“要不要结构”，而在“结构应该落在 kernel 还是表面叙事”。
- Earliest-source check:
  1. 外部对照均已按 2026-03-23 重新核验。
  2. 内部 source bundle 与同日官方页面一致，没有发现方向性冲突。
- Strongest evidence:
  1. 你的根入口并不臃肿；`AGENTS.md / CLAUDE.md / GEMINI.md` 只有 60 行，且承担的是 router 角色，而不是“一份巨型总说明书”。
  2. 当前 harness 已具备社区公认的强控制面特征：稳定入口、可机读 selector、原子 start/complete、expected_version、append-only transition ledger、progress artifact、paused/resume protocol。
  3. `OpenAI` 与 `Anthropic` 的公开建议都支持：
     - 任务先走最简单可行流程
     - 子 agent 要职责聚焦
     - 长回合任务要可恢复
     - deterministic guardrails 应交给 harness / hooks / workflow，而不是全压在 prompt
  4. 你的 repo 在这些核心点上不是落后，而是高于平均线。
  5. 真正偏厚的是表面层：
     - `docs/*.md` 49 个
     - `workspace/*.md` 235 个
     - `scripts/` 45 个
     - `.claude/` 34 个文件、`.codex/` 12 个、`.gemini/` 1 个
     - 部门 `memos/outputs` 当前非 `.gitkeep` 文件数为 0
  6. 这说明当前复杂度更多堆在 governance surface，而不是活跃执行流量上。
- Strongest counter-evidence:
  1. 你的域不是低风险内容生成，而是带交易决策纪律要求的高风险系统；这类域对 traceability、recoverability、human approval 的要求本来就高。
  2. 因此 `state kernel` 的复杂度并不应被简单判成 over-engineering。
  3. 一些在普通 agent 仓库里显得重的设计，在这里属于必要成本：
     - work item state machine
     - progress artifact
     - interrupt marker / resume target
     - explicit founder/risk gates
- Unknowns:
  1. 这套 harness 在真实长期执行下的维护摩擦还没有被充分暴露，因为当前 open queue 很浅，company board 目前没有 open item。
  2. 部门化 scaffold 未来是否会被真正激活，目前证据不足。
  3. 三套工具适配层未来是否都要达到接近等强能力，还是应承认主从关系，目前没有被正式锁定。
- Risks:
  1. 若继续增加 meeting taxonomy、部门 scaffold、adapter 表面，而不增加真实执行负载，会形成维护负担大于治理收益的过配。
  2. 若误把“表面偏厚”理解成“kernel 也该简化”，会把真正有价值的控制能力一起拆掉。
  3. 若继续追求三工具完全镜像，而不是语义一致、能力有主次，会制造无效维护。
- Recommendation:
  1. 结论不是“你这套太重，应砍掉一半”，而是：
     `kernel 合理，surface 偏厚。`
  2. 与社区最佳实践相比，你的主要问题不是 state machine 太复杂，而是组织/文档/适配层提前铺得过多。
  3. 下一步应做 `surface compression`，不是 `kernel simplification`：
     - 保留 board -> selector -> opener -> transition/progress/interrupt 这条主链
     - 合并重复 README / workflow 解释
     - 把 dormant 部门 scaffold 明确标成占位而不是“仿佛已运行”
     - 接受工具语义一致但能力不完全对称
