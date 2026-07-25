---
id: "012"
title: Decouple dialogue logic from the inference engine
status: done
priority: high
created: 2026-07-23
completed: 2026-07-24
---

# Decouple dialogue logic from the inference engine

Separate "build the prompt / parse the answer" from "call the LLM" so the engine is
swappable by config, not code — and so the dialogue step can later become a
tool-using agent (task 003) with no change to dialogue logic.

- New `inference.py`: `LLMClient` interface + `OllamaClient` / `ClaudeClient` /
  `OpenAICompatClient`; `make_client` factory.
- `dialogue.generate_dialogue` now delegates via a client (injectable), strips
  `<think>` blocks; public API unchanged, CLI backends preserved
  (`litellm` → OpenAI-compatible client).
