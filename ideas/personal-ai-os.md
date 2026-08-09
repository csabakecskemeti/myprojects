---
slug: personal-ai-os
status: researching
created: 2026-08-08
updated: 2026-08-09
tags: [orchestration, multi-agent, multi-machine, privacy, local-llm, umbrella]
converted_to:
---

# Personal AI OS

The umbrella concept. A private, zero-cost, always-on system that keeps track
of everything I do — code, hardware, learning, family, house — across 4–5
machines and multiple agent frameworks, and tells me what is worth my time.

**This is not a single project.** It is the thing that a dozen existing
projects turn out to be parts of. `steward` is one component, not the whole.

## The Idea

One system where:

- Every project, area, idea and captured article lives in **one source of
  truth**, readable from any machine and by any agent
- Agents on different machines, in different frameworks, on different models
  can **hand work to each other** and resume each other's sessions
- An **always-on component** captures things I send it from anywhere, enriches
  them in the background, and connects them to what I am already working on
- It runs on **my own hardware at zero marginal cost**, and **personal data
  never leaves the LAN**
- When I ask "what should I do now", it gives a real answer

## Problem It Solves

- **Fragmentation** — state lives in my head and scattered across 4–5 machines
- **Mixed lifecycles** — some work finishes, some never does; treating them
  alike makes everything feel unbounded
- **No prioritization** — `projectz` tracks 57 projects and cannot say which
  one deserves the next hour. 44 sit in `backlog`; 8 open tasks exist in total
- **Lost inflow** — articles, ideas and links vanish because capturing them
  costs more than it is worth. One idea file exists in the entire tracker
- **No continuity** — switching machines means re-explaining context
- **Non-code work is invisible** — hardware builds, house, family and learning
  have no repo, so a git-driven tracker cannot see them

## Component Projects

Everything below already exists. The idea is the connective tissue, not new
scaffolding.

### Core

| Project | Status | Role in the concept |
|---------|--------|---------------------|
| [steward](../projects/steward/MAP.md) | draft | Always-on coordinator: capture, enrichment, review, leader election |
| [agent-hub](../projects/agent-hub/MAP.md) | active | Messaging, registry, task queue between agents |
| [skill-vault](../projects/skill-vault/MAP.md) | active | Ships `projectz` — the source of truth and its decision layer |

### Inference substrate

| Project | Status | Role in the concept |
|---------|--------|---------------------|
| [llm-router](../projects/llm-router/MAP.md) | backlog | Tier selection across vLLM and llama.cpp endpoints |
| [llm-forwarder](../projects/llm-forwarder/MAP.md) | backlog | Proxy to local inference endpoints |
| [llmaas](../projects/llmaas/MAP.md) | backlog | Local inference serving |
| [cc-token-saver-mcp](../projects/cc-token-saver-mcp/MAP.md) | backlog | Delegate cheap tasks to local models |
| [dgx-spark-playbooks](../projects/dgx-spark-playbooks/MAP.md) | backlog | The hardware everything runs on |

### Observability and capture

| Project | Status | Role in the concept |
|---------|--------|---------------------|
| [quasar-deck](../projects/quasar-deck/MAP.md) | active | Is the infrastructure healthy? Which tier is available? |
| [clipboard-mcp](../projects/clipboard-mcp/MAP.md) | backlog | Possible fast capture path when at a machine |
| [ambient-agents](../projects/ambient-agents/MAP.md) | backlog | Prior exploration of always-on agent patterns |

### Consumers of the captured knowledge

| Project | Status | Role in the concept |
|---------|--------|---------------------|
| [article-to-podcast-converter](../projects/article-to-podcast-converter/MAP.md) | active | Turns the reading queue into something consumable on a commute |
| [ai-articles](../projects/ai-articles/MAP.md) | backlog | Output side — what gets written from what was learned |

**The reading loop is the most under-appreciated connection here:** capture an
article by email → enrich and link it to an active project → convert it to
audio → listen while doing hardware work. Two existing projects already close
that loop; nothing has connected them.

## The Fleet

