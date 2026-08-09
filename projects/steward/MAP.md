---
slug: steward
status: draft
role: owner
repo: (design only - no code yet)
has_git: false
tags: [agent, orchestration, multi-machine, privacy, local-llm, design]
created: 2026-08-08
updated: 2026-08-09
last_commit:
my_commits: 0
total_commits: 0
parents: []

dependencies:
  hard:
    - project: agent-hub
      reason: "Messaging, registry and task queue; must be hardened and remotely reachable first (Phase 0)"
  soft:
    - project: skill-vault
      reason: "projectz 0.8 decision layer ships as a skill update (Phase 1)"
    - project: llm-router
      reason: "Tier selection across vLLM and llama.cpp endpoints (Phase 4)"
    - project: llm-forwarder
      reason: "Routing to local inference endpoints (Phase 4)"

goals:
  - goal: multi-agent-coordination
    contribution: "The always-on coordinator: lease-based leader election, handoff records, cross-framework message contract"
  - goal: unified-multi-machine-workflow
    contribution: "Single source of truth plus continuity so switching machines needs no re-explanation"
  - goal: local-llm-self-sufficiency
    contribution: "First real consumer of tiered local inference; zero cloud dependency by design"
---

# steward

**Status:** draft | **Role:** owner | **Design complete, no code yet**

An always-on personal coordination agent spanning multiple machines, agent
frameworks and LLM backends — at zero marginal cost, with no cloud dependency
and no personal data leaving the LAN.

## Quick Links

- [Tasks](./tasks/)
- [Notes](./notes/)
- [Internal Docs](./docs/)

## Part Of

[personal-ai-os](../../ideas/personal-ai-os.md) — the umbrella concept.
`steward` is the buildable core; that idea file holds the connections to the
dozen other projects that are components of the same system.

## Design Documents

- [Architecture](./docs/steward-architecture.md) — design of record
- [Roadmap](./docs/steward-roadmap.md) — **authoritative build order**
- [Use Cases](./docs/steward-usecases.md) — 10 scenarios, double as acceptance tests

## Dependencies

### Hard (Code)
- **agent-hub**: Messaging, registry and task queue. Currently 1 commit,
  local-only, no service unit — Phase 0 exists to fix this.

### Soft (Workflow)
- **skill-vault**: projectz 0.8 decision layer ships as a skill update
- **llm-router** / **llm-forwarder**: tier selection and endpoint routing

## Goals

| Goal | Contribution |
|------|--------------|
| [multi-agent-coordination](../../goals/multi-agent-coordination.md) | Always-on coordinator, lease election, handoffs |
| [unified-multi-machine-workflow](../../goals/unified-multi-machine-workflow.md) | Single source of truth plus continuity |
| [local-llm-self-sufficiency](../../goals/local-llm-self-sufficiency.md) | First real consumer of tiered local inference |

## Internal Docs

- [Architecture](./docs/steward-architecture.md)
- [Roadmap](./docs/steward-roadmap.md)
- [Use Cases](./docs/steward-usecases.md)
