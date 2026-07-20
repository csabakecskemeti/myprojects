---
date: 2026-07-19
tags: [evaluation, embeddings, llm-judge, measurement]
---

# Eval harness built — three metrics that looked right and weren't

Session goal was measurement, not improvement: make dialogue quality comparable so
model/prompt changes stop being judged by ear. Built `evaluate.py` on branch
`feat/dialogue-eval-harness`. Full write-up in the repo at `docs/evaluation.md`.

## The finding worth acting on

**Front-loading is real, monotonic, and in every episode.** Coverage declines from
the start of the article to the end without exception, and degrades with article
length (Cerebras 94.7%, RLHF 92.1%, MoE 70.8%). The model runs out of steam on long
inputs. This is now reproducible and measurable, so it's the highest-confidence
improvement target.

## Three implementations that produced plausible numbers and were wrong

Worth remembering because each one *looked* like a working metric:

1. **Fixed cosine threshold.** An episode about a completely different article
   scores 0.70 against this one; a real match scores 0.79. A 0.55 threshold
   reported 100% coverage for everything. Now calibrated per run against an
   unrelated episode.

2. **Per-turn chatter scoring.** Ranked "it's like a library of a million books,
   you only read one" — the best explanatory turn in the episode — as filler, and
   "sounds like a cooking show gone wrong" — a joke — as substance. Cosine measures
   vocabulary overlap, so jargon-echoing wins and fresh analogies lose. That's
   backwards for podcast quality. Axis abandoned; delegated to the LLM judge.

3. **Blank-line-only chunking.** An article with no blank lines became a single
   13k-char chunk that any episode trivially "covered" → 100%. Only one of three
   baseline numbers was ever honest.

## The judge doesn't work yet

A local 8B instruct model returned **byte-identical scores** for a real episode, a
randomly shuffled one, and a 6-turn fragment. It pattern-matches the rubric rather
than reading. Added `--judge-self-check` (real vs shuffled) as a permanent gate; it
currently FAILs.

Reasoning models are also unusable as judges here — glm-4.7-flash and the "thinker"
spend their whole budget in `reasoning_content` and return empty `content`, even at
4096 max_tokens.

**Blocks the bake-off.** Next session: set ANTHROPIC_API_KEY and validate the Claude
judge (approved spend, no key present), or try gpt-oss-20b locally.

## Meta-lesson

Every one of these failures was invisible from the output alone — the numbers looked
reasonable. They were only caught by negative controls: an unrelated article, a
shuffled transcript, reading the actual top/bottom-ranked turns. Build the control
before trusting the metric.
