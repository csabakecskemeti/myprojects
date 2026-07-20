---
id: "008"
title: Handle crosstalk merging two speakers into one turn
status: done
priority: high
created: 2026-07-19
completed: 2026-07-20
---

# Handle crosstalk merging two speakers into one turn

RESOLVED. Cause was a resolution loss in our own stage 3, not a diarization failure.

WhisperX assigns a speaker to every *word*, then collapses each segment to one
speaker by majority. Where a Whisper segment straddles a speaker change, that
collapse discards the minority speaker. `to_dialogue.py` read `seg["speaker"]` and
inherited the loss.

The word labels were correct all along. In o4pwkwg0zfk at 4135.5s a segment labelled
SPEAKER_00 has words split 21x SPEAKER_01 then 55x SPEAKER_00 — the guest's reply,
correct at word level, thrown away at segment level.

**4.5% of segments corpus-wide (1,590 / 35,088) span more than one speaker**, so this
affected a meaningful share of the data, not a rare edge case.

## Done

- [x] `turns_from_words()` builds turns from word-level labels
- [x] `absorb_fragments` no longer folds short turns across speaker boundaries; it
      removes a fragment only when the same speaker continues on both sides
- [x] Stage 3 re-run for all 57 episodes (no re-transcription needed)

## Note for next time

A first diagnosis claimed the cause was upstream in pyannote. It compared segment
labels against each other and never checked them against the word labels in the same
file. When a format carries labels at two resolutions, compare them before blaming
the upstream model.
