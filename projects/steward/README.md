---
slug: steward
created: 2026-08-08
---

# Steward

An always-on personal coordination agent that tracks projects, areas, ideas and
captured knowledge across multiple machines, multiple agent frameworks and
multiple LLM backends — at zero marginal cost, with no cloud dependency.

## Problem

Work is spread across 4–5 machines and dozens of repos, mixed with
never-ending responsibilities (community quantization, hardware, house,
family) and a constant inflow of articles and ideas.

- **Fragmentation** — state lives in my head and scattered across machines
- **Mixed lifecycles** — some work has a finish line, some never ends; lumping
  them together makes everything feel equally unbounded
- **No prioritization** — even with perfect tracking, nothing answers "given
  all this, what is worth the next hour"

`projectz` already tracks 57 projects across 3 machines and answers
*"what do I have?"* well. It answers *"what should I do now?"* not at all:
44 of 57 projects sit in `backlog`, only 2 have any tasks, and 8 open tasks
exist in total. The decision layer is empty.

## Solution

Three stores with one rule — **durable small text is the contract, everything
fast is disposable**:

| Store | Holds | Leaves the LAN |
|---|---|---|
| `myprojects` (git) | projects, areas, goals, next actions, distilled knowledge | yes |
| `myprojects-private` (git, LAN-only remote) | transcripts, PII, family/health/financial | **never** |
| `agent-hub` (service) | registry, messages, task queue, inbox | never |

Key mechanisms:

- **Decision layer** — `areas/` for continuous work, `kind:` to decouple from
  git, and `next_action` + `effort` + `energy` so "I have 90 minutes and I'm
  tired" is answerable
- **Leader election via git lease** — `git push` is a free compare-and-swap;
  no consensus protocol. The lease also serves as service discovery
- **Tiered inference** — vLLM on the DGX cluster, llama.cpp (LM Studio /
  Ollama / native) on the MacBook, all OpenAI-compatible, so the router is a
  list of base URLs. Anything the current tier cannot do is queued, not
  dropped
- **Email capture** — the steward moves between machines, a mailbox does not.
  Outbound IMAP only: no port forwarding, no tunnels, works behind hotel NAT
- **Handoff records** — migrate state, not processes; portable across
  machines, models and frameworks

## Tech Stack

- **Language:** Python
- **Service:** `agent-hub` (FastAPI + SQLite + MCP), on the OrangePi 5
- **Truth:** Git + Markdown
- **Inference:** vLLM (DGX Spark cluster), llama.cpp (MacBook, OrangePi)
- **Transport:** IMAP/SMTP for capture, HTTP + JSON between agents
- **Network:** Tailscale

## Current State

Design complete. No code written yet.

- [x] Architecture designed and documented
- [x] Use cases defined (10, doubling as acceptance tests)
- [x] Build order with acceptance criteria per phase
- [ ] Phase 0 — harden `agent-hub`
- [ ] Phase 1 — `projectz` 0.8 and backlog triage
- [ ] Phase 2 — private vault
- [ ] Phase 3 — mail capture
- [ ] Phase 4 — lease and tiers
- [ ] Phase 5 — handoffs and delegation
- [ ] Phase 6 — steward loop
- [ ] Phase 7 — KV warm resume *(deferred, probably skip)*

Phases 0–3 are worth doing even if the rest is never built.

## Key Files

- `docs/steward-architecture.md` — design of record
- `docs/steward-roadmap.md` — authoritative build order
- `docs/steward-usecases.md` — end-to-end scenarios

## Open Questions

- Mail provider and domain for the dedicated address (blocks Phase 3)
- Whether `agent-hub` follows the steward on failover or stays pinned to the
  OrangePi — leaning pinned, it is simpler
- Whether areas need their own `next_action` or just a cadence nudge
- Model choice per tier; not yet benchmarked on the OrangePi (RK3588)

## Related

- [Architecture decisions](./docs/steward-architecture.md)
- [multi-agent-coordination](../../goals/multi-agent-coordination.md)
- [unified-multi-machine-workflow](../../goals/unified-multi-machine-workflow.md)