Six machines, deliberately assigned roles — see
[computers/README.md](../computers/README.md) for full detail.

| Machine | Role | Inference tier |
|---|---|---|
| Mac Pro (2013 Xeon, 128 GB) | Desktop / daily driver | **none** — client only |
| MacBook Pro (M5 Max, 128 GB) | Travel, steward failover | A |
| AI workstation (RTX 5090 + RTX 6000 Pro, 1 TB DDR5) | Heavy compute, quantization | A |
| DGX Spark ×2 (GB10, 121 GB each) | Local LLM inference (vLLM) | A |
| OrangePi 5 Plus (RK3588) | Always-on services, rack display | C |

Two findings that changed the design:

- **The MacBook is tier A, not tier B.** 128 GB unified memory runs large
  quantized models, so travelling with the rack off no longer degrades
  capability. Tier B is now empty — the ladder is effectively A or C.
- **The Mac Pro provides no inference at all.** Roles and tiers are
  independent: the machine with the most checkouts is a pure client.

## Related Goals

- [multi-agent-coordination](../goals/multi-agent-coordination.md)
- [unified-multi-machine-workflow](../goals/unified-multi-machine-workflow.md)
- [remote-access-infra](../goals/remote-access-infra.md)
- [local-llm-self-sufficiency](../goals/local-llm-self-sufficiency.md)
- [sync-dev-environment](../goals/sync-dev-environment.md)

Four of the five existing goals are already describing pieces of this idea.
That is the strongest evidence the concept is real rather than invented: it
was arrived at independently, three times, before it was named.

## Brainstorm Notes

- The recurring architectural pattern across every layer: **a small durable
  text record is the contract; everything fast is a disposable cache.** True
  for git vs `agent-hub`, for handoff records vs KV blobs, and for public vs
  private stores
- Git is the only always-available coordination point, so leader election and
  service discovery both belong there — not in a service that can be off
- A mailbox is the only address that survives the coordinator moving between
  machines. Outbound IMAP only: no inbound reachability required anywhere
- **Default private, promote to public.** The inverse fails the first time
  classification is wrong, and GitHub is permanent
- Degrade, never fail: anything the current tier cannot do is queued, not
  dropped. Travel becomes a latency problem, not a data-loss problem
- Most of the inference substrate is already written and sitting in `backlog`.
  This idea is largely **assembly, not construction**

## Research

- [Steward architecture](../projects/steward/docs/steward-architecture.md) — design of record
- [Steward roadmap](../projects/steward/docs/steward-roadmap.md) — build order
- [Steward use cases](../projects/steward/docs/steward-usecases.md) — 10 acceptance scenarios

## Viability Assessment

### Pros

- Roughly 80% of the components already exist in some form
- Every phase is independently useful; stopping anywhere leaves a working system
- Zero marginal cost and no cloud dependency, by design
- Gives several stalled `backlog` projects (`llm-router`, `llm-forwarder`,
  `cc-token-saver-mcp`) their first real consumer — which is likely why they
  stalled

### Cons

- Broad surface area; easy to drift into building infrastructure forever
- The highest-value step (triaging 57 projects) is the least enjoyable
- Success depends on habit, not code. If capture is not used daily, none of
  the rest matters
- OrangePi-class hardware limits what the always-on tier can reason about

### Effort Estimate

- Phases 0–3 (durable hub, decision layer, vault, capture): a few weekends
- Phases 4–6 (lease, tiers, handoffs, loop): a month or two part-time
- Phase 7 (KV warm resume): deferred, probably never — see architecture §8.3

## Decision

**Status: researching**

Not converting to a project — it is an umbrella, and `steward` already carries
the buildable part. This file exists to hold the connections between the
dozen projects that turn out to be components.

Next steps:

1. Review the three steward design documents *(scheduled: 2026-08-09)*
2. Phase 0 — harden `agent-hub`: push to a remote, systemd unit, Tailscale
3. Phase 1 — `projectz` 0.8, then triage all 57 projects
4. Revisit this file after Phase 3: if capture is being used daily, the
   concept is validated; if not, stop and fix that before building further
