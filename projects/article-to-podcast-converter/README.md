---
slug: article-to-podcast-converter
created: 2026-06-29
---

# Article-to-Podcast Converter

Convert any article URL into a two-voice AI podcast conversation with TTS audio.

## Problem

Can't read while walking or commuting. Standard TTS is monotonous. Articles are dense — a dialogue format is more listenable and naturally adds pacing.

## Solution

Three-step pipeline: fetch article → generate host+expert dialogue with Claude → synthesize two-voice audio with OpenAI TTS.

## Tech Stack

- **Language:** Python 3.11+
- **Article extraction:** trafilatura
- **Dialogue generation:** Anthropic Claude (claude-sonnet-4-6)
- **TTS:** OpenAI TTS (alloy = host, onyx = expert)
- **Audio assembly:** pydub

## Getting Started

```bash
git clone git@github.com:csabakecskemeti/article-to-podcast-converter.git
cd article-to-podcast-converter
pip install -r requirements.txt

# Text only (no TTS cost):
python convert.py --url "https://example.com/article" --text-only

# Full audio output:
python convert.py --url "https://example.com/article"
# → output/<title>.mp3
```

## Current Focus

Getting good dialogue quality from the prompt. The text-only mode (`--text-only`) is the fastest iteration loop — test the dialogue before spending on TTS.

## Key Decisions

- **trafilatura** over newspaper3k: better extraction quality on modern sites
- **Claude for dialogue**: prompt-tunable, handles long articles well
- **OpenAI TTS** as default: simple API, good quality, two distinct voices available
- **pydub for assembly**: straightforward MP3 concatenation with silence between turns
