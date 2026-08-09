---
title: Steward Roadmap
status: draft
created: 2026-08-08
updated: 2026-08-08
---

# Steward Roadmap

Execution plan for [steward-architecture.md](./steward-architecture.md).
Use cases referenced here are defined in
[steward-usecases.md](./steward-usecases.md).

This is the **authoritative build order**. The architecture document describes
*what* the system is; this describes *in what order it gets built and how you
know a phase is finished*.

## Ordering principles

1. **Nothing unattended before it is durable.** Phase 0 exists because the
   linchpin of four goals currently has one commit and no remote.
2. **Nothing reasons over noise.** The decision layer and the backlog triage
   come before any agent tries to answer "what should I do."
3. **Nothing writes before the vault exists.** Once content reaches GitHub it
   is permanent; force-pushing history does not reliably remove it.
4. **Every phase is independently useful.** Stopping after any phase leaves a
   working system, not a half-built one.

| Phase | Deliverable | Size | Value if you stop here |
|---|---|---|---|
| 0 | Harden `agent-hub` | S | Existing work stops being one disk failure from gone |
| 1 | `projectz` 0.8 + backlog triage | M | "What should I do now?" becomes answerable, manually |
| 2 | Private vault | S | Personal data has a home before anything starts writing |
| 3 | Mail capture | M | Send anything from anywhere; nothing is lost again |
| 4 | Lease + tiers | M | Runs unattended, survives travel and power-down |
| 5 | Handoffs + delegation | M | Continuity across machines, frameworks and models |
| 6 | Steward loop | S | The daily 3 and the weekly review arrive on their own |
| 7 | *(deferred)* KV warm resume | L | Marginal — see §Phase 7 |

**Phases 0–3 are worth doing even if the rest is never built.**

---

## Phase 0 — Harden `agent-hub`

**Why first:** `agent-hub` is `repo: (local only - not pushed to remote yet)`,
1 commit, no service unit — and four goals depend on it. Every later phase
assumes it is boring and reliable. This is the only phase that is urgent
rather than merely next.

**Deliverables**
- [ ] Push to a GitHub remote; update `MAP.md` with the real repo URL
- [ ] `systemd` unit on the OrangePi, enabled, restarts on failure
- [ ] Reachable over Tailscale from every machine
- [ ] SQLite marked vault-class: excluded from any public or cloud backup
- [ ] Health endpoint the router can probe

**Done when:** reboot the OrangePi, and every machine can send and receive a
message with zero manual steps.

**Unblocks:** UC-5, UC-8

---

## Phase 1 — `projectz` 0.8 and backlog triage

**Why here:** the steward's output quality is bounded by the quality of what
it reasons over. 44 of 57 projects in `backlog` with 8 open tasks total means
any agent asked "what next" today returns noise.

**Deliverables**
- [ ] `areas/` — continuous work with `cadence` + `health`, never `done`
- [ ] `kind:` — `repo` | `hardware` | `learning` | `household` | `area`;
      only `kind: repo` is touched by `scan`
- [ ] `next_action`, `effort`, `energy` on every `active` project and area
- [ ] Decay rules implemented, batched and confirmed — never silent
- [ ] `/projectz now --effort --energy` returning **3 items max**
- [ ] **Triage all 57 projects**: active / backlog / archived, or convert to
      an area

**Done when:** UC-2 and UC-9 pass. Every `active` project has exactly one
concrete `next_action`.

**The tedious part is the point.** Step 6 produces nothing new and is the one
you will want to skip. An agent reasoning over 44 items of noise gives
noise-flavoured advice, and no amount of later engineering fixes that.

---

## Phase 2 — Private vault

**Why before capture:** the moment capture starts writing, PII is in flight.
Anything pushed to GitHub is permanent.

**Deliverables**
- [ ] `myprojects-private` repo, remote = bare repo on the home server,
      LAN/Tailscale only, **no GitHub remote ever**
- [ ] `private_ref:` opaque-ID convention in the public repo
- [ ] Pre-commit hook on the public repo: secret scanner + PII pass
- [ ] Default-private promotion gate: classify before anything moves public
- [ ] Encrypted external-disk mirror (the vault has no offsite backup)

