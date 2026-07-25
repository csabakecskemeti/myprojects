---
id: "011"
title: Per-turn audio streaming (server → extension)
status: active
priority: high
created: 2026-07-24
---

# Per-turn audio streaming (server → extension)

The biggest UX win on the client–server path. Today the server generates the whole
episode before returning any audio; stream it instead.

- Server: after `generate_dialogue`, synthesize turn-by-turn and emit each turn's
  audio as a self-contained segment over a chunked response / SSE. Kokoro is fast
  enough to stay ahead of playback.
- Extension: read the response as a stream; `decodeAudioData` each segment and
  schedule on one `AudioContext` timeline for gapless playback (preferred over MSE
  or a single growing `<audio>` WAV).
- Optional later: stream dialogue generation too (turns as the LLM emits them).

Design is written up in repo `docs/client-server.md` → TODO §1.
