---
id: "010"
title: Client–server prototype (local server + Chrome extension)
status: done
priority: high
created: 2026-07-23
completed: 2026-07-24
---

# Client–server prototype (local server + Chrome extension)

Convert the article you're reading into a podcast on demand.

- FastAPI server: `POST /podcast {title,text,url}` → WAV. Reuses the pipeline.
- MV3 Chrome extension: in-page extraction + playback.
- Extension-text-or-server-fetch article resolution.
- Persistent Kokoro (loaded once at startup, reused).
- Verified end-to-end against local LM Studio (gpt-oss-20b) + Kokoro.

Branch `feat/podcast-server-chrome-ext`. Scope: whole-episode audio then play.
See repo `docs/client-server.md`. Follow-ups split into tasks 011–012.
