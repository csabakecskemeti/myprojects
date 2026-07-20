---
id: "007"
title: Fix article front-loading in generated dialogue
status: active
priority: high
created: 2026-07-19
---

# Fix article front-loading in generated dialogue

Measured 2026-07-19: coverage declines monotonically from the start of the article
to the end in **every** episode tested, and gets worse as articles get longer.

| Episode | Chunks | Coverage | By third (start->end) |
|---|---|---|---|
| Cerebras | 19 | 94.7% | 100 -> 100 -> 83.3 |
| RLHF | 38 | 92.1% | 100 -> 92.3 -> 83.3 |
| MoE | 48 | 70.8% | 81.2 -> 68.8 -> 62.5 |

Highest-confidence improvement available: the failure is reproducible and now
measurable, so a fix can be verified rather than guessed at.

## Candidate approaches

- Chunk the article and generate per-section, then stitch
- Add an explicit outline pass before writing dialogue
- Scale the DEEP DIVE point count with article length

## Acceptance Criteria

- [ ] Coverage-by-third is flat (or near-flat) on the MoE article
- [ ] MoE overall coverage well above the 70.8% baseline
- [ ] No regression in drift or structure metrics
