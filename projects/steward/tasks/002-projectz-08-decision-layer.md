---
id: "002"
title: Phase 1 - projectz 0.8 decision layer
status: active
priority: high
created: 2026-08-08
blocked_by: "001"
---

# Phase 1 - projectz 0.8 decision layer

The steward's output quality is bounded by what it reasons over. Today an
agent asked "what next" returns noise.

## Acceptance Criteria

- [ ] `areas/` — continuous work with `cadence` + `health`, never `done`
- [ ] `kind:` — `repo` | `hardware` | `learning` | `household` | `area`;
      only `kind: repo` touched by `scan`
- [ ] `next_action`, `effort`, `energy` on every `active` project and area
- [ ] Decay rules implemented, batched and confirmed — never silent
- [ ] `/projectz now --effort --energy` returning 3 items max
- [ ] Ships as a `skill-vault` release

## Done When

UC-2 and UC-9 pass. Every `active` project has exactly one concrete
`next_action`.
