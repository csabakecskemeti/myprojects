---
slug: llm-qlora
created: 2026-06-13
---

# LLM QLoRA Fine-Tuning

QLoRA fine-tuning toolkit for LLMs including Llama 3 8B.

## Problem

Fine-tuning large LLMs requires significant GPU memory. QLoRA makes it feasible on consumer hardware.

## Solution

Config-driven training script supporting QLoRA. Example: fine-tune Llama3-8B on wizard_vicuna_70k dataset.

## Tech Stack

- **Language:** Python 3.8+
- **Method:** QLoRA (Quantized LoRA)
- **Models:** Llama 3, others

## Getting Started

```bash
pip install -r requirements.txt
python train.py configs/llama3_8b_chat_uncensored.yaml
```
