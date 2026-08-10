---
title: Machine Fleet
updated: 2026-08-09
---

# Machine Fleet

Inventory and role assignment for every machine in the
[personal-ai-os](../ideas/personal-ai-os.md) setup.

`computers/<mac-id>.md` files track **development machines** — where code is
checked out, maintained by `/projectz scan`. This README covers the **whole
fleet**, including infrastructure nodes that host no repos.

## Overview

| Machine | Hardware | OS | Role | Inference tier |
|---|---|---|---|---|
| **Mac Pro** | 2013 (MacPro6,1), 12-core Xeon E5 2.7 GHz, 128 GB | macOS 12.7.6 | Desktop / daily driver | **none** — client only |
| **MacBook Pro** | Mac17,7, **M5 Max, 128 GB** unified | macOS 26.6 | Travel, mobile dev, steward failover | **A** (unified memory) |
| **AI workstation** | **RTX 5090 + RTX 6000 Pro, 1 TB DDR5** | Debian 12 | Heavy compute, quantization, fine-tuning | **A++** |
| **DGX Spark ×2** *(→ ×4)* | NVIDIA GB10, 128 GB unified each, 200 Gbps network | DGX OS | Local LLM inference (vLLM) | **A+** |
| **OrangePi 5 Plus** | RK3588, ARM64 | Linux | Always-on services, rack display | **C** |

### Tier scale

Tiers rank *inference capability*, independent of role.

| Tier | Meaning | Machines |
|---|---|---|
| **A++** | Peak: training, fine-tuning, quantization, largest models | AI workstation |
| **A+** | Cluster inference, long context, high throughput | DGX Spark ×2 (→ ×4) |
| **A** | Full enrichment on large quantized models | MacBook Pro |
| **C** | Mechanical only — never enriches | OrangePi 5 Plus |
| **none** | Client, provides no inference | Mac Pro |

Tier B is deliberately empty; the ladder is effectively A-class or C.

**Planned:** the Spark cluster extends to **4× GB10** once the QSFP switch
arrives — 512 GB aggregate unified memory over 200 Gbps. This raises the
ceiling for A+ and makes the cluster, not the workstation, the target for
large-model serving.

## Addressing

All machines are on one `/22` (`192.168.4.0/22`), so `.local` mDNS resolves
fleet-wide — `192.168.4.x` and `192.168.7.x` are the same subnet.

| Machine | Hostname | SSH alias | User | Passwordless from MacBook |
|---|---|---|---|---|
| Mac Pro | `Mac-Pro.local` | `macpro` | `csabakecskemeti` | ✅ |
| Mac Pro (external) | `71.202.66.108:8822` | `macpro-wan` | `csabakecskemeti` | untested |
| MacBook Pro | `MacBook-Pro-2.local` | `macbook` | `kecso` | n/a |
| AI workstation | `workstation2deb12.local` | *(todo)* | `kecso` | powered off |
| DGX Spark 1 | `spark-7ceb.local` | `spark-7ceb` | `kecso` | ✅ |
| DGX Spark 2 | `spark-db71.local` | `spark-db71` | `kecso` | ✅ |
| OrangePi 5 Plus | `server-opi5p.local` | `opi` | `kecso` | ✅ |

All use `~/.ssh/id_rsa` (RSA-4096). Verified 2026-08-09.

**Note on the DGX Sparks:** NVIDIA Sync maintains its own `ssh_config` (included
at the top of `~/.ssh/config`) pinning `spark-db71.local` and several IPs to
`nvsync.key`. Because `IdentityFile` accumulates across command line and config,
that key can silently satisfy auth and mask the fact that `id_rsa` is not
authorized. `id_rsa` is now installed on both Sparks so the fleet uses one key;
the NVIDIA entries remain and still work.

**Addresses belong in `~/.ssh/config`, not in shell aliases.** Shell aliases
call the ssh alias (`alias ssh_opi="ssh opi"`), so when an address changes only
one line per machine needs editing. Before this rule, `.bash_profile` held a
stale IP while `.zshrc` held the hostname — the drift this prevents.

Tailscale (Phase 0) replaces this with one name that works on the LAN and
while travelling, retiring the `macpro-wan` split.

## Shared shell environment

Applied fleet-wide, hooked into `~/.zshrc` and `~/.bashrc` between
`# BEGIN fleet-prompt` / `# END fleet-prompt` markers so regeneration never
clobbers hand-written config.

### `~/.fleet-prompt.sh` — unified prompt

Layout is identical everywhere: `user@host ~/path (branch) %`

**The host segment is colour-coded per machine.** With six boxes and constant
SSH between them, the colour is a safety feature — it tells you which machine
you are about to run a command on before you read the hostname.

| Colour | Machine | Role |
|---|---|---|
| cyan | MacBook Pro | travel |
| green | Mac Pro | desktop |
| red | AI workstation | heavy compute |
| magenta | DGX Sparks | inference cluster |
| yellow | OrangePi 5 Plus | always-on |
| blue | unknown host | — |

