---
id: "004"
title: Evaluate higgs-tts-3-4b for expressive delivery
status: active
priority: low
created: 2026-07-19
---

# Evaluate higgs-tts-3-4b for expressive delivery

https://huggingface.co/bosonai/higgs-tts-3-4b as a Kokoro replacement. Kokoro is fast and
dependency-light but flat — narrates evenly where a podcast needs emphasis, laughter, and
emotional range.

Deliberately lower priority than the writing work: expressive TTS can't rescue stiff
dialogue.

## Acceptance Criteria

- [ ] Benchmark VRAM and synthesis time per episode (~4B vs Kokoro's 82M)
- [ ] A/B against Kokoro on the same podcast.json
- [ ] Only synthesizer.py changes (it consumes podcast.json)
