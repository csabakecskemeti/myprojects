---
slug: cc-token-saver-mcp
created: 2026-06-13
---

# CC Token Saver MCP

MCP server that delegates simple Claude Code tasks to a local LLM to reduce Claude API token usage.

## Problem

Claude Code uses expensive cloud tokens even for simple tasks (code snippets, docs, basic refactoring) that a local LLM could handle.

## Solution

MCP server exposing local LLM as tools. Claude Code tries the local LLM first for simple tasks, falls back to Claude for complex reasoning. Configurable via `.env` with OpenAI-compatible API.

## Tech Stack

- **Protocol:** MCP (Model Context Protocol)
- **Integration:** Claude Code
- **Backend:** Any OpenAI-compatible local LLM

## Current State

- [x] MCP server with tool exposure
- [x] Local LLM delegation for code generation, docs, reviews
- [x] Configurable via .env
