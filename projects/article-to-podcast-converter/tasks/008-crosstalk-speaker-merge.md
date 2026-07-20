---
id: "008"
title: Handle crosstalk merging two speakers into one turn
status: active
priority: high
created: 2026-07-19
---

# Handle crosstalk merging two speakers into one turn

When speakers talk over each other or hand off rapidly, pyannote attributes one
person's words to the other, producing a single turn that actually contains a short
exchange between both. Found at the end of `o4pwkwg0zfk`: sign-off, guest reply, and
host closing all emitted as one SPEAKER_00 turn.

**Cause is upstream.** All raw segments in that window are labelled SPEAKER_00 by
pyannote itself. `merge_segments` correctly merged consecutive same-speaker segments
— the labels were already wrong. Fixing merge logic will not help.

**Detection signal already exists in the data.** WhisperX labels every *word*, and
those labels sometimes disagree inside one segment. In o4pwkwg0zfk, 18/652 segments
(2.8%) contain words attributed to more than one speaker — a cheap local flag needing
no LLM to find candidates.

## Acceptance Criteria

- [ ] Measure the mixed-word-label rate across the whole corpus (is ~3% typical?)
- [ ] Decide and implement one of:
      - flag + drop suspect turns (cheapest; ~3% loss is fine, bad turns are poison)
      - split at the word-level label change (mechanical, inherits bad labels)
      - LLM repair of flagged turns only — must re-attribute, never rewrite text
      - enable pyannote overlapping-speech detection / newer checkpoint (best upstream)
- [ ] Fix `absorb_fragments`: it folds sub-25-char turns into the previous turn
      WITHOUT checking speaker, so short interjections get misattributed. Same class
      of error, separate cause, my bug rather than pyannote's.
