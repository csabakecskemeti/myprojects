---
title: Steward Architecture
status: draft
created: 2026-08-08
updated: 2026-08-09
---

# Steward Architecture

An always-on personal coordination agent that tracks projects, areas, ideas and
captured knowledge across multiple machines, multiple agent frameworks, and
multiple LLM backends — at zero marginal cost, with no cloud dependency.

This document is the design of record. Agents on any machine should read this
before making changes to `projectz`, `agent-hub`, or the steward itself.

---

## 1. The problem

Work is spread across 4–5 machines, dozens of repos, several never-ending
areas of responsibility (community quantization, hardware, house, family),
and a constant inflow of articles and ideas. Existing state:

- `projectz` tracks 57 projects across 3 registered machines. It answers
  *"what do I have?"* well and *"what should I do now?"* not at all.
- `agent-hub` exists (FastAPI + SQLite + MCP) but is 1 commit, local-only,
  never pushed, no service unit.
- 44 of 57 projects sit in `backlog`, which has become a dumping ground.
- Only 2 of 57 projects have any tasks. The decision layer is empty.

The goal is not a better inventory. It is **attention allocation**, plus
**continuity** — any agent, on any machine, in any framework, picking up
where another left off.

---

## 2. Core principle: durable text truth, disposable caches

| | `myprojects` (git, public) | `myprojects-private` (git, LAN only) | `agent-hub` (service) |
|---|---|---|---|
| Holds | projects, areas, goals, next actions, distilled knowledge | transcripts, KV blobs, PII, family/health/financial | registry, messages, task queue, inbox |
| Speed | slow, durable | slow, durable | fast, operational |
| Source of truth | **yes** | **yes** | no — working memory |
| Leaves the LAN | yes (GitHub) | **never** | never |

> **The rule: caches are ephemeral. Anything worth keeping is promoted into
> git. Anything personal is promoted into the *private* repo.**

The same pattern recurs at three levels — `agent-hub` caches messages, layer 2
caches conversation state (§8.4), and the private repo caches nothing but
holds what must not travel. In every case a small durable text record is the
contract and the fast thing is disposable.

Consequences that make the whole system tractable:

- The SQLite database can be deleted at any time and rebuilt. It never
  becomes a second, rotting source of truth.
- The service can move between machines freely.
- Everything durable is human-readable markdown, readable by any agent in any
  framework without an API.

---

## 3. Components

```
                    ┌───────────────────────────┐
                    │  GitHub: myprojects repo  │
                    │  durable truth + LEASE    │  ← always available
                    └─────────────┬─────────────┘
                                  │ clone / pull / push
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
  ┌─────▼─────┐            ┌──────▼──────┐           ┌──────▼──────┐
  │ OrangePi  │            │ AI Worksta. │           │  MacBook    │
  │ tier C    │            │  tier A     │           │  tier A     │
  │ STEWARD ★ │            │             │           │  (failover) │
  └─────┬─────┘            └─────────────┘           └─────────────┘
        │ hosts
  ┌─────▼──────┐    ┌──────────────┐    ┌────────────────────┐
  │ agent-hub  │    │ IMAP mailbox │    │ DGX Spark cluster  │
  │ (follows   │    │ (capture)    │    │ (tier A inference) │
  │  steward)  │    └──────────────┘    └────────────────────┘
  └────────────┘
```

| Component | Role | Status |
|---|---|---|
| `myprojects` (git) | Durable truth, lease, service discovery | exists |
| `projectz` skill | Human/agent interface to the truth | exists, v0.7 |
| `agent-hub` | Messaging, registry, task queue | exists, needs hardening |
| Steward | Scheduled loop: drain, enrich, promote, review | **new** |
| Mail adapter | Universal capture from anywhere | **new** |
| `llm-router` | Tier selection + health check | backlog, first real consumer |

---

## 4. `projectz` 0.8 — the decision layer

### 4.1 Areas vs projects

Add `areas/` alongside `projects/`. The distinction is a **definition of
done**, not size or importance.

- **Project** — has a finish line. Can be `done`.
- **Area** — continuous, maintained indefinitely. Cannot be `done`; it has a
  review cadence instead.

Examples of areas: HuggingFace community quantization, DGX cluster upkeep,
house maintenance, family, reading/learning, physical health.

