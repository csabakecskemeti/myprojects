---
slug: lorax
created: 2026-06-13
---

# LoRAX (Fork)

Fork of predibase/lorax — multi-LoRA inference server that scales to 1000s of fine-tuned LLMs.

## Problem

Serving many LoRA adapters efficiently without loading each as a separate model.

## Solution

LoRAX dynamically loads and serves multiple LoRA adapters on a single base model deployment.

## Tech Stack

- **Language:** Python
- **Purpose:** Multi-LoRA LLM serving
- **Upstream:** https://github.com/predibase/lorax

## Current State

Fork with 1 commit (Docker prerequisites README update). Primarily used for reference/testing.
