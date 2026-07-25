---
date: 2026-07-24
tags: [client-server, chrome-extension, inference-refactor, kokoro, dataset, handoff]
---

# Client–server prototype + dataset corpus complete

Two-part session (2026-07-23 → 24).

## Part 1 — dataset corpus finished

The `youtube-transcribe-diarize` corpus is **complete: 533 episodes** across
big-technology-podcast (86), dwarkesh-podcast (124), thediaryofaceo (323), all
through **stage 4** (uniform speaker+role and block/`kinds` annotations).

- Found 24 episodes missing stage 4 — root cause was upstream (transient yt-dlp
  403s at stage 1, one stalled at stage 2), not role assignment.
- Rebuilt stages 1–3 for all 24. Hit and worked around a real `batch.py` bug:
  single-video invocation under no-JS yt-dlp extraction re-probes the media URL
  into a 400-char id → `Errno 36`. Workaround: drive stages with the real watch URL.
- Ran stage 4 on the 24 against the litellm endpoint in batches, 0 failures —
  confirming the earlier DGX failures were load/concurrency (the other agent ran the
  whole corpus at once), not a hard outage.
- **Open quality caveat:** `format: panel` is over-assigned (thediaryofaceo ~46%,
  even a 2-speaker Yudkowsky interview). Needs a validation pass before training.

## Part 2 — client–server prototype (new branch)

Branch `feat/podcast-server-chrome-ext`. Convert the article you're reading into a
podcast: a **local server** + a **Chrome extension**.

- **Decoupled the LLM call** from dialogue logic → new `inference.py`
  (`LLMClient`: Ollama / Claude / OpenAICompat). `dialogue.py` delegates the call,
  strips `<think>` blocks; public API unchanged, CLI backends still work. This seam
  is shaped to later hold a tool-using agent (see task 003 / per the user's note the
  dialogue generator becomes a web-search-enriching agent).
- **Server** (`server/`, FastAPI): `POST /podcast {title,text,url}` → WAV. Reuses
  fetcher/dialogue/synthesizer. Extension-text-or-server-fetch fallback; head-truncate
  long articles (context overflow); LM Studio by default via `A2P_LLM_*`.
- **Extension** (`extension/`, MV3): in-page heuristic extraction + plays the WAV.
- **Persistent Kokoro**: `synthesizer.get_pipeline` caches the pipeline, warmed at
  server startup — loads once, not per request (verified).
- Docs: `docs/client-server.md` (architecture + quickstart + ordered TODO + build
  log), `server/README.md`, `extension/README.md`.

Decisions: prototype = whole-episode-then-play (streaming documented next);
extraction = extension + server fallback; LM Studio model is just for testing the
plugin idea (real/fine-tuned model later). DGX under maintenance → run on local LM
Studio.

## How to continue (cold-start)

1. Code branch `feat/podcast-server-chrome-ext` is **pushed** to origin (commits
   `864313e`, `868ca35`, `62d04c2`) — available on any machine.
2. Read `docs/client-server.md` → Quickstart to run it; TODO section for next steps.
3. Next biggest item: **per-turn streaming** (task 011). Then the **agent dialogue
   generator** (task 003).