**Done when:** UC-7 passes, and a deliberately planted test secret is blocked
by the pre-commit hook.

---

## Phase 3 — Mail capture

**Why here:** lowest effort, highest daily payoff, and it works standalone
with zero inference. One idea file in the entire tracker is the evidence that
capture is currently too expensive to bother with.

**Deliverables**
- [ ] Dedicated address on an owned domain
- [ ] IMAP IDLE drain; move to `processed/`, never delete
- [ ] Sender whitelist **and DKIM verification**; failures to `quarantine/`
- [ ] Plus-address routing: `+read` `+idea` `+task` `+note` `+buy` `+private`
- [ ] Mechanical enrichment with no model: dedup, title, metadata, timestamp
- [ ] Capture contract normalised so HTTP and CLI adapters drop in later

**Done when:** UC-1 and UC-10 pass — a link sent from the phone appears in git
within 2 minutes with a real title, and a re-send does not duplicate.

---

## Phase 4 — Lease and tiers

**Why here:** first phase where something runs unattended on more than one
machine, so election has to exist before the loop does.

**Deliverables**
- [ ] `steward/LEASE.md`, 5 min renew / 10 min TTL
- [ ] Claim via `git push` compare-and-swap; rejected push means back off
- [ ] Claim delays: OrangePi 0s, workstation 30s, MacBook 120s **on AC only**
- [ ] `hub_url` in the lease as service discovery
- [ ] `steward/inference.yaml`: OpenAI-compatible base-URL preference list
      (vLLM on DGX, LM Studio / Ollama / `llama-server` on the MacBook)
- [ ] Health check with 2s timeout selects the tier
- [ ] `pending_enrichment/` queue; drains on tier upgrade, capped

**Done when:** UC-3 and UC-8 pass — kill the OrangePi and captures keep
working with no intervention and no duplicate commits.

---

## Phase 5 — Handoffs and delegation

**Deliverables**
- [ ] Handoff record format under `projects/<slug>/handoffs/`
- [ ] Session-start rule: read the latest handoff **before** touching a project
- [ ] Session-end rule: write handoff, update `MAP.md` `next_action`
- [ ] On `status: complete`, promote "What I learned" into `docs/`
- [ ] `agent-hub` message contract: `message` | `task` | `result` | `handoff`
- [ ] One ~30-line client per framework in use — **no per-framework adapters**

**Done when:** UC-4 and UC-5 pass — work resumes on a different machine with a
different model and nothing is re-explained.

---

## Phase 6 — Steward loop

**Deliverables**
- [ ] 5 min: renew lease, drain mail, commit, push
- [ ] 30 min: enrich if tier ≥ B, promote completed handoffs
- [ ] Daily 07:00: the **3-item** email, chosen by `next_action` + `effort` +
      `energy` + goal priority
- [ ] Weekly: batched decay and review proposals, confirmed by reply

**Done when:** UC-6 passes and the daily mail arrives unprompted.

**The honest risk:** capture will work and the review may still be ignored. If
that is still true after a month, the fix is fewer active projects — not a
better email.

---

## Phase 7 — KV warm resume *(deferred, probably skip)*

Layer 2 (§8.3) only works with the **native `llama-server`**. vLLM, LM Studio
and Ollama do not expose slot save/restore, so it is unavailable in three of
the four engine configurations — and the one where it works is the travel
setup, where sessions are shortest and the hardware is weakest.

On cloud models it is moot: the prompt cache TTL is 5 minutes (1 hour
extended), so resuming hours later is always cold.

**Revisit only if** native `llama-server` becomes the daily driver on the
MacBook. Layer 1 handoffs deliver the continuity that actually matters.

---

## Open questions

Carried from the architecture document; none block Phase 0 or 1.

- Mail provider and domain for the dedicated address (blocks Phase 3)
- KV blob TTL — needs a real measurement (Phase 7 only)
- Whether `agent-hub` follows the steward or stays pinned to the OrangePi.
  **Leaning pinned:** simpler, and travelling alone with the MacBook involves
  little cross-machine messaging anyway
- Whether areas need their own `next_action` or just a cadence nudge
- Model choice per tier — not yet benchmarked on the OrangePi (RK3588)
