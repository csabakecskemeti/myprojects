---
slug: dq-int4-to-bf16-dequant
created: 2026-06-13
---

# DQ INT4 to BF16 Dequantizer

INT4 dequantization to BF16 for models like Kimi-K2-Thinking, enabling GGUF conversion.

## Problem

Models like moonshotai/Kimi-K2-Thinking are released in INT4 quantized format. llama.cpp's converter doesn't support INT4 directly, requiring dequantization to BF16 first.

## Solution

Inspired by DeepSeek V3's FP8→BF16 dequantizer. Converts INT4 safetensors to BF16, generates the safetensors index JSON. Includes a debug utility (`safetensors_diff.py`) for comparing original vs converted tensors.

## Tech Stack

- **Language:** Python
- **Libraries:** torch, safetensors, tqdm

## Current State

- [x] INT4 → BF16 conversion
- [x] Safetensors index generation
- [x] Debug diff utility

## Getting Started

```bash
python int4_cast_bf16_fixed.py --input-int4-hf-path <path> --output-bf16-hf-path <path>
```
