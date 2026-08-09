---
slug: multi-agent-coordination
status: active
priority: high
created: 2026-06-14
target_date:
parents:
  - unified-multi-machine-workflow
  - ai-powered-income
---

# Multi-Agent Coordination

## Description

Enable Claude Code instances running on different machines to communicate with each other, share context, delegate tasks, and coordinate work. An agent on your MacBook should be able to ask an agent on your workstation to run a heavy computation.

## Why It Matters

- **Task delegation**: "Run this on the GPU machine"
- **Context sharing**: Agent on machine B knows what agent on machine A was working on
- **Parallel work**: Multiple agents working on different parts of a problem
- **Continuity**: Switch machines and agent picks up where the other left off

## Use Cases

### 1. Heavy Compute Delegation
```
MacBook Agent: "I need to run inference on a large model"
  → Sends task to Workstation Agent
  → Workstation Agent runs on GPU
  → Returns result to MacBook Agent
```

### 2. Context Handoff
```
Mac Pro Agent: "I was refactoring the auth module, here's the context"
  → Stores context in agent-hub
  → MacBook Agent: "Continue the auth refactoring"
  → Retrieves context, continues work
```

### 3. Parallel Execution
```
Mac Pro Agent: "Run tests on all backends"
  → Spawns tasks to Workstation (Python tests)
  → Spawns tasks to DGX (GPU tests)
  → Collects results
```

### 4. Local LLM Routing
```
Any Agent: "This is a simple task, use local LLM"
  → Routes to DGX Spark for local inference
  → Saves cloud API costs
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Mac Pro    │     │  Workstation│     │  MacBook    │
│  Agent      │     │  Agent      │     │  Agent      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │  agent-hub  │
                    │  (central)  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌─────────┐  ┌─────────┐  ┌─────────┐
        │DGX Spark│  │DGX Spark│  │ Other   │
        │   #1    │  │   #2    │  │ Services│
        └─────────┘  └─────────┘  └─────────┘
```

## Components

### agent-hub (Exists)
- [x] Basic message passing
- [x] Agent registration with MAC + session ID
- [x] SQLite persistence
- [ ] Context sharing (conversation summaries)
- [ ] Task delegation protocol
- [ ] Result collection
- [ ] Agent discovery (who's online?)

### MCP Integration
- [x] MCP tools for send/receive
- [ ] Auto-inject hook deployed on all machines
- [ ] Standardized task format

### Routing Logic
- [ ] Task complexity estimation
- [ ] Route simple tasks to local LLM
- [ ] Route heavy compute to GPU machines
- [ ] Fallback handling

## Success Criteria

- [ ] agent-hub running and accessible from all machines
- [ ] Claude Code on each machine has MCP tools configured
- [ ] Can send message from Mac Pro agent, receive on MacBook agent
- [ ] Can delegate compute-heavy task to workstation
- [ ] Can route simple inference to DGX Spark
- [ ] Agents can share session context

## Contributing Projects

| Project | Status | Contribution |
|---------|--------|--------------|
| agent-hub | active | Core messaging infrastructure |
| cc-token-saver-mcp | backlog | Routes simple tasks to local LLM |
| llm-router | backlog | Complexity-based routing |
| skill-vault | active | Shareable skills for agent coordination |
| steward | draft | Always-on coordinator: lease election, handoff records, cross-framework message contract |

## Progress Notes

- 2026-06-14: Goal created as sub-goal of unified-multi-machine-workflow
- 2026-06-14: agent-hub already deployed on OrangePi 5, basic messaging works
- 2026-08-08: `steward` designed — see [architecture](../projects/steward/docs/steward-architecture.md).
  Resolves "context sharing" and "agent discovery" via git-lease election plus
  layer-1 handoff records. Blocked on hardening agent-hub (Phase 0).
