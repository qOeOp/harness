# Hosted Kernel Harness Spec v1.6

- Date: 2026-03-25
- Owner: CTO / Workflow & Automation
- Supersedes:
  - `.agents/skills/harness/references/archive/harness/2026-03-25-hosted-kernel-harness-spec-v1-5.md`
- Round focus:
  - deterministic adoption

## Why This Round

只把 adoption 拆出去还不够。  
如果 adoption 继续靠宽泛语义分类，它仍然不适合默认产品化。

## Changes In This Version

1. adoption 改为 `preview-first`
2. adoption 只允许 `heading/block-only`
3. mixed section 默认不迁
4. 每个 adopted section 必须带：
   - `section-id`
   - `source heading`
   - `source checksum`
   - `adopted target`
   - `adopted_at`
5. root 原位置换 redirect block 时必须带 `section-id`

## Locked Principle

迁移靠结构边界，不靠自由语义猜测。

## Residual Risk

1. adopted section 的真相优先级还没写死
2. 还没有 migration ledger
3. 还没有 doctor 对 redirect coverage 的校验

