---
date: 2026-07-21
tags: [dataset, roles, ads, annotation, status]
---

# Where we are: role assignment + ad/announcement annotation

Two related capabilities in youtube-transcribe-diarize (stage 4). Merged to main.

## 1. Speaker role assignment — DONE across the corpus

`assign_roles.py` labels each diarized SPEAKER_xx as HOST / GUEST_1..N (co-hosts
allowed as HOST_1..N), plus derives format (interview/panel/cohosted) and
structure (asymmetric vs symmetric). Output: `speaker_roles.json` per episode.

Coverage — 509/509 episodes, 100%:
- big-technology-podcast: 85/85
- dwarkesh-podcast: 121/121
- thediaryofaceo: 303/303

Decided by an LLM, not a heuristic — every mechanical signal (talk-time,
first-speaker, self-intro regex) disagreed on real episodes. Labels come back
"high confidence" almost always, including ambiguous cases, so confidence is not
calibrated; a spot-check against audio is still owed but the coverage is complete.

## 2. Ad / announcement annotation — BUILT, tested on 1 episode, NOT rolled out

`assign_roles_ads.py` — an ad-aware variant of stage 4. **Reframed per Csaba: ads
are LABELLED and KEPT, not removed.** The goal model turns an article into a
podcast where we may want to *inject ads on demand*, so the fine-tune must see
real ad reads marked as such; filtering is left to the training pipeline.

Handles both shapes of ad:
- dedicated announcer voice -> role ANNOUNCER (kept, first-class)
- host-read ad (common case) -> caught at the TURN level; each ad segment records
  reader_role=HOST, so "the host read this himself" is explicit

Output: `speaker_roles_ads.json` (separate from speaker_roles.json, non-destructive):
- per-turn `turn_annotations` aligned 1:1 with dialogue turns:
  {is_ad, ad_kind, sponsor, role, ad_segment}
- `ad_segments`: {turns, kind, sponsor, speaker, reader_role,
  position(pre/mid/post-roll), words}
- counts: ad_turn_count, clean_turn_count, host_read_ad_count

Detection: cheap lexical gate finds candidate windows -> LLM reads them for exact
ad ranges + sponsor. `--scan-all` scans every window (max recall). `--think`
enables reasoning (24k output budget) — tightens boundaries, ~27x slower, does not
fix inherently ambiguous cases.

### Status / what's left
- Tested on ONE episode (thediaryofaceo/qgeQ5kMVwRA): correctly flagged a host-read
  Fiverr Pro ad, a subscribe announcement, a guest sponsor intro — with reader_role.
- **Precision unvalidated.** That one episode had ~2 false positives (guest praising
  Netflix as a stock; a sign-off read as an announcement). Because we label not
  remove, tolerable — but must be measured before a corpus run.
- speaker_roles_ads.json exists for 1 episode only; NOT run across the 509.
- Bugs fixed while building (all had made it silently report "0 ads"):
  required_key hardcoded to "roles" rejected valid {"ads":...} JSON (the real one);
  reasoning model truncated at low max_tokens; per-window exceptions swallowed.

### Next steps (TODO in youtube-transcribe-diarize/TODO.md)
1. Precision/recall spot-check on 5-10 ad-heavy episodes (DoaCEO is the natural set).
2. Add a per-segment confidence so training can threshold weak detections.
3. Decide gate vs --scan-all, and whether --think is worth it, for the corpus run.
4. Run across the corpus; optionally fold ad-awareness into the default stage 4.
5. Note: assign_roles.py now has a 10s inter-call sleep (DGX protection) which the
   ad path inherits — many window calls/episode makes a corpus ad run slow; consider
   making the rate limit configurable.
