---
slug: article-to-podcast-converter
status: active
role: owner
repo: https://github.com/csabakecskemeti/article-to-podcast-converter
has_git: true
tags: [python, ai, podcast, tts, kokoro, vllm, litellm, local-llm]
created: 2026-06-29
updated: 2026-07-19
last_commit: 2026-07-19
my_commits: 18
total_commits: 18
parents: []
dependencies:
  hard: []
  soft:
    - claude-autopilot-sandbox
goals:
  - local-llm-self-sufficiency
---

# article-to-podcast-converter

**Status:** active | **Role:** owner | **Commits:** 18/18

## Quick Links

- [Tasks](./tasks/)
- [Notes](./notes/)
- [Internal Docs](./docs/)

## Repository

- Remote: https://github.com/csabakecskemeti/article-to-podcast-converter
- Branch: `feat/vllm-backend-e2e` (pushed, not yet merged to main)
- Local: ~/Documents/workspace/article-to-podcast-converter

## Pipeline

```
Article URL → raw_article.md → podcast.json → podcast.wav
              (trafilatura)    (local LLM)     (Kokoro-82M)
```

`podcast.json` is the handoff format between dialogue generation and TTS, which
makes the TTS engine swappable. All artifacts land together in
`articles/<slug>-<date>/`.

## Key Files

- `convert.py` — end-to-end CLI (`--url`, `--backend`, voices, names)
- `fetcher.py` — article URL → clean markdown (trafilatura)
- `dialogue.py` — article → `podcast.json` + `.md` + `_raw.txt`; backends: ollama / claude / litellm
- `synthesizer.py` — `podcast.json` → two-voice WAV (Kokoro-82M)
- `prompts/dialogue.txt` — prompt template

## Current State

- [x] Article fetcher
- [x] Dialogue generator — Ollama, Claude, and LiteLLM/vLLM backends
- [x] TTS synthesizer — Kokoro-82M local, two voices, WAV
- [x] JSON pipeline (markdown → JSON handoff)
- [x] End-to-end CLI working on local vLLM
- [ ] **Dialogue quality — the current weak point.** Coherent but doesn't read like
      real conversation. See [dialogue quality plan](./docs/dialogue-quality-plan.md)
- [ ] Evaluation harness (`evaluate.py`) — blocks all other quality work
- [ ] Local GGUF model bake-off via LM Studio
- [ ] Agentic web enrichment (reuse claude-autopilot-sandbox's searxng)
- [ ] Expressive TTS (higgs-tts-3-4b)

## Notes

Runs entirely on local inference — no cloud cost per episode. The Claude backend
exists but the working path is a local vLLM server behind LiteLLM.

## Internal Docs

- [Dialogue quality plan](./docs/dialogue-quality-plan.md)
