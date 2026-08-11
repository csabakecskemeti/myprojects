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
- [x] **120-task curriculum written and validated** (50 reference solutions pass, 534 assertions)
- [x] Stage 0 exploded to **one function per task** (87 tasks) so a stall names one idea
- [x] **Proactive in-app coaching** — fires on a 45s stall or 3 failed runs: code smells,
      recall cards, and a local-LLM read of the buffer (auto-detects Ollama/LM Studio;
      prefers a code-tuned model)
- [x] 3-rung hint ladders on every task; visible test cases
- [x] **Help button** — local model gives one next step from your code + the error
- [x] **Validated task generation** — weak topics top themselves up; every generated
      exercise must have a reference solution that passes and a starter that fails.
      Capped (4/topic, 2 for syntax topics, 40 total) so one topic can't swallow the session
- [x] Progress persists across restarts; reset by day / all / mastery
- [x] **30 real coding exercises** added (control-flow, text, classes, interpreters,
      simulation) + 10 LeetCode-easy classics in LeetCode's own format — 152 tasks total
- [x] **Areas** you can jump between, independent of stage gating
- [x] INPUT/OUTPUT examples derived from the tests via `ast`
- [x] Free-form exercise requests to the local model
- [x] Re-run solved tasks to refine them (unscored, keeps the better version);
      task picker to revisit anything; Pause button that doesn't corrupt timings
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
