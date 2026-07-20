---
id: "002"
title: Local GGUF model bake-off via LM Studio
status: active
priority: high
created: 2026-07-19
---

# Local GGUF model bake-off via LM Studio

Rank local quantized models on writing quality using the eval harness (task 001).

No new backend needed: LM Studio serves an OpenAI-compatible API on
`http://localhost:1234/v1`, so the existing `litellm` backend works with only
`LITELLM_BASE_URL` / `LITELLM_MODEL` changed.

## Acceptance Criteria

- [ ] Script drives `~/.lmstudio/bin/lms` to load/unload models
- [ ] Fixed article set generated per model
- [ ] Scored via evaluate.py, leaderboard emitted
- [ ] Test the hypothesis that instruct/reasoning/coding models narrate rather than
      converse — prefer creative/character-writing tunes
- [ ] Fine-tune only if nothing off-the-shelf wins

Depends on: 001
