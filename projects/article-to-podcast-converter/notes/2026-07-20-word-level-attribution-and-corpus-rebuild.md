---
date: 2026-07-20
tags: [dataset, diarization, whisperx, corpus, debugging]
---

# Word-level attribution fix, role redesign, corpus rebuild

## The bug that mattered

Crosstalk was merging two speakers into one turn — a sign-off, the guest's reply,
and the host's closing all emitted as one `SPEAKER_00` turn.

**My first diagnosis was wrong.** I compared segment-level speaker labels against
each other, saw they all agreed, and concluded pyannote had failed upstream. Csaba
checked the word level and found the labels were correct there all along.

Actual cause: WhisperX assigns a speaker to every *word*, then collapses each
segment to a single speaker, effectively by majority. Where a Whisper segment
straddles a speaker change, the minority speaker is discarded. Stage 3 read
`seg["speaker"]` and inherited that loss.

Concrete case (o4pwkwg0zfk @ 4135.5s): segment labelled SPEAKER_00, words split
21x SPEAKER_01 then 55x SPEAKER_00. The guest's reply was correctly attributed and
thrown away.

**Scale: 4.5% of segments corpus-wide (1,590 / 35,088) span more than one speaker.**
Not an edge case.

Fix: `turns_from_words()` builds turns from word labels, merging only adjacent
words that share a speaker.

**Method lesson:** I had computed the mixed-word statistic *myself* and read it as
"a detection signal for a diarization problem" rather than as evidence the segment
labels were lossy. The data contradicting me was in my own output. When a format
carries labels at two resolutions, compare them before blaming the upstream model.

## Role assignment: heuristics out, LLM in

Csaba's call, and correct. `to_dialogue.py` had guessed "whoever talks least is the
host". Across six episodes, three plausible signals disagreed in five:

| episode | first speaker | least talkative | most questions |
|---|---|---|---|
| 7Z1kn6JNUbE | SPEAKER_01 | SPEAKER_02 | SPEAKER_01 |
| c65JYf7wa_I | SPEAKER_00 | SPEAKER_00 | SPEAKER_01 |
| i-mRanTY6c4 | SPEAKER_01 | SPEAKER_00 | SPEAKER_00 |
| pj7TzkII7hk | SPEAKER_01 | SPEAKER_00 | SPEAKER_01 |
| qA17304wOiw | SPEAKER_00 | SPEAKER_01 | SPEAKER_00 |
| rJ6YdXhvGpY | SPEAKER_02 | SPEAKER_00 | SPEAKER_00 |

Each fails structurally: talk volume misreads panel shows (host out-talks any single
guest, not all combined); first-speaker breaks on cold-open teaser clips of the
guest; self-introduction regex matched nothing in all six.

Now: stage 3 stays mechanical (raw SPEAKER_xx + per-speaker stats), stage 4
(`assign_roles.py`) uses an LLM. Separating them also means roles can be re-run or
upgraded without redoing transcription. **Written but not yet validated** — given
the local 8B judge failed the shuffle test in evaluate.py, verify before trusting it
across 61 episodes.

Also fixed `absorb_fragments`, which folded short turns into the previous turn
regardless of speaker, misattributing brief interjections. Now only removes a
fragment when the same speaker continues on both sides.

## Corpus rebuild in progress

Deleted all transcript.json + dialogue.json, kept audio.wav (58 files) and
meta.json. Reprocessing all 61 episodes from local audio.

Rationale beyond certainty: the first episode was transcribed with
`--max-speakers 2` before the default became 3, so the corpus was diarized under
inconsistent settings. The rebuild makes every episode identical in code and config.

## Batch reliability gap

5 of 61 episodes failed with "audio download failed" — transient, almost certainly
YouTube rate-limiting after ~56 rapid downloads. Re-running the exact download later
succeeded. Failure isolation worked (the other 56 completed), but `batch.py` has no
retry/backoff, so a blip costs an episode until someone re-runs manually. Task 009.

I had also reported "batch reached 61/61" as a clean finish without checking
batch_log.json — it reached the end of the list with 5 failures along the way.
