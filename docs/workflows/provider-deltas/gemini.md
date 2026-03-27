# Gemini Delta

更新日期：`2026-03-24`

## 目的

记录 Gemini 相对于 [agent-operator-contract.md](../agent-operator-contract.md) 的 provider-specific delta。

本文件只记录 Gemini 特有差异，不复述共性 operator rules。

## 适用面

当前仓库里与 Gemini 直接相关的 adapter surface 主要是：

1. `GEMINI.md`
2. `.gemini/settings.json`
3. 未来如有必要才会出现的 `/.gemini/agents/`

## Gemini-Specific Operating Notes

### 1. Context Routing Is Hierarchical

Gemini 通过 `GEMINI.md` 层级上下文提供 repo 指令，并允许在 `settings.json` 里改 `context.fileName`。

当前仓库选择：

1. consumer repo 的 `GEMINI.md` 与 `.gemini/settings.json` 属于 user-owned/provider-owned surface
2. harness 不生成、不修改这些文件
3. consumer runtime 的 first hop 仍只收敛到 `.harness/entrypoint.md`
4. framework source repo 仍以 `SKILL.md` 与 canonical references 为入口，不假装常驻 `.harness/`
5. 详细 workflow source 当前仍是 [document-routing-and-lifecycle.md](../document-routing-and-lifecycle.md)

不要把 `GEMINI.md` 再长回第二套宪法。

### 2. Skill Discovery Remains Provider-Owned

Gemini 官方 workspace skill 发现支持：

1. `.gemini/skills/`
2. provider 自己支持的 skill discovery alias

这些都属于 provider 自己的发现机制，不属于 harness runtime contract。
因此当前仓库不生成、也不要求任何 Gemini skill mirror。

### 3. Custom Subagents Are Experimental

截至 `2026-03-24`，Gemini custom subagents 仍是 experimental。

项目级自定义 subagents 的路径是：

1. `.gemini/agents/*.md`

并需要 `settings.json` 里开启：

1. `"experimental": { "enableAgents": true }`

当前仓库没有这样做，原因不是“不会做”，而是：

1. repo 虽然已有 `roles/` canonical role source，但 Gemini 还不是当前真实执行主面
2. Gemini custom subagents 仍是 experimental
3. 为了表面对称而复制 11 个 provider mirror，只会重新引入 drift surface

### 4. Agent Semantics Stay In `roles/`

Gemini 侧当前只有：

1. routing parity
2. skills parity
3. agent role semantic parity

这些语义都落在 `roles/` 和 canonical docs，不落在 Gemini-specific repo mirrors。

### 5. Missing Gemini Agent Adapter Should Produce Honest Output

如果某个建议需要 Gemini custom subagents 才成立，正确做法是：

1. 明确说明当前 repo 未启用这层 adapter
2. 产出 reviewable proposal 或 decision pack
3. 不要把“Gemini theoretically supports it”包装成“仓库已经具备”

## 非目标

本文件不定义：

1. 仓库级 operator contract
2. 公司 OS 的 canonical semantics
3. Claude / Codex delta
4. Gemini skills 正文
