---
slug: ai-articles
created: 2026-06-13
---

# AI Articles Generator

AI-powered article generation system that creates well-researched articles on any topic.

## Problem

Generating high-quality articles requires research, drafting, reviewing, and revision — a multi-step process too slow to do manually at scale.

## Solution

LangChain + LangGraph multi-stage workflow: web research (DuckDuckGo) → draft → review → revise. Outputs Markdown and HTML with syntax highlighting.

## Tech Stack

- **Language:** Python
- **Frameworks:** LangChain, LangGraph
- **AI:** OpenAI API
- **Search:** DuckDuckGo

## Current State

- [x] Automated research via DuckDuckGo
- [x] Multi-stage workflow (research → draft → review → revise)
- [x] Markdown and HTML output
- [x] Retry logic with exponential backoff

## Getting Started

```bash
export OPENAI_API_KEY=...
pip install -r requirements.txt
python main.py
```
