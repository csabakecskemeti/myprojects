---
title: Steward Use Cases
status: draft
created: 2026-08-08
updated: 2026-08-09
---

# Steward Use Cases

Concrete end-to-end scenarios for the system described in
[steward-architecture.md](./steward-architecture.md).

Each use case names the **components it exercises** and the **phase** from
[steward-roadmap.md](./steward-roadmap.md) that delivers it. They are written
so they double as acceptance tests: if a phase is done, its use cases run
end-to-end without manual intervention.

---

## UC-1 — Capture an article from the phone

**Trigger:** Reading on the phone, find something worth keeping.

```
Share → Mail → to: steward+read@<domain>
                subject: "New agent memory framework"
                body: <url>
```

**Flow:**
1. Mail sits in the mailbox. Delivery is the phone's problem, not the
   steward's — offline, it queues and sends on reconnect.
2. Lease holder drains via IMAP IDLE, verifies sender whitelist + DKIM.
3. **Mechanical** (works on every tier): dedup by `Message-ID` and URL, fetch
   page title and metadata, write `inbox/<ts>-<slug>.md`.
4. Lands in the **vault** first. Promoted to the public repo only once
   classified clean.
5. Marked processed by moving to the `processed/` folder — never deleted.

**Exercises:** mail adapter, capture contract, vault default-private, lease
**Phase:** 3
**Passes when:** a link sent from the phone appears in git within 2 minutes,
with a real title, and no duplicate on a second send.

---

## UC-2 — "I have 90 minutes and I'm tired"

**Trigger:** Evening, some energy but not much.

```
$ /projectz now --effort 1h --energy shallow
```

**Flow:**
1. Read all `active` projects and areas past their `cadence`.
2. Filter to `effort <= 1h` and `energy: shallow`.
3. Rank by parent goal priority, then staleness.
4. Return **3 items max**, each with its concrete `next_action`.

**Exercises:** `projectz` 0.8 decision layer
**Phase:** 1
**Passes when:** the answer is three specific next actions, not a project
list. Requires that `active` projects actually carry `next_action` — which is
what makes Phase 1 mandatory before anything else.

---

## UC-3 — Article captured abroad connects to work at home

**Trigger:** UC-1 fired two weeks ago while travelling; DGX was powered off.

**Flow:**
1. Abroad, steward ran on the MacBook at **tier A** — or the OrangePi at
   tier C. Either way capture succeeded and the item was queued to
   `pending_enrichment`.
2. Home. DGX comes up, health check promotes the router to **tier A**.
3. Steward drains the deferred queue: tags each item, compares against active
   projects and goals.
4. Finds the memory-framework article relates to `agent-hub`. Writes
   `links: [agent-hub]` and appends a pointer to that project's notes.
5. Next time `agent-hub` is worked on, the article surfaces with it.

**Exercises:** tiers, deferred enrichment, linking, promotion to git
**Phase:** 4
**Passes when:** two weeks of captures with no cluster produce zero data loss
and full retroactive linking once tier A returns.

---

## UC-4 — Continue on another machine

**Trigger:** Working on `agent-hub` on the Mac Pro; leaving for the day.

**Flow:**
1. Session ends → agent writes
   `projects/agent-hub/handoffs/<ts>-macpro.md` with what it was doing, what
   it learned, files touched, open questions, `next_action`.
2. `next_action` is written back to `MAP.md`. Commit, push.
3. Next day on the MacBook: agent pulls, reads the latest handoff **before
   touching the project**, resumes cold but informed.
4. On `status: complete`, "What I learned" is promoted to
   `projects/agent-hub/docs/`.

**Exercises:** handoff contract (layer 1), knowledge distillation
**Phase:** 5
**Passes when:** work resumes on a different machine with a different model
and nothing has to be re-explained. Note this is **layer 1 only** — no KV
reuse, which is correct and sufficient (see architecture §8.3).

---

## UC-5 — Delegate heavy compute

**Trigger:** On the MacBook, need to quantize a large model.

**Flow:**
1. MacBook agent posts a `type: task` message to `agent-hub` addressed to
   `role:gpu`.
2. Workstation agent picks it up, runs the job, posts `type: result`.
3. MacBook agent is notified, continues.

