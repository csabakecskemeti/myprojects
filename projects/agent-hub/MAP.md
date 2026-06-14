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

## Description

Private message hub for inter-agent communication. Allows multiple Claude Code instances to send messages to each other across machines and sessions.

## Features

- Agent registration with MAC address + session ID
- Message queue with SQLite persistence
- Broadcast to all agents
- Auto-inject hook for Claude Code
- MCP tools integration
