---
slug: agent-hub
status: active
role: owner
repo: (local only - not pushed to remote yet)
has_git: true
tags: [python, mcp, fastapi, claude-code, multi-agent]
created: 2026-06-14
updated: 2026-06-14
last_commit: 2026-06-14
my_commits: 1
total_commits: 1
contributes_to:
  - goal: local-llm-self-sufficiency
    contribution: Agent coordination for task routing
  - goal: unified-multi-machine-workflow
    contribution: Core messaging between machines
  - goal: remote-access-infra
    contribution: Central hub accessible from all machines
  - goal: multi-agent-coordination
    contribution: Primary inter-agent communication system
---

# agent-hub

**Status:** active | **Role:** owner | **Commits:** 1/1

## Quick Links

- [Tasks](./tasks/)
- [Notes](./notes/)
- [Internal Docs](./docs/)

## Repository

- Remote: (not pushed yet)
- Branch: main
- Local: ~/Documents/workspace/agent-hub

## Goals

| Goal | Contribution |
|------|--------------|
| [local-llm-self-sufficiency](../../goals/local-llm-self-sufficiency.md) | Agent coordination for task routing |
| [unified-multi-machine-workflow](../../goals/unified-multi-machine-workflow.md) | Core messaging between machines |
| [remote-access-infra](../../goals/remote-access-infra.md) | Central hub accessible from all machines |
| [multi-agent-coordination](../../goals/multi-agent-coordination.md) | Primary inter-agent communication system |

## Description

Private message hub for inter-agent communication. Allows multiple Claude Code instances to send messages to each other across machines and sessions.

## Features

- Agent registration with MAC address + session ID
- Message queue with SQLite persistence
- Broadcast to all agents
- Auto-inject hook for Claude Code
- MCP tools integration
