---
slug: llm-forwarder
created: 2026-06-13
---

# LLM Forwarder

Python package for forwarding chat requests to OpenAI-compatible API endpoints with custom prompt injection.

## Problem

Need to intercept and modify LLM requests before they reach the model — injecting context, pre-processing prompts, or routing to different endpoints.

## Solution

Configurable proxy server that forwards OpenAI-compatible chat requests with a customizable prompt-handling function.

## Tech Stack

- **Language:** Python
- **API:** OpenAI-compatible endpoints

## Current State

- [x] Configurable server address and port
- [x] Flexible OpenAI API integration
- [x] Customizable prompt-handling function