```yaml
# areas/<slug>.md
---
slug: hf-community-quants
kind: area
cadence: weekly          # how often the steward surfaces it
health: green            # green | yellow | red — set at review
next_action: "Quantize the new Mistral release"
effort: 1h
energy: shallow
last_reviewed: 2026-08-08
---
```

### 4.2 `kind:` — decoupling from git

`scan` currently infers everything from commit recency, so anything without a
repo is invisible or permanently `backlog`. Add an explicit `kind:`:

| kind | Status inferred from | Example |
|---|---|---|
| `repo` | git commit recency (current behaviour) | `agent-hub` |
| `hardware` | manual only | DGX tiny rack build |
| `learning` | manual only | Read the new agent-framework paper |
| `household` | manual only | Fix the garage shelf |
| `area` | n/a — uses `cadence` + `health` | HF quantization |

Only `kind: repo` is touched by `scan`. Everything else is never
auto-downgraded, which is the bug that currently makes non-code work
invisible.

### 4.3 The three fields that enable prioritization

Every `active` project and every area carries:

```yaml
next_action: "Push agent-hub to a remote and add a systemd unit"
effort: 15min | 1h | weekend
energy: deep | shallow
```

`next_action` is **exactly one concrete step**, not a list. This is the single
change that turns the tracker into something that can answer *"I have 90
minutes and I'm tired — what should I do?"* A project that is `active` with no
`next_action` is flagged at review as needing a decision.

### 4.4 Decay

44 items in `backlog` is past the point of being holdable, so it reads as
noise and gets ignored. Rules:

- `backlog` untouched > 6 months → proposed for `archived` at weekly review.
- `active` with no commit and no `next_action` change in 30 days → proposed
  for `backlog`.
- Proposals are **batched and confirmed**, never applied silently.
- `done`, `review`, and all areas are exempt.

### 4.5 Statuses (revised)

| Status | Meaning | Applies to |
|---|---|---|
| `draft` | Just created | projects |
| `active` | Working on it now; must have `next_action` | projects |
| `backlog` | Genuinely intend to resume | projects |
| `blocked` | Waiting on a hard dependency | projects |
| `review` | In testing/review | projects |
| `done` | Finished | projects |
| `archived` | Not coming back | projects |
| `green`/`yellow`/`red` | Health, set at review | areas |

---

## 5. Lease protocol — who is the steward

### 5.1 Why git, not `agent-hub`

`agent-hub` runs on the OrangePi. In the travel scenario the OrangePi may be
powered off. **A registry that is down cannot report that it is down.** GitHub
is the only component reachable in every scenario, so election happens there.

### 5.2 The lease file

`steward/LEASE.md` in the tracker repo:

```yaml
---
holder: 4ebcb7c6dad2
holder_name: macbook-pro
hub_url: http://macbook.tail-scale-net.ts.net:8080
tier: A
claimed: 2026-08-08T14:02:11Z
expires: 2026-08-08T14:12:11Z
---
```

- Renewed every **5 minutes**, TTL **10 minutes**.
- `hub_url` doubles as **service discovery**: any agent reads the lease to
  find where `agent-hub` currently lives. The hub follows the steward.

### 5.3 Election

`git push` to GitHub is a compare-and-swap: a non-fast-forward push is
**rejected**. That is the only primitive needed — no Raft, no consensus
library, no extra service.

```
loop:
  pull --rebase
  if lease valid and holder == me:  renew, push, continue
  if lease valid and holder != me:  sleep, continue
  if lease expired or absent:
      sleep(claim_delay)            # priority, see below
      pull --rebase                 # re-check after waiting
      if still expired: write lease, push
         if push rejected: someone won, back off
```

### 5.4 Claim delay = priority, without coordination

Nodes wait different amounts before claiming an expired lease, so the
preferred node wins the race naturally:

| Node | Delay | Condition |
|---|---|---|
| OrangePi | 0s | always — cheap, always-on |
| AI workstation | 30s | if powered |
| MacBook | 120s | **only on AC power** |

The AC-power condition on the MacBook is not an optimization. Auto-spinup is
the feature most likely to become resented; a background loop that fires
while on battery in a café is how this system gets turned off.

### 5.5 Split brain

Tolerable by construction. Two stewards briefly both running produces
duplicate git commits, not corruption — the loser's push is rejected and it
re-reads. IMAP flag changes and folder moves are server-side atomic, so at
worst one capture is processed twice and deduplicated by `Message-ID`.

