---
slug: ai-utils
created: 2026-06-13
---

# AI Utils

General AI utilities for running models and applying LoRA weights from checkpoints.

## Problem

Need a simple way to chat with base models or LoRA fine-tuned models, with option to merge weights.

## Solution

`generate.py` — runs HuggingFace models, applies LoRA checkpoint weights, supports base model chat, LoRA chat, and merging LoRA weights into the base model.

## Tech Stack

- **Language:** Python
- **Framework:** HuggingFace Transformers, PEFT

## Getting Started

```bash
# Chat with base model
python generate.py -b -bm DevQuasar/vintage-nextstep_os_systemadmin-ft-phi2

# Chat with LoRA fine-tuned model
python generate.py -bm <base_model> -c <checkpoint>

# Save merged model
python generate.py -bm <base_model> -c <checkpoint> -sm -msd <output_dir>
```
