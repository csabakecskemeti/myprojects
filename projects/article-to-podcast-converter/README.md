---
slug: article-to-podcast-converter
created: 2026-06-29
---

# Article-to-Podcast Converter

Convert any article URL into a two-voice AI podcast conversation with TTS audio,
running entirely on local inference.

## Problem

Can't read while walking or commuting. Standard TTS is monotonous. Articles are dense —
a dialogue format is more listenable and naturally adds pacing and clarification.

## Solution

Three-step pipeline with a JSON handoff between stages:

```
Article URL → raw_article.md → podcast.json → podcast.wav
              (trafilatura)    (local LLM)     (Kokoro-82M)
```

`podcast.json` is the contract between dialogue generation and TTS, which keeps the
TTS engine swappable. All artifacts for an article land together in
`articles/<slug>-<date>/`.

## Tech Stack

- **Language:** Python 3.12 (Kokoro requires <3.13 — spacy/misaki)
- **Article extraction:** trafilatura
- **Dialogue generation:** local vLLM behind LiteLLM (default working path);
  Ollama and Anthropic Claude backends also supported
- **TTS:** Kokoro-82M, local and free (`af_heart` host, `am_michael` expert)
- **Output:** WAV (no system dependencies; MP3 optional via ffmpeg, deprioritized)

## Getting Started

```bash
git clone git@github.com:csabakecskemeti/article-to-podcast-converter.git
cd article-to-podcast-converter
python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt

# Full pipeline on the local vLLM backend:
.venv/bin/python convert.py --url "https://example.com/article" --backend litellm

# Dialogue only — fastest iteration loop, skips TTS:
.venv/bin/python convert.py --url "https://example.com/article" --text-only
```

## Current Focus

**Dialogue quality.** The pipeline works end to end, but the writing doesn't read like
real conversation. The blocker is that quality isn't *measured* — every change is judged
by listening to a single episode. Building an eval harness first, then a local GGUF model
bake-off ranked by it.

See [dialogue quality plan](./docs/dialogue-quality-plan.md).

## Key Decisions

- **trafilatura** over newspaper3k: better extraction on modern sites
- **Local inference (vLLM/LiteLLM)** over cloud: no per-episode cost, and dialogue
  generation is the highest-volume step. Claude backend retained for comparison.
- **Kokoro-82M** over cloud TTS: local, free, no API key, and no system dependencies
  (espeak-ng is bundled by `espeakng-loader`)
- **JSON over markdown** as the TTS input: parsing generated markdown was fragile, and
  the structured format makes the TTS engine swappable
- **Truncate, never splice**, when a model starts repeating: splicing out a repeated
  block reorders the conversation (it once put the outro at turn 4). Output is always a
  contiguous prefix of what the model produced.
- **WAV over MP3** as default: MP3 needs ffmpeg, which was the only thing standing
  between a fresh clone and a working pipeline

## Related

- [Dialogue quality plan](./docs/dialogue-quality-plan.md)
- `claude-autopilot-sandbox` — searxng web search + Docker agent harness to reuse for
  agentic enrichment
