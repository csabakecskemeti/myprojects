---
date: 2026-07-21
tags: [dataset, ads, roles, validation, ground-truth]
---

# Ad-annotation validation against ground truth (Nick Lane / Dwarkesh)

First validation of assign_roles_ads.py against a PUBLISHED reference transcript.
Episode 0GMWxuYuxJI (Dwarkesh x Nick Lane). Test instance copied to
podcasts/test/nick-lane/0GMWxuYuxJI/ (audio omitted; REFERENCE.md holds ground truth
from https://www.dwarkesh.com/p/nick-lane).

## Ad detection — strong recall, moderate precision

Ground-truth sponsors (from the published transcript): **Gemini in Sheets, Labelbox,
Lighthouse** (3).

Result: **recall 3/3 = 100%**, **precision 3/5 = 60%**.
- Found all three real sponsors: Gemini/Sheets [t39], Labelbox [t59-61], Lighthouse [t95].
- 2 false positives, both the SAME failure mode seen on the DoaCEO test:
  - the guest INTRODUCTION [t3] flagged as a sponsor (even mislabeled "sponsor:
    Nick Lane" — the guest's name, not a sponsor).
  - the SIGN-OFF [t101] flagged as an "announcement".

So the recurring precision issue is intros and outros, not mid-conversation content.
That is a fixable, well-defined error class — the prompt can be told the host's
guest-introduction and the closing thanks are NOT ads.

Note on position: the published transcript groups all sponsor reads near the start;
our timestamps place them at t39/t59/t95 (spread through the audio). Our positions
reflect the actual audio; the transcript groups them editorially. Not an error.

## Role assignment — a real error, confirmed by ground truth

Ground truth: 2 speakers (Dwarkesh=host, Nick Lane=guest) => interview.
Our result: **3 speakers, labeled "panel"** (HOST + GUEST_1 + GUEST_2).

Cause: diarization SPLIT Nick Lane's voice into two clusters (SPEAKER_01 and
SPEAKER_02) — almost certainly the cold-open teaser clip vs the interview body — and
role assignment faithfully labeled the two clusters as two guests, so format became
"panel". The HOST was still correctly identified (SPEAKER_00 = Dwarkesh).

This is a diarization limitation surfacing as a role error, and it means some of the
corpus's "panel"/3-speaker episodes may actually be 2-speaker interviews with a split
guest. Worth auditing: check 3-speaker episodes where two "guests" barely overlap in
time (a teaser clip vs the body) — a sign of one person split.

## Takeaways / next
- Ad detection is good enough to be useful now (100% recall on real sponsors); the
  60% precision is dominated by two predictable false positives (intro, sign-off).
  Fix: extend the AD_PROMPT to exclude guest intros and sign-offs. Re-test.
- Add a validation harness: run on the handful of Dwarkesh episodes that have
  published transcripts, score recall/precision automatically.
- Investigate diarization over-split (guest-in-two-clusters). Options: a post-pass
  that merges speaker clusters with (near) zero temporal overlap and similar role, or
  feeding max-speakers=2 for known 2-person shows. This also inflated the corpus's
  panel count.
- Sponsor-name extraction is unreliable ("sponsor: Nick Lane"); treat the sponsor
  field as best-effort, not authoritative.

## UPDATE 2026-07-22 — generalized to block classifier; re-validated

Per Csaba's reframe: don't "fix" the diarization split by merging; the real goal is
to LABEL the non-conversational blocks regardless of speaker. Two mechanisms:
speaker-level (a split intro/ad cluster -> ANNOUNCER role) and content-level (a
block bundled into the host's voice -> found by reading the turns).

Generalized `assign_roles_ads.py` from ad-only detection to a block classifier over
kinds: ad / announcement / intro / trailer / signoff (None = conversation). Output
now carries `blocks`, `block_kind_counts`, per-turn `block_kind`, with `ad_segments`
as a convenience subset.

Re-validated on Nick Lane:
- **Ads: 3/3 real sponsors (Gemini/Sheets, LabelBox, Lighthouse), 0 false positives
  -> precision 100% (was 60%), recall 100%.**
- The two former false positives are now correctly TYPED, not suppressed:
  intro [t2-3] -> `intro`, sign-off [t101] -> `signoff`.
- Also caught an `announcement` [t97] (audience/channel plug).
- 93/102 turns are clean conversation.

So the intro/sign-off fix and the richer block annotation were the same change. The
diarization split is no longer treated as an error to fix — whichever way a block
lands (own cluster -> ANNOUNCER, or bundled -> content pass), it gets labelled.

Minor residual: the cold-open teaser at t0-1 was folded into the intro block rather
than typed `trailer`; boundary nuance, not a miss of substance.
