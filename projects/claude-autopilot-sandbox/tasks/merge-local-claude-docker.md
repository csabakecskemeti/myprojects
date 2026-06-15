---
slug: merge-local-claude-docker
status: open
priority: high
created: 2026-06-14
---

# Merge or delete ~/Documents/workspace/local-claude-docker

## Alert

You have TWO local folders pointing to the same GitHub repo:
- `~/Documents/workspace/local-claude-docker` (older name)
- `~/Documents/workspace/claude-autopilot-sandbox` (current name)

**Both have uncommitted changes with different content!**

## What's in local-claude-docker (not in claude-autopilot-sandbox)

Untracked files to review:
- `kaggle_*.txt` - Kaggle task files
- `log.txt`, `neon_todo_app_log.txt`, `snake_log.txt` - Session logs
- `agent-marketplace-prd.txt`, `agentcon-task*.txt` - Task definitions
- `cyberpunk-platformer.md`, `investment_finder.txt` - Project ideas
- `kill-and-resume-with-context.md` - Documentation
- `terminal_control_center.txt`, `todo-task.txt` - More tasks
- `test_stop_hook_feedback/` - Test folder
- `docs/CONFIG_HARDENING_PLAN.md` - Config docs
- Modified: `CLAUDE.md`, `TODO.md`, `docker-compose.yml`, `run.sh`

## Action Required

1. Review the files above in `local-claude-docker`
2. Copy anything valuable to `claude-autopilot-sandbox`
3. Commit changes to `claude-autopilot-sandbox`
4. Delete `local-claude-docker`: `rm -rf ~/Documents/workspace/local-claude-docker`
5. Close this task

## Commands

```bash
# Compare the two folders
diff -rq ~/Documents/workspace/local-claude-docker ~/Documents/workspace/claude-autopilot-sandbox

# Copy specific files you want to keep
cp ~/Documents/workspace/local-claude-docker/FILENAME ~/Documents/workspace/claude-autopilot-sandbox/

# After merging, delete the old folder
rm -rf ~/Documents/workspace/local-claude-docker
```
