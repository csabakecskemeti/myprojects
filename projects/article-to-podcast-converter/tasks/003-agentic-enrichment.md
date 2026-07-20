---
id: "003"
title: Agentic web enrichment, faithful to the article
status: active
priority: medium
created: 2026-07-19
---

# Agentic web enrichment, faithful to the article

Research selected points on the web to add depth, while staying true to the source
article. Enrichment must support the article, never drift into a different story.

Reuse `claude-autopilot-sandbox` (code: ~/Documents/workspace/local-claude-docker) —
it already has searxng web search, Docker autonomy, supervisor, and Langfuse tracing.

## Acceptance Criteria

- [ ] Decide: purpose-built agent (easier to constrain) vs existing harness
      (Claude Code / Hermes — free tool-use, retries, tracing)
- [ ] Enrichment gated on the fidelity score so added facts can't drift
- [ ] Measurable improvement in coverage/flow without a fidelity regression

Depends on: 001 (fidelity gate)