---

## 6. Inference tiers — zero cost, degrade don't fail

### 6.1 Mechanical vs reasoning

Split every steward job in two:

- **Mechanical** — needs no model: drain mailbox, dedup by `Message-ID` and
  URL, fetch page title/metadata, timestamp, write to git, renew lease.
  **This must always work, including on tier C with no model loaded.**
- **Reasoning** — tagging, cross-project linking, summarizing, review.
  Requires a model.

### 6.2 Tiers and engines

See [the fleet inventory](../../../computers/README.md) for full hardware and
role assignment.

| Tier | Host | Engine | Available when | Capabilities |
|---|---|---|---|---|
| **A** | DGX Spark ×2 (GB10, 121 GB each) | **vLLM** | Cluster powered and reachable | Everything: cross-project linking, weekly review, deep enrichment |
| **A** | AI workstation (RTX 5090 + RTX 6000 Pro, 1 TB DDR5) | vLLM or llama.cpp | Powered | Same, plus quantization and fine-tuning |
| **A** | MacBook Pro (**M5 Max, 128 GB unified**) | **llama.cpp** — LM Studio, Ollama, or native server | Machine awake | Full enrichment on large quantized models |
| **C** | OrangePi 5 Plus (RK3588) | llama.cpp (3–4B), or none | Always | Mechanical only |
| — | Mac Pro (2013 Xeon) | none | — | **Client only, never an inference provider** |

**Revision (2026-08-09): the MacBook is tier A, not tier B.** 128 GB of unified
memory runs large quantized models locally, so travelling with the rack powered
down no longer degrades capability — capture *and* enrichment both run at full
quality. Tier B is currently empty; the ladder is effectively A or C.

This weakens the practical need for deferred enrichment without removing it:
§6.3 still matters for the case where only the OrangePi is awake, but the
common travel scenario is no longer degraded at all.

### 6.3 The router is a list of base URLs

LM Studio, Ollama, native `llama-server`, and vLLM **all expose an
OpenAI-compatible `/v1` API**. So "multi-framework inference" collapses to a
preference list plus a health check — one client, swap `base_url`:

```yaml
# steward/inference.yaml
tiers:
  - tier: A
    base_url: http://dgx-1.ts.net:8000/v1
    engine: vllm
    model: <large>
  - tier: A
    base_url: http://localhost:1234/v1     # LM Studio
    engine: llama.cpp
    model: <mid GGUF>
  - tier: A
    base_url: http://localhost:11434/v1    # Ollama
    engine: llama.cpp
  - tier: C
    base_url: http://orangepi.ts.net:8080/v1
    engine: llama.cpp
    model: <small GGUF>
health_check: GET {base_url}/models, 2s timeout
```

This is exactly what the `llm-router` and `llm-forwarder` projects (both
backlog under the `local-llm-self-sufficiency` goal) are for. The steward is
their first real consumer, and the requirement is small enough to be worth
building properly.

### 6.3a Verified: the cluster can already do enrichment work

Tested 2026-08-09 against `spark-db71` (vLLM, `DeepSeek-V4-Flash`) with a real
Phase 1 triage prompt — classify a project's README into
`STATUS` / `KIND` / `NEXT_ACTION`:

```
STATUS: backlog
KIND: repo
NEXT_ACTION: Write problem and solution sections.

7.7s · prompt 157 tok · completion 277 tok
```

Correct, correctly formatted, at zero marginal cost. **The enrichment tier is
not speculative — it works today.**

> **Implementation note: the served model is a reasoning model.** It emits
> `reasoning_content` before `content`, so a small `max_tokens` returns
> `finish_reason: "length"` with **`content: null`** — looking like a failure
> when it is really a truncated think phase. Budget ~1000+ completion tokens
> for short structured answers, and always check `content` for null rather
> than assuming a non-empty string. Any steward code calling a tier-A endpoint
> must handle this.

**Note:** LM Studio, Ollama, and `llama-server` are all llama.cpp underneath.
They differ in packaging and in which endpoints they expose — which matters
for §8.3 and nothing else.

### 6.3 Deferred enrichment — the rule that makes travel safe

> Anything the current tier cannot do is **queued, not dropped.**

