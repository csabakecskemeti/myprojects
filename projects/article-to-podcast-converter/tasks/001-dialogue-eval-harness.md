---
id: "001"
title: Build evaluate.py dialogue quality harness
status: active
priority: high
created: 2026-07-19
---

# Build evaluate.py dialogue quality harness

Score a `podcast.json` against its `raw_article.md`. **Blocks all other quality work** —
without a score, model and prompt changes are tuned on vibes.

## Acceptance Criteria

- [ ] Coverage: article split into sections/claims, embedded (nomic-embed via LM Studio),
      uncovered sections reported. Watch for front-loading on long articles.
- [ ] Flow: LLM-judge rubric + proxies (turn-length distribution, Q/A alternation,
      responsiveness to prior turn)
- [ ] Chatter: informative vs filler turn ratio, with a target band
- [ ] Fidelity: claims unsupported by the article
- [ ] Per-axis + overall score, so changes are A/B testable
- [ ] Runs over the accumulated `podcast_raw.txt` corpus
