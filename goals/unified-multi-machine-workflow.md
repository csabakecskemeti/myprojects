---
slug: unified-multi-machine-workflow
status: active
priority: high
created: 2026-06-14
target_date:
parent: ai-powered-income
---

# Unified Multi-Machine Workflow

## Description

Create a seamless development experience across all personal machines where switching computers feels invisible - same tools, same configs, same project state, same AI capabilities, and agents that can communicate across machines.

## Why It Matters

- **Continuity**: Pick up exactly where you left off on any machine
- **Flexibility**: Work from Mac Pro at home, workstation for heavy compute, MacBook when traveling
- **Efficiency**: No time lost setting up or syncing manually
- **AI everywhere**: Access local LLM infrastructure from any location
- **Collaboration**: Agents can delegate tasks to each other across machines

## Machines

| Machine | Type | Primary Use |
|---------|------|-------------|
| Csabas-Mac-Pro | 2013 Mac Pro | Daily driver, general development |
| AI Workstation | Linux | Heavy compute, GPU workloads |
| M1 MacBook Pro | macOS | Travel, mobile development |
| DGX Spark Cluster (2x) | NVIDIA | Local LLM inference |

## Success Criteria

- [ ] All machines have identical dev environment (dotfiles, tools, configs)
- [ ] Switching machines requires zero manual sync
- [ ] Can access any machine remotely from any other
- [ ] Can access DGX Spark cluster from any machine
- [ ] Claude Code agents can message each other across machines
- [ ] Project state (tasks, notes, progress) syncs automatically

## Sub-Goals

| Goal | Status | Focus |
|------|--------|-------|
| [sync-dev-environment](./sync-dev-environment.md) | active | Same configs/tools everywhere |
| [remote-access-infra](./remote-access-infra.md) | active | Access any machine from anywhere |
| [multi-agent-coordination](./multi-agent-coordination.md) | active | Agents communicate across machines |

## Related Goals

- [local-llm-self-sufficiency](./local-llm-self-sufficiency.md) - The AI infrastructure these machines access

## Contributing Projects

| Project | Status | Contribution |
|---------|--------|--------------|
| skill-vault | active | Shareable Claude Code skills across machines |
| agent-hub | active | Inter-agent messaging system |
| dgx-spark-playbooks | backlog | DGX Spark setup and access |
| quasar-deck | active | Monitoring across machines |

## Progress Notes

- 2026-06-14: Goal created with 3 sub-goals