Items land in `inbox/pending_enrichment/`. Capture always succeeds. Two weeks
abroad with the DGX off means the OrangePi keeps swallowing every article;
when the cluster comes back up the steward drains the backlog and does the
linking retroactively.

**Worst failure mode is "slightly stale", never "down" and never "lost."**

---

## 7. Capture — the universal interface

### 7.1 Why email

The steward *moves between machines*. An HTTP endpoint is bound to a host, so
every failover breaks every capture path. A mailbox is bound to nothing: the
current lease holder connects **outbound** to IMAP and drains it.

This eliminates port forwarding, dynamic DNS, tunnels, and any need for
inbound reachability — it works from behind hotel wifi and CGNAT.

Properties obtained for free:

- **The mailbox is the queue.** Never delete on read; move to `processed/`.
  A crash mid-drain loses nothing, and no separate capture persistence is
  needed.
- **IMAP IDLE**, not polling — long-lived outbound connection, near-instant.
- **Offline capture already works** — the phone queues and sends on
  reconnect. On a plane, in the subway. Not built, just inherited.
- Attachments, screenshots, and forwarded articles work natively.
- Replies thread, so the daily review is a conversation.

On external dependency: there is still a mail provider, but what matters is
**lock-in, not hosting**. SMTP/IMAP are open protocols; moving to self-hosted
is a config change. Slack or Telegram would be a rewrite. Use a dedicated
address on an owned domain so the address itself is portable.

### 7.2 Routing via plus-addressing

No command syntax to remember at 11pm:

| Address | Becomes |
|---|---|
| `steward+read@` | reading queue item |
| `steward+idea@` | `ideas/<slug>.md` |
| `steward+task@` | task on the best-matching project |
| `steward+note@` | note on the best-matching project |
| `steward+buy@` | household/shopping item |
| `steward+private@` | straight to the vault, never classified, never promoted |
| `steward@` | untyped — vault first, promoted only once classified clean (tier A) |

Subject → title. Body → note. URLs in body → fetched and enriched.

### 7.3 Auth

Anyone can email that address.

- Sender must be on an explicit whitelist, **and**
- **DKIM must pass.** A bare `From:` header is trivially spoofed; whitelisting
  on it alone is not authentication.
- Failures go to `quarantine/`, never to the steward.

### 7.4 Capture contract

Email is an **adapter**, not the interface. All paths normalize to:

```yaml
# inbox/<iso8601>-<slug>.md
---
id: <message-id or uuid>
source: email | http | cli
captured: 2026-08-08T14:02:11Z
kind: read | idea | task | note | buy | unknown
url: https://...
title: "..."
tags: []                  # filled by enrichment
links: []                 # related project/area slugs, filled by enrichment
enriched: false
---
<body>
```

Later fast paths — HTTP POST over Tailscale when home, a `/capture` CLI —
produce the same record. The steward never knows which adapter it came from.

---

## 7.5 The private vault

Raw transcripts are exactly where PII lives — pasted content, paths,
credential-adjacent detail, family and financial context. So the "warm resume"
store (§8.3) and the private store are **the same system**, not two.

### Shape

`myprojects-private` — a second git repo whose remote is a **bare repo on the
home server**, reachable over LAN/Tailscale only. No GitHub remote, ever. This
keeps git's sync and merge machinery while never touching the internet: it
syncs when home, works offline otherwise.

```
myprojects-private/
├── transcripts/<session-id>.md      # raw agent sessions
├── kv/<session-id>.bin              # layer 2 blobs (gitignored if large)
├── people/                          # family, contacts, health
├── finance/
└── private/<id>.md                  # anything referenced from public
```

Public records reference private ones by **opaque ID only** — never by title:

```yaml
private_ref: pv-2026-08-08-a1b2
```

### Three rules

**1. Default private, promote to public.** Captures land in the vault first.
Something must actively classify an item as clean before it moves to the
public repo. The inverse — default public, redact on detection — fails the
first time classification is wrong, and once it is on GitHub it is public
forever. This also composes with §6: tier C cannot classify, therefore cannot
promote, therefore travel is private by default.

**2. Vault content is processed only by local models.** Never route private
content to a cloud tier even when one is available and more capable. The
zero-cost preference and the privacy requirement are the same constraint,
which is convenient — but it must be enforced in the router, not by habit.

