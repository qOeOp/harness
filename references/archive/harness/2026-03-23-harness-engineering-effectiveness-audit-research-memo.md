# Research Memo

- Linked work items: WI-0001
- Date: 2026-03-23
- Owner: Compounding Engineering Lead
- Question: 客观评估当前仓库在践行 harness engineering 上做得怎么样，整体工作流与架构是否存在冗余设计和无效架构
- Scope:
  1. 只审当前 repo 的 company OS / harness 层
  2. 不审产品 runtime 或业务实现
  3. 重点看 `Entry / Policy / State / Tools / Feedback` 是否真正形成控制面
  4. 重点识别冗余治理表面、无效抽象和未闭环风险
- Research dispatch: n/a
- Verification date: 2026-03-23
- Verification mode: internal-only
- Freshness level: stable
- Sources reviewed:
  1. AGENTS.md
  2. docs/workflows/document-routing-and-lifecycle.md
  3. .harness/workspace/current/product-vision.md
  4. .harness/workspace/state/README.md
  5. .harness/workspace/state/items/WI-0001.md
  6. .agents/skills/harness/references/archive/harness/2026-03-23-harness-consistency-and-cleanup-research-memo.md
  7. .agents/skills/harness/references/archive/harness/2026-03-23-agent-governance-frontier-and-harness-integration-research-memo.md
  8. scripts/lib_state.sh
  9. scripts/open_current_work_item.sh
  10. scripts/select_work_item.sh
  11. scripts/start_work_item.sh
  12. scripts/complete_work_item.sh
  13. scripts/transition_work_item.sh
  14. scripts/finalize_work_item.sh
  15. scripts/cleanup_terminal_work_item.sh
  16. scripts/upsert_work_item_progress.sh
  17. scripts/refresh_boards.sh
  18. scripts/audit_state_system.sh
  19. scripts/sweep_state_drift.sh
  20. scripts/validate_workspace.sh
  21. scripts/audit_document_system.sh
  22. scripts/audit_tool_parity.sh
  23. scripts/audit_doc_style.sh
  24. scripts/run_state_validation_slice.sh
  25. scripts/audit_repo_trust_boundary.sh
- Conflicting sources:
  1. `.agents/skills/harness/references/archive/harness/company-harness-map.md` 记录的是 state system 落地前判断；当前仓库已经进入 `items + boards + transitions + progress` 阶段，旧判断不能继续直接当现状。
  2. 根 README 和多个 workflow 文档都在解释执行入口；这是必要冗余的一部分，但也开始出现“同一语义在多个位置重复解释”的迹象。
  3. `tool-neutral semantics` 基本成立，但 `tool adapter capability symmetry` 并不成立，Claude 侧控制面明显更厚。
- Earliest-source check:
  1. 当前仓库最早一层是 `document routing + memory architecture`。
  2. 最新一层已经进入 `Operating State System v1`，出现 `work item / board / transition / progress / cleanup` 原语。
  3. 说明系统已从“文档制度”进入“状态协议”，但仍处于过渡态。
- Strongest evidence:
  1. 当前仓库已经具备真正的 harness kernel，而不只是文档叙事：
     - `.harness/workspace/state/items/` 作为运行态本体
     - `.harness/workspace/state/boards/` 作为派生视图
     - `.harness/workspace/state/transitions/` 作为 append-only transition ledger
     - `.harness/workspace/state/progress/` 作为 recovery artifact
  2. 状态协议不是纸面存在：
     - `audit_document_system.sh`、`audit_tool_parity.sh`、`audit_doc_style.sh`、`audit_state_system.sh`、`refresh_boards.sh --check`、`sweep_state_drift.sh` 都通过
     - `run_state_validation_slice.sh` 也能完整跑通 validation slice
  3. `transition_work_item.sh`、`link_work_item_artifact.sh`、`finalize_work_item.sh` 已经体现出 harness engineering 的关键特征：
     - precondition
     - version check
     - operation id
     - derived views
     - terminal cleanup
  4. 入口链条已经从“读很多文档”收敛为“board -> selected work item -> action recommendation”，说明执行面开始盖过纯文档面。
  5. 文档与 memory 的层次划分总体清楚：
     - constitution / canonical operating docs / operational memory / active working set / archive
  6. `trust boundary` 审计暴露出真实短板，而不是只报格式问题：
     - repo 少于两个 collaborator，无法形成独立 reviewer separation
     - `main` 最新 commit 未 verified
  7. 从规模看，治理表面已经不小：
     - `264` 个 markdown 文件
     - `36` 个 shell scripts
     - `47` 个 tool-adapter files
     - 但当前运行态只有 `5` 个 work items、`21` 个 transitions
