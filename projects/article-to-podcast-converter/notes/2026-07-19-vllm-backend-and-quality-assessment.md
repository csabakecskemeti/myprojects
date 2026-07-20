---
date: 2026-07-19
tags: [vllm, litellm, kokoro, python-env, dialogue-quality]
---

# vLLM backend landed; dialogue quality is now the bottleneck

## Shipped (branch `feat/vllm-backend-e2e`, 6 commits, pushed)

Got the whole pipeline running end to end on local inference:
fetch → dialogue via local vLLM → Kokoro TTS → WAV.

- LiteLLM/vLLM backend for dialogue generation
- Fixed `convert.py`, which had drifted out of sync with its own modules and was broken
- All artifacts now land together in `articles/<slug>-<date>/` instead of a stray `output/`
- Default expert voice `am_adam` → `am_michael` (am_adam is graded **F+** in Kokoro's own
  quality table — one of the worst in the set)
- MP3 deprioritized; WAV is the documented path and needs zero system dependencies

## Python env gotcha (cost the most time — worth remembering)

pyenv-built Python 3.12 was missing `_ctypes`, which broke `soundfile` and therefore
Kokoro.

**Root cause:** pyenv compiles CPython from source, and stdlib C extensions are built
*only if the matching dev headers are present*. A missing header **does not fail the
build** — it prints a warning and silently produces a Python without that module, which
then explodes later at import time. The MacBook this was originally developed on had the
libs via Homebrew, so it never surfaced there.

Fix: `sudo apt-get install -y libffi-dev liblzma-dev`, then rebuild
`pyenv install 3.12.13` and recreate the venv.

Also learned: `espeak-ng` does **not** need separate installation — `espeakng-loader`
(pulled in by `kokoro`) bundles `libespeak-ng.so`.

## Bug worth not repeating

Local models sometimes emit the whole episode, then repeat it verbatim. My first fix
excised the repeated block and spliced head to tail — which **reordered the conversation
and put the outro at turn 4**, replying to a guest who hadn't spoken yet. Splicing is
wrong: removing a block from the middle joins the head to a tail that doesn't
conversationally follow.

Correct fix: **truncate, don't splice.** Keep the first clean pass. The output is now
always a *contiguous prefix* of the model's turns, which makes reordering structurally
impossible rather than merely unlikely.

Also added: raw model output is saved to `podcast_raw.txt`. Post-processing is lossy, and
without the original these artifacts weren't diagnosable after the fact.

## Next: quality, and measuring it

The dialogues are workable but not amazing — coherent, but they don't read like real
conversation. Nothing is currently *measured*, so every change is judged by listening to
one episode.

Plan in [dialogue-quality-plan](../docs/dialogue-quality-plan.md). Headline findings:

- **LM Studio already serves an OpenAI-compatible API on `localhost:1234/v1`** with 10
  local models (~119 GB), so the existing `litellm` backend can drive a GGUF bake-off
  with only an env change — no new code path needed.
- **`claude-autopilot-sandbox` already has searxng web search** plus Docker autonomy and
  Langfuse tracing, so the agentic enrichment idea should reuse it rather than build
  search from scratch.
- Suspicion: the stiff writing comes from using instruct/reasoning/coding models, which
  narrate rather than converse. Worth testing creative/character-writing tunes.