Branch detection uses `git symbolic-ref`, never `git status` — on large repos
(`llama.cpp`, `executorch`) status would make every prompt slow.

### `claude-local` — run Claude Code against the local cluster

Auto-detects the served model from vLLM on `spark-db71` and points Claude Code
at the LiteLLM proxy:

```
claude-local          # -> deepseek-ai/DeepSeek-V4-Flash
```

Defined on the Mac Pro and MacBook. Uses `spark-db71.local` rather than a
hardcoded IP.

> `LOCAL_LLM_URL` / `LOCAL_LLM_MODEL` on the Mac Pro are **not** dead
> variables — `skill-vault/plugins/local-llm/scripts/local-llm.sh` reads both.
> The model pin was stale (`Qwen/Qwen3.6-35B-A3B-FP8`, no longer served) and is
> now `deepseek-v4`. It should really auto-detect the way `claude-local` does.

---

## Roles in detail

### Mac Pro — desktop / daily driver · no inference tier

`003ee1c99605` · 26 repos checked out — the primary development machine.

General development, browsing, day-to-day work. **No inference role**: 2013
Intel hardware with no usable GPU compute. It is a client of the fleet, never
a provider.

> ⚠️ macOS 12.7.6 is past Apple's security-update window. Worth planning
> around given it holds the most checkouts.

### MacBook Pro — travel + steward failover · tier A

`4ebcb7c6dad2` · registered 2026-06-25, migrated 2026-07-30 · 2 repos.

**M5 Max with 128 GB unified memory makes this a tier-A machine, not a weak
travel node.** It runs large quantized models locally via LM Studio, Ollama or
native `llama-server`.

This materially improves the travel story in the
[steward architecture](../projects/steward/docs/steward-architecture.md):
with the rack powered down and the DGX cluster off, capture and enrichment
still run at full capability rather than degrading to mechanical-only. See §6.

Steward failover target — claims the lease after a 120 s delay, **only on AC
power**.

### AI workstation — heavy compute · tier A++

`bcfce7d9356d` · 27 repos — the largest checkout, all inference and
fine-tuning work.

RTX 5090 + RTX 6000 Pro with 1 TB DDR5. Handles quantization runs, fine-tuning,
multi-GPU experiments, and anything that would take hours elsewhere. Target for
`type: task` delegation addressed to `role:gpu` (UC-5).

*Currently powered off — specs recorded as stated, not probed.*

### DGX Spark ×2 — local LLM inference · tier A+

`spark-7ceb` (192.168.4.77) · `spark-db71` (192.168.7.103)
NVIDIA GB10, **128 GB unified memory each, 200 Gbps network**.

The `local-llm-self-sufficiency` substrate. Serves models via **vLLM**, with
OpenAI-compatible endpoints the router consumes directly. Rack-mounted with
the OrangePi (see `dgx-spark-tiny-rack`).

Not projectz-registered — infrastructure, no repos.

### OrangePi 5 Plus — always-on services · tier C

`server-opi5p` · RK3588, ARM64.

The only machine that is always on, which makes it the default steward host
(0 s lease claim delay). Runs:

- **`agent-hub`** — messaging, registry, task queue *(Phase 0: needs a
  systemd unit and a remote)*
- **`quasar-deck`** GUI — cluster monitoring on the GeeekPi 6.91" 1424×280
  rack LCD, autostarted on boot
- **steward** — once Phase 6 lands

Tier C: mechanical work only. Never enriches — bad tags are worse than none.

Not projectz-registered — infrastructure, no repos.

---

## Role summary

Roles are independent of inference tier. A machine can be a capable client and
provide no inference at all.

| Role | Machines |
|---|---|
| Daily development | Mac Pro, MacBook Pro |
| Heavy compute / training | AI workstation |
| LLM inference serving | DGX Spark ×2, AI workstation, MacBook Pro |
| Always-on services | OrangePi 5 Plus |
| Physical display | OrangePi 5 Plus (rack LCD) |
| Steward host (priority order) | OrangePi → AI workstation → MacBook |

## Open items

- [ ] SSH alias for the AI workstation (currently powered off)
- [ ] Tailscale across the fleet — retires `macpro-wan` and the LAN/WAN split
- [ ] Confirm workstation GPU/RAM by probe once powered on
- [ ] Register the workstation's `computers/<mac-id>.md` local paths after the
      next `/projectz scan` there
- [ ] macOS 12.7.6 on the Mac Pro is EOL for security updates
- [ ] `local-llm` plugin should auto-detect its model instead of pinning it
- [ ] Deploy the shared shell environment to the workstation once powered on
- [ ] Generate all of this from a declarative inventory — see
      [ideas/fleetz.md](../ideas/fleetz.md)
