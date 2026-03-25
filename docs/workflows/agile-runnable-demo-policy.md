# Agile Runnable Demo Policy

更新日期：`2026-03-23`

## 收敛结论

本公司遵循的 agile 原则不是“频繁展示半成品”，而是：

**每次向 Founder 展示的版本都必须是独立可运行、可体验、可验证的垂直切片。**

agile 也不是“为了更快展示而压缩前置阶段”。

在 AI 公司里，真正昂贵的是：

1. vision 是否锁定
2. 需求是否稳定
3. 边界是否明确
4. 计划是否可信

执行本身通常很快，所以前置阶段默认比执行阶段更值得投入时间。

## 为什么

Founder 不是来替团队想象“功能做完后会怎样”的。

Founder review 的对象必须是：

1. 已经能运行
2. 已经能使用
3. 已经有明确边界
4. 已经能验证价值

否则那不叫 demo，只叫未完成的内部状态。

## 规则

1. 不展示无法启动或无法触达核心路径的版本。
2. 不展示“功能做了一半，但还不能形成完整体验”的版本。
3. 每次迭代必须交付一个最小可运行单元。
4. 如果某项工作还只是研究或设计，只能作为 internal artifact 汇报，不能作为 Founder-facing demo。
5. 如果某个 slice 的问题定义、验收标准或边界还没稳定，不得为了“赶 demo”硬推进。

## 一个合格 demo 必须回答

1. 用户现在能完成什么任务？
2. 这条路径从入口到输出是否完整？
3. 哪些约束还没解决，但不影响当前 slice 的可运行性？
4. 如何验证它确实工作？

## Demo Gate

在提交 Founder review 前，必须通过：

1. `Runnable`
   - 能启动
   - 能执行核心流程

2. `Usable`
   - Founder 能独立操作，不需要团队脑补解释

3. `Bounded`
   - 已知哪些东西故意没做

4. `Reviewable`
   - 有清晰的验收点和反馈问题

## Acceptance Review

Founder 参与产品过程的主要方式不是日常 requirements 讨论，而是 `Acceptance Review`。

规则：

1. 只有通过 Demo Gate 的版本，才允许进入 Founder 验收。
2. Founder 的职责是：
   - 判断是否“好到可以继续”
   - 提出方向性质疑
   - 明确哪些地方仍然“不够好”
3. Founder 不负责现场补需求、拆任务或决定实现细节。
4. 验收后的反馈由 `Compounding Engineering Lead` 和 `Chief of Staff` 分解给各部门处理。

## 当前阶段的解释

由于当前还是 `pre-code`，所以本规则暂时作用于：

- 文档工作流 demo
- department workflow demo
- memory / intake / decision 流程 demo

等进入编码阶段后，这条规则直接升级为产品交付标准。

## 与钢铁纪律的关系

1. demo cadence 是输出节奏，不是向下硬推阶段的理由。
2. 前置阶段如果不稳，最正确的动作不是继续做 demo，而是回到当前层补强。
3. 在 AI 公司里，“先把规划做极致”不是慢，而是避免后续大规模返工的唯一办法。
