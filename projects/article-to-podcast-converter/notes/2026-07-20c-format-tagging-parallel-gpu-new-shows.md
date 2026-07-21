---
date: 2026-07-20
tags: [dataset, format, gpu, parallel, corpus, batch]
---

# Format tagging, two-GPU parallelism, new shows

## Corpus now spans two shows

- **Big Technology Podcast**: 82 episodes (two playlists — main feed + top videos).
  1 permanently unavailable, 1 flaky download dropped. Combined: 6,637 turns,
  ~794k words. Structure: 65 asymmetric, 17 symmetric.
- **Dwarkesh Podcast**: processing started — 133 episodes, 216 hours of long-form
  interviews (mean 97 min, longest 272). Asymmetric host-guest, on-target for the
  fine-tune. Running sharded across both GPUs.

## Episode format classification (stage 4)

Derived from role counts, no extra LLM call:
- asymmetric: interview, panel (host draws out guests)
- symmetric: cohosted, cohosted_with_guest (peers)

Matters because the two shapes teach different voices; mixing them yields an averaged
"host" who both interrogates and lectures. Filter on `structure` when building
training data. `--retag` backfills onto existing assignments.

The co-hosted episodes were Csaba's catch: a "2 hosts, 0 guests" assignment on
5WrO5pAI-UU looked wrong but was right — Ranjan Roy is a recurring co-host, not a
guest, on the Friday news format. The label was correct; what was missing was
*distinguishing* that format from interviews. Now tagged.

Note: dominant-speaker word share does NOT separate the groups (asymmetric 0.581,
symmetric 0.548). Good — shows the LLM reads conversation, not talk volume — but also
means the label is unvalidated judgement.

## Two-GPU parallelism

`--shard I/M` partitions a playlist; per-shard lock + log avoid the shared-state race.
GPU chosen by CUDA_VISIBLE_DEVICES (inherited by the transcribe subprocess), so no
device flag needed:

  CUDA_VISIBLE_DEVICES=0 batch.py ... --shard 1/2 &
  CUDA_VISIBLE_DEVICES=1 batch.py ... --shard 2/2 &

Whisper large-v3 + pyannote fit on the 5090's 32GB. GPU0 = RTX PRO 6000 (96GB),
GPU1 = RTX 5090 (32GB).

## build_dataset.sh

One-command runner: `./build_dataset.sh "<playlist>" "<Show>"`. Preflights venv +
HF_TOKEN, runs all 4 stages, prints a corpus summary. The "loud failure" fix proved
out: a run with 3 failures printed "3 EPISODE(S) FAILED — corpus is INCOMPLETE"
rather than reading as clean.

## Reliability observations

- Transient "audio download failed" recurs (~3-5% of episodes), still no retry/backoff
  (task 009). Re-running usually recovers them.
- Hit a stale-lock false positive: a lock's PID was reused by an unrelated process, so
  acquire_lock saw it "alive" and a retry stalled. The PID-liveness check is not
  sufficient on its own; consider also checking lock age or writing a start timestamp.
- One episode failed with an ffprobe rename error on the .part file — flaky, dropped
  per "sufficient examples, not all".
