---
slug: article-to-podcast-converter
status: active
role: owner
repo: https://github.com/csabakecskemeti/article-to-podcast-converter
has_git: true
tags: [python, ai, podcast, tts, claude, openai]
created: 2026-06-29
updated: 2026-06-29
last_commit: 2026-06-29
my_commits: 1
total_commits: 1
parents: []
dependencies:
  hard: []
  soft: []
goals: []
---

# article-to-podcast-converter

**Status:** active | **Role:** owner | **Commits:** 1/1

## Quick Links

- [Tasks](./tasks/)
- [Notes](./notes/)
- [Internal Docs](./docs/)

## Repository

- Remote: https://github.com/csabakecskemeti/article-to-podcast-converter
- Branch: main
- Local: ~/Documents/workspace/article-to-podcast-converter

## Pipeline

```
Article URL → trafilatura fetch → Claude dialogue generation → OpenAI TTS → MP3
```

## Key Files

- `convert.py` — CLI entrypoint (`--url`, `--text-only`)
- `fetcher.py` — article URL → clean text (trafilatura)
- `dialogue.py` — text → HOST/EXPERT script (Claude)
- `synthesizer.py` — script → two-voice MP3 (OpenAI TTS: alloy + onyx)
- `prompts/dialogue.txt` — prompt template

## Current State

- [x] Initial project structure
- [x] Article fetcher
- [x] Dialogue generator (Claude)
- [x] TTS synthesizer (OpenAI, two voices)
- [x] CLI end-to-end
- [ ] Test with real articles and tune prompt
- [ ] Evaluate TTS voice quality
- [ ] Error handling and edge cases
