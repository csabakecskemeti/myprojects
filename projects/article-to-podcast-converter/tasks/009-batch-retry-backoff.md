---
id: "009"
title: Add retry with backoff to batch.py downloads
status: active
priority: medium
created: 2026-07-20
---

# Add retry with backoff to batch.py downloads

5 of 61 episodes failed with "audio download failed" during the first full run —
transient, almost certainly YouTube rate-limiting after ~56 rapid downloads.
Re-running the same URL later succeeded immediately.

Failure isolation worked as designed (the other 56 finished), but there is no retry,
so each blip costs an episode until someone notices and re-runs. For genuinely
unattended overnight runs this needs handling.

## Acceptance Criteria

- [ ] Retry failed downloads 2-3 times with exponential backoff
- [ ] Optional small delay between episodes to avoid tripping rate limits at all
- [ ] Distinguish permanent failures (removed, private, age-gated) from transient
      ones and don't waste retries on the former
- [ ] Batch summary line surfaces the failure count prominently — a run that ends
      with failures should not read as a clean finish

## Update 2026-07-20

Recurred on the top-videos playlist (3 of 24 failed, 2 transient). Also found a
related lock bug: a stale .batch.lock whose PID had been reused by an unrelated
process passed the liveness check, so a retry stalled at stage 1. Add a start
timestamp or age check to acquire_lock so a reused PID can't wedge future runs.
