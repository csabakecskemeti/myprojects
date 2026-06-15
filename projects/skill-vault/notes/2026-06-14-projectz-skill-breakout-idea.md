---
date: 2026-06-14
tags: [projectz, architecture, optimization]
---

# Projectz Skill Breakout Idea

## Problem

The projectz SKILL.md is now ~1200 lines / 32KB. This is a lot of context to inject every time `/projectz` is invoked.

## Proposed Solution

Break into multiple skills under the same plugin:

```
skill-vault/plugins/projectz/skills/
├── projectz/SKILL.md   # Core: summary, scan, sync, note, task (~300 lines)
├── goals/SKILL.md      # Goals: goal, goals, link, unlink (~200 lines)
├── ideate/SKILL.md     # Ideation: ideate, ideas, idea, convert (~200 lines)
└── deps/SKILL.md       # Dependencies: depends, deps, blocked, depgraph (~200 lines)
```

Invocation would be:
- `/projectz` - Core
- `/projectz:goals` - Goals
- `/projectz:ideate` - Ideation
- `/projectz:deps` - Dependencies

## Cross-referencing

Since `related_skills` is not a standard frontmatter field, put relationships in the body:

```markdown
## Related Skills

This skill is part of the projectz family:
- `/projectz` - Core project management
- `/projectz:deps` - Dependency tracking
...
```

Claude reads the body, so it understands the relationships.

## Decision

**For now: Keep as single file.** The 32KB context cost is acceptable.

**Revisit if:**
- Context becomes a bottleneck
- Users complain about slow response
- We add even more features

## Reference

Checked Claude Code skill spec - official frontmatter fields are:
- name, description, when_to_use
- disable-model-invocation, user-invocable
- allowed-tools, disallowed-tools, model, effort, shell
- context, agent, paths, hooks
