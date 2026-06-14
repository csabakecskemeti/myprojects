---
slug: unsloth-ft-example
created: 2026-06-13
---

# Unsloth Fine-Tuning Example

Working Unsloth fine-tuning example with Vicuna dataset.

## Problem

Setting up Unsloth fine-tuning correctly with the right conda environment and dependencies is tricky.

## Solution

Documented, working example based on unslothai's README, fine-tuning with Vicuna dataset.

## Tech Stack

- **Language:** Python
- **Framework:** Unsloth
- **Dataset:** Vicuna

## Getting Started

```bash
conda create --name unsloth_env \
    python=3.11 \
    pytorch-cuda=12.1 \
    pytorch cudatoolkit xformers -c pytorch -c nvidia -c xformers \
    -y
conda activate unsloth_env
pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
```
