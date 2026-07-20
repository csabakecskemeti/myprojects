---
id: "006"
title: Get an LLM judge that passes --judge-self-check
status: active
priority: high
created: 2026-07-19
---

# Get an LLM judge that passes --judge-self-check

**Blocks the model bake-off (task 002).** Ranking models by a judge that returns
constants is worse than not ranking at all.

The local 8B instruct judge scored a real episode, a randomly shuffled one, and a
6-turn fragment identically — it pattern-matches the rubric instead of reading.
Reasoning models (glm-4.7-flash, apriel-thinker) are also unusable: they spend the
whole token budget in reasoning_content and return empty content.

## Acceptance Criteria

- [ ] `evaluate.py --judge-backend <x> --judge-self-check` reports PASS
- [ ] Option A: set ANTHROPIC_API_KEY, validate the Claude judge (approved spend,
      untested — no key present in env or .env)
- [ ] Option B: try a larger local non-reasoning model, e.g. openai.gpt-oss-20b@q4_k_m
- [ ] Record which judge was chosen and its self-check delta
