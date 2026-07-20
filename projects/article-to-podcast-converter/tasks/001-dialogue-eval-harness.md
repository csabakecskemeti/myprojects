---
id: "001"
title: Build evaluate.py dialogue quality harness
status: done
priority: high
created: 2026-07-19
completed: 2026-07-19
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

## Outcome (2026-07-19)

Built. Coverage / drift / structure work and are trustworthy. Two axes did NOT
land as planned:

- **Chatter is unmeasurable by embeddings.** Cosine similarity measures vocabulary
  overlap, so it ranks the best analogy in the episode as filler and a joke as
  substance. Delegated to the LLM judge.
- **Flow is blocked.** The local 8B judge returned byte-identical scores for a
  real episode, a shuffled one, and a 6-turn fragment. `--judge-self-check` was
  added to catch this; it currently FAILs.

Full write-up: repo `docs/evaluation.md`.