**3. Pre-commit hook on the public repo** running a secret scanner
(e.g. gitleaks) plus a PII pass, blocking the commit on a hit. Policy fails;
mechanism should not.

### Known exposure

`agent-hub`'s SQLite holds message payloads, which can contain PII. It is
LAN-only so exposure is low, but it is **vault-class** — never back it up
anywhere public, and exclude it from any cloud backup of the OrangePi.

---

## 8. Agent continuity

### 8.1 You migrate state, not processes

Different frameworks cannot share a process, but they can all write the same
JSON. An agent ending a session writes a **handoff record**; any agent, on any
machine, in any framework, resumes from it.

```yaml
# projects/<slug>/handoffs/<iso8601>-<machine>.md
---
session_id: abc123
machine: 4ebcb7c6dad2
framework: claude-code | langgraph | custom
model: claude-opus-5 | qwen3-32b | ...
started: 2026-08-08T09:00:00Z
ended: 2026-08-08T11:30:00Z
status: handoff | complete
---

## What I was doing
## What I learned          ← promoted to docs/ on `status: complete`
## Files touched
## Open questions
## Next action             ← writes back to MAP.md next_action
```

### 8.2 Knowledge distillation

On `status: complete`, the steward promotes **What I learned** into the
project's `docs/` and updates `next_action`. This is what makes the system
compound rather than merely accumulate — the reason to bother with handoffs
at all.

### 8.3 Two layers of continuity

The handoff record is the contract. Raw conversation state is an
*opportunistic* optimization on top of it.

| | Layer 1 — handoff record | Layer 2 — warm resume |
|---|---|---|
| Contains | summary, learnings, files, next action | raw transcript + optional KV cache blob |
| Size | ~2 KB | MB–GB |
| Stored in | `myprojects` (git) | `myprojects-private` / local vault |
| Portable across machine, model, framework | **yes** | no |
| Lifetime | indefinite | hours–days, easily invalidated |
| Role | **the contract** | cache |

Resume logic:

```
if same machine and same model and blob valid and within window:
    warm start from layer 2
else:
    cold start from layer 1 handoff record
```

**On cloud models (Claude):** the prompt cache TTL is 5 minutes by default,
1 hour extended. Resuming hours or a day later is *always* a cold cache, so
layer 2 buys nothing there. Note that the handoff record is not a loss but a
compression — replaying a 200k-token transcript costs 200k input tokens, a
handoff costs ~2k. What is actually lost is nuance, not money.

**On local models: narrower than it first appears.** Disk-persisted KV
requires slot save/restore, and that is only exposed by the **native
`llama-server`**:

| Engine | Where | Persisted KV to disk? |
|---|---|---|
| vLLM | DGX cluster (tier A) | No — in-memory prefix caching only |
| LM Studio | MacBook | No — wraps llama.cpp, endpoint not exposed |
| Ollama | MacBook | No — wraps llama.cpp, endpoint not exposed |
| **native `llama-server`** | MacBook / OrangePi | **Yes** — `--slot-save-path`, slot save/restore |

So layer 2 is available in exactly **one** of the four configurations, and it
is the travel configuration where sessions are shortest and the machine is
weakest. Further caveats:

- A blob is valid only for the exact same model + quantization + engine build
  + token prefix. A system-prompt tweak or an engine upgrade invalidates it.
- Gigabytes for long contexts. Viable on the workstation, **not** the OrangePi.
- Never treat a blob as recoverable state. If missing or stale, layer 1 must
  be sufficient on its own.

> **Recommendation: build layer 2 last, or not at all.** Layer 1 is what
> actually delivers continuity across machines, models and frameworks. Revisit
> only if native `llama-server` becomes the daily driver on the MacBook.

### 8.4 Framework neutrality

Do **not** build per-framework adapters. `agent-hub` is already HTTP + JSON.
Define one message contract; each framework writes a ~30-line client. MCP
becomes one client among several, not the interface.

```json
{
  "from": "4ebcb7c6dad2:session-abc",
  "to": "broadcast | <machine>:<session> | role:gpu",
  "type": "message | task | result | handoff",
  "payload": {},
  "reply_to": "<message-id>"
}
```

---

## 9. Steward loop

