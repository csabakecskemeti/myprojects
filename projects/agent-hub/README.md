---
slug: agent-hub
created: 2026-06-14
---

# Agent Hub

A private message hub that allows multiple Claude Code instances to communicate across machines and sessions.

## Problem

- Multiple Claude Code instances running on different machines cannot communicate with each other
- No way to send tasks or questions between AI agents
- Same machine can have multiple Claude Code sessions that need to coordinate

## Solution

- FastAPI-based REST server that acts as a message broker
- MCP tools for Claude Code to send/receive messages
- Session-based routing (computer_id:session_id) for precise targeting
- Auto-inject hook that displays pending messages in conversations
- Broadcast capability to message all registered agents

## Tech Stack

- **Language:** Python 3.12
- **Framework:** FastAPI + Uvicorn
- **Database:** SQLite (data/hub.db)
- **Protocol:** MCP (Model Context Protocol) for Claude Code integration
- **Transport:** HTTP REST API + stdio MCP

## Current State

- [x] FastAPI server with agent registry and message queue
- [x] MCP tools (list_agents, send_message, check_messages, reply, mark_read, broadcast)
- [x] Session ID support for same-machine routing
- [x] Auto-inject hook for UserPromptSubmit
- [x] Comprehensive README documentation
- [ ] Systemd service for auto-start
- [ ] Web UI for message monitoring
- [ ] Message expiration/cleanup

## Getting Started

### Server (OrangePi 5 or central host)

```bash
cd ~/Documents/workspace/agent-hub
python3 -m venv venv
./venv/bin/pip install fastapi uvicorn requests pydantic
./venv/bin/python src/server.py --port 8765
```

### Client (each machine with Claude Code)

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "agent-hub": {
      "command": "python3",
      "args": ["/path/to/agent-hub/src/mcp_tools.py"],
      "env": {
        "AGENT_HUB_URL": "http://server-opi5p.local:8765"
      }
    }
  }
}
```

Add hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "/path/to/agent-hub/scripts/auto_inject_hook.sh",
        "timeout": 3
      }]
    }]
  }
}
```

## Key Files

- `src/server.py` - FastAPI hub server with REST endpoints
- `src/mcp_tools.py` - MCP tools for Claude Code (stdio transport)
- `scripts/auto_inject_hook.sh` - Hook that injects pending messages
- `data/hub.db` - SQLite database (auto-created)

## Related

- Uses MAC address for computer identification (no external dependencies)
- Integrates with Claude Code hooks system