- Strongest counter-evidence:
  1. 治理语义和角色命名已经明显多于当前执行负载。5 个 work item 对应大量 role、meeting taxonomy、cadence 和部门骨架，存在“组织叙事先行”风险。
  2. 多数部门目前更像 schema-ready container，而不是高频运行单元。部门边界已声明，但真实部门工作流密度还不够高。
  3. README、根入口、workflow 文档之间存在重复解释；虽然大体一致，但这类重复会随着后续迭代扩大维护成本。
  4. 工具中立是成立的，但能力中立并不成立：
     - Claude 侧有 hooks、commands、skills、agents
     - Codex 侧目前主要是 agents
     - Gemini 侧更接近轻量 context router
     这不是架构错误，但如果不承认差异，就会高估当前“全工具等价成熟度”。
  5. 当前评估对象是一个持续变动中的 dirty worktree，说明系统仍处于快速重构期；这削弱了“已稳定定型”的判断。
- Unknowns:
  1. 当 open work items 从 `5` 扩张到 `20+` 时，当前 board / selector / cleanup 复杂度是否仍然顺手。
  2. progress artifact 未来应该继续保持 markdown，还是升级为更可机读的 sidecar。
  3. Founder 会议 taxonomy 与部门化结构，在产品 runtime 开始后会不会继续增长为新的治理负担。
  4. Codex / Claude / Gemini 三侧是否需要更接近的 operator capability，还是明确承认“语义同源、能力不对称”。
- Risks:
  1. 如果继续增长治理表面，快过 state hardening，系统会重新滑回“更多 md，少量真实控制面”。
  2. 如果部门、角色、meeting taxonomy 在执行密度不足时继续扩张，会形成维护负债而不是执行杠杆。
  3. 如果 trust boundary 不补，当前 hash chain 和 state audit 只能证明“局部一致”，不能证明“高可信协作”。
  4. 如果 README / workflow / adapter instructions 的重复解释继续增长，后续会出现语义漂移。
- Recommendation:
  1. 当前仓库对 harness engineering 的实践，结论不是“过度空转”，也不是“已经 best-in-class”，而是：
     `kernel 正确，控制面已成型，但治理表面开始偏厚。`
  2. 最准确判断是：
     - `Harness kernel maturity`: 中高
     - `Governance surface economy`: 中等
     - `Trust boundary maturity`: 偏弱
  3. 下一阶段不要继续扩写组织层和会议层；应该把注意力收回到 4 个 P0：
     - state hardening
     - progress / recovery convention
     - trust boundary
     - governance surface compression
  4. 建议把当前仓库定位为：
     `一个已经跨过“纯文档仓库”阶段、但仍未跨过“可长期低熵运行”门槛的 harness-in-transition。`

## Divergent Hypotheses

1. `Mostly performative governance`
   - 这套系统主要还是 md 与角色叙事，真实 harness 很弱。
2. `Already strong harness`
   - 这套系统已经完成从文档仓库到受控 harness 的升级，主要问题只剩微调。
3. `Transitional kernel with surface inflation`
   - 真正的 harness kernel 已经形成，但治理表面增长开始快于执行密度。

## First Principles Deconstruction

1. harness engineering 的本质不是“角色像公司”，而是：
   - 状态是否可恢复
   - 迁移是否可校验
   - 视图是否可派生
   - 清扫是否可持续
   - 新 agent 是否能快速进入真实工作对象
2. 在 `pre-code` 阶段，最有价值的不是更多组织叙事，而是最小但足够硬的控制面。
3. 任何不能减少 ambiguity、retry risk、manual drift 的治理表面，都是负债而不是资产。
4. 任何只能在单一工具里成立、却被叙述为“全局能力”的机制，都不应被误判为成熟架构。

## Convergence To Excellence

采纳第 3 条判断：

1. 当前仓库已经明显高于“只有制度文档”的阶段。
2. 当前最值得保住的是 `state kernel`，不是继续扩张角色和 ritual。
3. 当前最该削的是表面增殖，而不是 `work item / board / transition / progress / cleanup` 这条主链。
4. 最优动作不是重构成别的框架，也不是继续长文档化，而是：
   - 保 kernel
   - 压表面
   - 补 trust
   - 用真实事项继续验证
