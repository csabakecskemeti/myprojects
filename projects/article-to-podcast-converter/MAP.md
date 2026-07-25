---
slug: article-to-podcast-converter
status: active
role: owner
repo: https://github.com/csabakecskemeti/article-to-podcast-converter
has_git: true
tags: [python, ai, podcast, tts, kokoro, vllm, litellm, local-llm, fastapi, chrome-extension]
created: 2026-06-29
updated: 2026-07-24
last_commit: 2026-07-24
my_commits: 22
total_commits: 22
parents: []
dependencies:
  hard: []
  soft:
    - claude-autopilot-sandbox
goals:
  - local-llm-self-sufficiency
---

# article-to-podcast-converter

**Status:** active | **Role:** owner | **Commits:** 22/22

## Quick Links

- [Tasks](./tasks/)
- [Notes](./notes/)
- [Internal Docs](./docs/)

## Repository

- Remote: https://github.com/csabakecskemeti/article-to-podcast-converter
- Branch: `feat/podcast-server-chrome-ext` (client–server prototype; **local-only,
  not pushed**). `main` has the dataset docs. `feat/vllm-backend-e2e` +
  `feat/dialogue-eval-harness` still exist, not merged.
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
- `dialogue.py` — dialogue *logic* (prompt + parse); delegates the LLM call
- `inference.py` — engine-agnostic `LLMClient` (the swappable LLM call)
- `synthesizer.py` — `podcast.json` → two-voice WAV (Kokoro-82M; pipeline cached)
- `server/` — FastAPI server: `POST /podcast` → WAV (prototype)
- `extension/` — MV3 Chrome extension: convert the page you're reading
- `prompts/dialogue.txt` — prompt template

## Current State

- [x] Article fetcher
- [x] Dialogue generator — Ollama, Claude, and LiteLLM/vLLM backends
- [x] TTS synthesizer — Kokoro-82M local, two voices, WAV
- [x] JSON pipeline (markdown → JSON handoff)
- [x] End-to-end CLI working on local vLLM
- [x] **Client–server prototype** — FastAPI server + MV3 Chrome extension, article
      you're reading → podcast WAV (task 010). Whole-episode audio; verified on local
      LM Studio + Kokoro. Repo `docs/client-server.md`.
- [x] **Decoupled inference engine** — `inference.LLMClient`, swap by config (task 012)
- [x] **Persistent Kokoro** — loaded once at server startup, reused
- [x] **Dataset corpus complete** — 533 eps across 3 shows, stages 1–4 (see sub-tool)
- [ ] **Per-turn audio streaming** — next big UX win on client–server (task 011)
- [ ] **Agent dialogue generator** — dialogue step becomes a web-search-enriching
      agent; fits the `LLMClient` seam (task 003)
- [ ] **Dialogue quality — the current weak point.** Coherent but doesn't read like
      real conversation. See [dialogue quality plan](./docs/dialogue-quality-plan.md)
- [x] Evaluation harness (`evaluate.py`) — coverage/drift/structure trustworthy;
      chatter unmeasurable by embeddings, flow blocked on judge (repo docs/evaluation.md)
- [ ] **Working LLM judge** — blocks the bake-off; local 8B judge fails self-check
- [ ] **Fix front-loading** — measured: coverage declines start→end in every episode
- [ ] Local GGUF model bake-off via LM Studio
- [ ] Expressive TTS (higgs-tts-3-4b)
- [ ] **Panel over-labeling** — stage-4 `format:panel` over-assigned; validate before training

## Notes

Runs entirely on local inference — no cloud cost per episode. The Claude backend
exists but the working path is a local vLLM server behind LiteLLM.

## Internal Docs

- [Dialogue quality plan](./docs/dialogue-quality-plan.md)
- Client–server architecture + handoff: repo `docs/client-server.md`
- Detailed eval findings: repo `docs/evaluation.md`

## Sub-tool: youtube-transcribe-diarize

Self-contained, agent-agnostic tool (formerly `dataset/`). YouTube URL ->
speaker-labeled dialogue JSON via WhisperX+pyannote (GPU) + LLM role assignment.
Has its own AGENTS.md, CLAUDE.md, and two Agent Skills (setup, run) following the
Anthropic skill standard.

**Corpus complete (2026-07-24): 533 episodes** — big-technology (86), dwarkesh (124),
thediaryofaceo (323), all through stage 4 with uniform speaker+role and block/`kinds`
annotations. Serves the fine-tune target for dialogue style. Open caveat:
`format: panel` over-assigned (validate before training). DGX inference is under
maintenance; stage 4 / generation currently runs on this machine's LM Studio.
