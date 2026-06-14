---
slug: llm-router
created: 2026-06-13
---

# LLM Router

Dynamic model selection API that routes prompts to small or large LLMs based on complexity.

## Problem

Running all prompts through a large LLM (70B) wastes resources when simple queries (capital of France?) only need a small model (8B).

## Solution

BERT classifier analyzes prompt complexity and routes to LLaMA3-8B or LLaMA3-70B accordingly. Reduces latency, cost, and power consumption.

## Tech Stack

- **Language:** Python
- **Classifier:** BERT
- **Models:** LLaMA 3 8B, LLaMA 3 70B

## Current State

- [x] Complexity classifier
- [x] Dual-model routing API
