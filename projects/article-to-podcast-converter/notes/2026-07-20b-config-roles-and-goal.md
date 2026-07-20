---
date: 2026-07-20
tags: [dataset, config, llm, roles, batch, goal]
---

# Goal recorded; config-driven role assignment; batch made honest

## The goal, now written down

**Build a training corpus for fine-tuning a model that writes podcast dialogue in the
style of high-quality human shows.** Stated at the top of `dataset/README.md` and in
STATUS §4.4.

Worth recording because it sets the quality bar. Errors in speaker attribution or
turn boundaries do not merely lose data — they teach the model the wrong thing (one
persona speaking both halves of an exchange, or uniformly-sized turns). Hence the
pipeline's bias toward dropping suspect material rather than silently repairing it.

## LLM is now configurable (`config.json` + `config.py`)

Defaults point at the same local vLLM endpoint and `Qwen/Qwen3.6-35B-A3B-FP8` the
main project already uses for dialogue generation. Profiles for `lmstudio` and
`claude` selectable via `--llm-profile`. Resolution order: config.json -> env var ->
CLI flag. Secrets stay in env vars *named by* the config, never in the committed file.

## Role assignment reworked

Writes a separate `speaker_roles.json` per episode rather than editing
`dialogue.json`. Keeps the mechanical extraction immutable: assignments can be
re-run, hand-corrected, or produced by a different model without risking the
transcript.

Roles are HOST (or HOST_1..N for co-hosted shows) and GUEST_1..N. Multiple hosts
allowed — configurable via `roles.allow_multiple_hosts`.

**Bug found by running it: JSON extraction failed on all five test episodes.** Qwen
narrates before answering ("Here's a thinking process: ..."), and that prose contains
braces, so a greedy `\{.*\}` regex spanned from a brace in the reasoning to the final
one and raised "Extra data". Fixed with a balanced-brace scanner that takes the last
span which parses *and* carries the expected key. Generalizable lesson: never regex
JSON out of a local instruct model's reply.

After the fix: 5/5 assigned, all high confidence.

**Needs verification, not trust.** One episode (0-AYqS5csVA) returned two HOSTs and
zero guests. Plausible for a co-hosted episode, but this is exactly the class of
result to check against audio before believing it — especially given the local 8B
judge in evaluate.py failed its shuffle self-check outright.

## Batch made honest

Two fixes, both about the log being able to describe reality:

- **Per-show lock.** Two batch runs were racing: one wrote an episode's dialogue.json
  while the other reached it, saw the file, and logged "skipped". That is how a
  rebuild recorded 38 ok + 23 skipped where a clean pass is 61 ok. The artifacts were
  correct; the log was fiction.
- **Loud failures + non-zero exit.** I had reported "61/61" as a clean finish while 5
  episodes had failed. The summary now prints a banner listing failures and exits 1.

## deno installed

yt-dlp warned on every download that no JS runtime was available and that extraction
without one is deprecated — a plausible contributor to the 5 transient download
failures. deno 2.9.3 now at ~/.deno/bin/deno.

## Corpus state

61 episodes, 0 failures, 53 two-speaker + 8 three-speaker. All transcripts and
dialogues regenerated after the word-level attribution fix. Role assignment running
across all 61.