**Exercises:** `agent-hub` messaging, task delegation, framework-neutral
contract
**Phase:** 5
**Passes when:** the requesting machine can sleep mid-job and still collect
the result afterwards.

---

## UC-6 — Weekly review kills the backlog

**Trigger:** Sunday, scheduled.

**Flow:**
1. Steward scans for: `backlog` untouched > 6 months, `active` with no
   `next_action`, areas past `cadence`, stale handoffs.
2. Composes a **batch of proposals** — archive these 9, these 3 need a next
   action, these 2 areas are overdue.
3. Emails it. Replies confirm or reject.
4. Confirmed changes applied, committed, pushed.

**Exercises:** decay rules, area cadence, review loop, mail as bidirectional
interface
**Phase:** 6
**Passes when:** a reply of "archive all" measurably shrinks the active set.
Proposals are always batched and confirmed — never applied silently.

---

## UC-7 — Personal item never reaches the internet

**Trigger:** A medical appointment, a financial figure, a family note.

```
to: steward+private@<domain>
```

**Flow:**
1. Straight into `myprojects-private`. Never classified, never promoted.
2. If a public project must reference it, it does so by opaque ID only —
   `private_ref: pv-2026-08-08-a1b2` — never by title.
3. Enrichment, if any, runs **only against a local model**. Never a cloud
   tier even when one is available and better.
4. The private repo's remote is a bare repo on the home server. It syncs when
   home and works offline otherwise.

**Exercises:** vault, opaque refs, local-only processing rule
**Phase:** 2
**Passes when:** `git log` on the public repo contains no trace, and the
pre-commit scanner blocks a deliberate test secret.

---

## UC-8 — The always-on box dies

**Trigger:** OrangePi loses power, or you fly and shut the rack down.

**Flow:**
1. Lease in `steward/LEASE.md` expires after 10 minutes.
2. MacBook waits its 120s claim delay, **and checks it is on AC power**.
3. Claims the lease with `git push` — a compare-and-swap; a losing racer is
   rejected and backs off.
4. Writes its own `hub_url`, so agents discover the hub's new location by
   reading the lease.
5. Capability drops to tier A on the MacBook (or C if only the OrangePi is
   awake, in which case reasoning defers).
6. OrangePi returns → reclaims at its 0s delay on next expiry.

**Exercises:** lease protocol, priority via claim delay, service discovery,
graceful degradation
**Phase:** 4
**Passes when:** killing the OrangePi mid-day causes captures to keep working
with no manual intervention, and no duplicate commits appear.

---

## UC-9 — A never-ending area gets attention

**Trigger:** HuggingFace community quantization — has no finish line, so it
never appears in a project list sorted by activity.

**Flow:**
1. `areas/hf-community-quants.md` has `cadence: weekly`, `health: green`.
2. Steward notices `last_reviewed` is 9 days old.
3. Surfaces it in the daily 3 with its `next_action`.
4. After work, `health` and `last_reviewed` are updated. It is never marked
   `done`, because it cannot be.

**Exercises:** areas, cadence, health
**Phase:** 1
**Passes when:** continuous responsibilities surface on schedule rather than
being crowded out by projects with recent commits.

---

## UC-10 — An idea becomes a project

**Trigger:** An idea while walking.

```
to: steward+idea@<domain>
```

**Flow:**
1. Captured → `ideas/<slug>.md`, `status: brainstorming`.
2. Steward enriches with related existing projects, prior art, links from the
   reading queue.
3. Over time: `/projectz idea <slug>` to develop it.
4. When ready: `/projectz convert <slug>` → a project with `next_action`.

**Exercises:** capture routing, existing ideation flow, linking
**Phase:** 3
**Passes when:** capture is cheap enough that ideas are actually recorded. The
current count of **1 idea file total** is the evidence that today it is not.

---

## Coverage by phase

| Phase | Use cases delivered |
|---|---|
| 0 — Harden `agent-hub` | *(none directly — unblocks 5, 8)* |
| 1 — `projectz` 0.8 + triage | UC-2, UC-9 |
| 2 — Private vault | UC-7 |
| 3 — Mail capture | UC-1, UC-10 |
| 4 — Lease + tiers | UC-3, UC-8 |
| 5 — Handoffs + delegation | UC-4, UC-5 |
| 6 — Steward loop | UC-6 |
