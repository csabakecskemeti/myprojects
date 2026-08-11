---
slug: coinbase-interview-prep
created: 2026-08-10
---

# Coinbase Interview Prep

Preparation for the Coinbase **IC7 / Core Automation** interview loop.

## Problem

The interview loop is four rounds, two of which are high-risk:

- **Tech Execution** — live coding with no AI assistance. Real gap: not having hand-written
  production code in a while ("lately I did not do any code, the agent is doing it").
- **Foundational** — the recruiter flagged a "lone wolf" perception; needs past
  people-leadership and multi-quarter-roadmap examples surfaced deliberately.

## Solution

A ~14-hour prep plan in 6 blocks, built entirely from hints the recruiter gave on the
2026-08-10 call — including an unusually detailed description of the coding round's format,
domain framing, and grading rubric.

## Current State

- [x] Call recorded, transcribed, diarized
- [x] Transcript re-annotated (machine diarization had speakers swapped throughout)
- [x] Full recap written
- [x] Hint/repetition analysis — idempotency is the one term she used in both of her lists
- [x] Prep plan written (6 blocks)
- [x] **pyprep app built** — local practice app, zero deps, records editing process
- [x] **50-task curriculum written and validated** (28 reference solutions pass, 413 assertions)
- [x] `/pyprep-coach` Claude Code skill
- [ ] Availability sent to recruiter
- [ ] Non-AI CodeSignal practice assessment completed
- [ ] Prep blocks executed
- [ ] Loop scheduled and run

## Key Files

**All material lives in the workspace, not in this tracker:**
`~/Documents/workspace/interviews/`

```
interviews/
├── pyprep/                     the practice app (generic, stdlib only)
│   └── python3 -m pyprep.server      →  http://127.0.0.1:8777
└── coinbase/
    ├── README.md               index + at-a-glance
    ├── recruiter-call-recap.md full recap of the call
    ├── hints-and-signals.md    repetition analysis + her literal homework list
    ├── prep-plan.md            6-block plan
    ├── coding-drills.md        stage-2 builds as prose
    ├── curriculum/             50 tasks (stage 0/1/2) + _src generators
    └── transcript/             corrected transcript + raw machine output
```

Coach skill: `~/Documents/workspace/.claude/skills/pyprep-coach/SKILL.md` → `/pyprep-coach`

Original recording + transcription pipeline:
`~/claude_workspaces/t1_20260810_151300/worker/`

## Related

- Goal: [coinbase-ic7-offer](../../goals/coinbase-ic7-offer.md)
