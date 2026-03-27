---
name: meeting-router
description: Use when a founder-facing meeting needs to be routed to the correct canonical meeting skill.
---

Read [./manifest.toml](./manifest.toml).
Read [./refs/README.md](./refs/README.md).

Route the current request to exactly one of:

- `governance-meeting`
- `vision-meeting`
- `acceptance-review`
- `requirements-meeting`
- `brainstorming-session`

Do not mix multiple meeting types into one output.
If the topic touches volatile external facts, follow the freshness and `research` bundle `dispatch` requirements in the selected downstream skill.
