---
slug: sync-dev-environment
status: active
priority: high
created: 2026-06-14
target_date:
parents:
  - unified-multi-machine-workflow
---

# Sync Dev Environment

## Description

Ensure all development machines have identical configurations, tools, and settings. When you install a tool or change a config on one machine, it should propagate to all others.

## Why It Matters

- No "works on my machine" issues between your own machines
- Muscle memory works everywhere (same keybindings, aliases, etc.)
- Claude Code behaves identically on all machines
- New machine setup is automated

## Components to Sync

### Shell & Terminal
- [ ] Zsh/Bash configuration (.zshrc, .bashrc)
- [ ] Shell aliases and functions
- [ ] Terminal emulator settings (iTerm2, Alacritty, etc.)
- [ ] Tmux configuration

### Development Tools
- [ ] Git configuration (.gitconfig)
- [ ] SSH keys and config
- [ ] Editor settings (VS Code, Vim, etc.)
- [ ] Language version managers (pyenv, nvm, rustup)

### Claude Code
- [ ] Claude Code settings (~/.claude/settings.json)
- [ ] MCP servers configuration
- [ ] Skills (~/.claude/skills/)
- [ ] Hooks configuration

### Project State
- [ ] Projectz tracker repo synced
- [ ] Common repos cloned to same paths
- [ ] Environment variables for projects

## Approach Options

| Approach | Pros | Cons |
|----------|------|------|
| **Dotfiles repo** | Simple, Git-based | Manual sync trigger |
| **Chezmoi** | Templates, secrets handling | Learning curve |
| **Nix/Home Manager** | Declarative, reproducible | Steep learning curve |
| **Ansible** | Powerful, idempotent | Overkill for personal use? |

## Success Criteria

- [ ] Single command to sync all configs
- [ ] New machine setup < 30 minutes
- [ ] Claude Code skills available on all machines
- [ ] No manual copying of configs ever

## Contributing Projects

| Project | Status | Contribution |
|---------|--------|--------------|
| skill-vault | active | Shareable skills across machines |

## Ideas

- Could use skill-vault pattern for dotfiles too
- Git submodules or separate repos per config type?
- Need to handle machine-specific configs (paths, hardware)

## Progress Notes

- 2026-06-14: Goal created as sub-goal of unified-multi-machine-workflow
