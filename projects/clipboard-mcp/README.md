---
slug: clipboard-mcp
created: 2026-06-13
---

# Clipboard MCP Server

MCP server allowing LLM models to save output directly to the system clipboard.

## Problem

Claude Code answers often include commands or values you need to immediately paste somewhere else — requiring manual copy.

## Solution

MCP server with tools for saving any text (commands, code, values) directly to the system clipboard. Tested on Linux and macOS.

## Tech Stack

- **Protocol:** MCP
- **Platform:** Linux, macOS

## Current State

- [x] Save command snippets to clipboard
- [x] Save code snippets
- [x] Save short answers (names, numbers, values)
- [x] Linux and macOS support
