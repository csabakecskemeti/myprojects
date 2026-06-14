---
slug: ministral-3-dequantizer-fp8-bf16
created: 2026-06-13
---

# Mistral FP8 to BF16 Dequantizer

Tool to dequantize FP8-quantized Mistral/Ministral models to BF16 for GGUF conversion with llama.cpp.

## Problem

Official Mistral Instruct models (e.g., Ministral-3-3B-Instruct-2512) are released in FP8 quantized format. llama.cpp can't convert FP8 directly — needs BF16 first.

## Solution

Dequantizes FP8 safetensors to BF16, enabling standard GGUF conversion pipeline via llama.cpp.

## Tech Stack

- **Language:** Python
- **Libraries:** torch, safetensors, tqdm

## Getting Started

```bash
pip install torch safetensors tqdm
python dequantize.py --input <fp8_model_path> --output <bf16_output_path>
```
