---
title: Dialogue Quality Plan
created: 2026-07-19
updated: 2026-07-19
---

# Dialogue Quality Plan

## The problem

The pipeline works end to end on local inference, but **the dialogues aren't amazing**.
They're coherent and on-topic, yet they don't read like real conversation — turns are
written rather than spoken, banter is overused, and it's unclear whether long articles
get covered fully or just front-loaded.

The core issue is that **none of this is measured**. Every prompt or model change so far
has been judged by listening to one episode, which is slow, subjective, and doesn't
compound. Fix the measurement first.

## Ordering (and why)

1. Evaluation harness ← blocks everything
2. Model bake-off (needs #1 to rank)
3. Agentic enrichment (needs #1's fidelity axis as a safety gate)
4. Expressive TTS (independent, but lowest leverage)

Better writing beats better voices: expressive TTS cannot rescue stiff dialogue, so
higgs-tts is deliberately last despite being the most fun.

## 1. Evaluation harness (`evaluate.py`)

Score a `podcast.json` against its `raw_article.md` on four axes:

| Axis | Question | Approach |
|------|----------|----------|
| **Coverage** | Does it cover the *whole* article? | Split article into sections/key claims, embed both sides, report uncovered sections. Suspected failure: front-loading on long articles. |
| **Flow** | Speech or narrated prose? | LLM-judge rubric. Cheap proxies to log regardless: turn-length distribution, Q/A alternation rate, whether a turn responds to the prior one or starts a fresh monologue. |
| **Chatter** | Is banter diluting substance? | Ratio of informative turns to filler/banter, with a target band. Some chatter is the point — the complaint is *over*use. |
| **Fidelity** | Claims unsupported by the article? | Low stakes today; becomes critical once web enrichment can introduce outside facts. |

`nomic-embed-text-v1.5` is already loaded in LM Studio, so embeddings are local and free.

Output per-axis + overall so changes become A/B testable. The `podcast_raw.txt` files
(saved since the vLLM branch) are the accumulating eval corpus.

## 2. Model bake-off via LM Studio

**Key finding: no new backend is needed.** LM Studio already serves an OpenAI-compatible
API on `http://localhost:1234/v1`, so the existing `litellm` backend reaches it with only
an env change:

```bash
LITELLM_BASE_URL=http://localhost:1234/v1
LITELLM_MODEL=<id from `lms ls`>
```

`~/.lmstudio/bin/lms` can load/unload models (`lms ls`, `lms server status`), so the
bake-off is scriptable: for each model → generate over a fixed article set → score →
leaderboard.

Locally available (10 models, ~119 GB):
`zai-org.glm-4.7-flash`, `openai.gpt-oss-20b` (q4_k_m),
`qwen.qwen3-coder-30b-a3b-instruct`, `servicenow-ai.apriel-1.6-15b-thinker`,
`nvidia.llama-3.1-8b-ultralong-2m-instruct` (ultralong context — interesting for long
articles), `qwen.qwen3-vl-8b-*`, `nvidia.opencodereasoning-nemotron-14b`.

**Hypothesis worth testing:** the stiffness comes from using instruct/reasoning/coding
models, which narrate rather than converse. Prefer creative/character-writing tunes.
Fine-tuning is the fallback if nothing off-the-shelf wins.

## 3. Agentic enrichment

Let the generator research selected points on the web for depth, while staying true to
the source article. The tension: enrichment must *support* the article, never drift into
a different story or add unsupported claims — hence gating it on the fidelity axis.

**Reuse `claude-autopilot-sandbox`** rather than building search from scratch. It already
runs Claude Code in Docker with autonomy, **searxng for web search**, supervisor
integration, and Langfuse tracing (code: `~/Documents/workspace/local-claude-docker`).

**Open decision:** purpose-built agent vs. existing harness (Claude Code, Hermes).
Purpose-built is easier to constrain and keeps fidelity guarantees tight; an existing
harness gets tool-use, retries, and tracing for free. Lean on whatever the sandbox
already proves out.

## 4. Expressive TTS

Evaluate [`bosonai/higgs-tts-3-4b`](https://huggingface.co/bosonai/higgs-tts-3-4b).
Kokoro is fast and dependency-light but flat — it narrates evenly where a podcast needs
emphasis, laughter, and emotional range. At ~4B vs Kokoro's 82M, benchmark VRAM and
synthesis time per episode before switching. Only `synthesizer.py` changes, since it
consumes `podcast.json`.

## Known smaller issues

- Model sometimes labels the expert's takeaway as a HOST turn → wrong voice reads it
- Long generations loop/re-emit the episode (worked around in `_truncate_at_repeat`;
  note the earlier splice-based version reordered dialogue and put the outro at turn 4 —
  don't reintroduce it)
- LAN IP `192.168.7.103` is hardcoded in `dialogue.py`/README of a public repo
