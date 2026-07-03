---
name: skills
description: Lists the skills available in this session — both general/built-in Claude Code skills and this project's custom skills (like /autopilot) — as a menu of what's available. Invoke with /skills.
---

When invoked:

1. List the general/built-in skills currently surfaced to this session (the "available skills" the harness lists), each with a one-line description in your own words.
2. List this project's custom skills found under `.claude/skills/` — read each `SKILL.md`'s frontmatter `name` and `description` directly from disk rather than relying on memory, and exclude this skill itself from the list.
3. Present both as two clearly labeled sections. Only list what's genuinely available right now — don't invent or assume skills that aren't actually present, since both lists can change over time as the harness updates or as new project skills are added.