```
every 5 min:   renew or contest lease
               drain mailbox (mechanical, always)
               dedup, fetch metadata, write inbox records
               commit + push

every 30 min:  if tier is A: enrich pending items (tag, link)
               promote completed handoffs to docs/
               commit + push

daily 07:00:   compose "what to do today" — 3 items max, chosen by
               next_action + effort + energy + goal priority
               email it to the primary address

weekly Sun:    review — decay proposals, areas past cadence,
               active projects missing next_action, stale handoffs
               email as a batch to confirm
```

Daily output is capped at **3 items**. A review that lists 57 projects is the
current failure mode reproduced in email form.

---

## 10. Build order

> **[steward-roadmap.md](./steward-roadmap.md) is authoritative** for phases,
> deliverables and acceptance criteria. The table below is a summary; where
> the two disagree, the roadmap wins.

Strict dependency chain; each step is independently useful.

| # | Step | Why it's first | Done when |
|---|---|---|---|
| 1 | **Harden `agent-hub`** | Linchpin of 4 goals, currently 1 commit and local-only — one disk failure from gone | Pushed to remote, systemd unit, Tailscale-reachable, survives reboot |
| 2 | **`projectz` 0.8** | Steward needs something to reason over | `areas/`, `kind:`, `next_action`/`effort`/`energy`, decay implemented |
| 3 | **Backlog migration** | 44 items of noise make the system unusable | Every project triaged to active/backlog/archived or converted to an area |
| 3.5 | **Private vault** | Must exist *before* capture starts writing, or PII lands in a public repo permanently | `myprojects-private` syncing to the home server, pre-commit scanner live on the public repo |
| 4 | **Mail capture** | Lowest effort, highest daily payoff; works standalone with zero inference | Send a link from the phone → lands in `inbox/` (vault first, promoted when classified) |
| 5 | **Lease protocol** | Required before anything runs unattended on >1 machine | Kill the OrangePi, MacBook takes over within 12 min |
| 6 | **Tiered inference** | Makes enrichment free and travel-safe | Router picks A/B/C by health check; deferred queue drains on tier upgrade |
| 7 | **Handoff records** | Continuity across machines and frameworks | Start on Mac Pro, finish on MacBook, no context re-explained |
| 8 | **Steward loop** | Everything above is its input | Daily 3-item email arrives; weekly review batches decay proposals |

Steps 1–4 are worth doing even if the rest is never built.

---

## 11. Risks and honest limitations

| Risk | Mitigation |
|---|---|
| OrangePi is a SPOF | It isn't — git is the truth, lease fails over, worst case is stale |
| Auto-spinup drains MacBook battery / surprises you mid-meeting | AC-power condition + 120s claim delay |
| Capture works, review is ignored | 3-item cap; if it's still ignored after a month, the fix is fewer active projects, not a better email |
| Tier C enrichment quality is poor | Never enrich on tier C — defer. Bad tags are worse than no tags |
| Mail provider outage | Captures queue on the phone; steward retries. Address is portable |
| Handoffs written but never read | Enforce at session start: agent reads latest handoff before touching the project |
| Deferred queue grows unbounded while travelling | Cap at N items; overflow still captured, just not auto-enriched |
| **PII promoted to the public repo** | Default-private + classification gate + pre-commit scanner. Assume anything pushed to GitHub is permanent |
| Private repo has no offsite backup | Accepted tradeoff. Mirror to an encrypted external disk, never to a cloud remote |
| KV blobs fill the disk | TTL them aggressively (days). They are a cache — deletion must always be safe |

### Known open questions

- Which mail provider / domain for the dedicated address.
- Whether `agent-hub` should follow the steward or stay pinned to the OrangePi
  and simply be unavailable while travelling (simpler, probably acceptable).
- Whether areas need their own `next_action` or just a cadence nudge.
- Model choice per tier — not yet benchmarked on OrangePi (RK3588).

---

## Related

- [steward-roadmap.md](./steward-roadmap.md) — build order and acceptance criteria
- [steward-usecases.md](./steward-usecases.md) — end-to-end scenarios
- [multi-agent-coordination](../../../goals/multi-agent-coordination.md)
- [unified-multi-machine-workflow](../../../goals/unified-multi-machine-workflow.md)
- [remote-access-infra](../../../goals/remote-access-infra.md)
- [local-llm-self-sufficiency](../../../goals/local-llm-self-sufficiency.md)
- [sync-dev-environment](../../../goals/sync-dev-environment.md)
