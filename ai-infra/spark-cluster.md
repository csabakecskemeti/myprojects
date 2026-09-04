---
title: DGX Spark cluster
updated: 2026-09-03
---

# DGX Spark cluster

Two DGX Spark nodes, 128 GB unified memory each, serving one tensor-parallel vLLM
instance fronted by LiteLLM.

## Nodes

| Role | Host | LAN (wired) | Cluster link | WiFi |
|------|------|-------------|--------------|------|
| head | `spark-db71.local` | `192.168.7.103` (`enP7s7`) | `192.168.200.1` (`enp1s0f1np1`) | `192.168.7.116` |
| worker | `spark-7ceb.local` | `192.168.4.62` (`enP7s7`) | `192.168.200.2` | `192.168.7.251` |

`192.168.200.0/24` is the dedicated inter-node link — that is the path tensor-parallel
traffic takes. The `192.168.7.x` addresses are **DHCP leases, not static**; see the open
task on giving the rack stable addressing (`projects/dgx-spark-tiny-rack/tasks/001-*`).

**Use the wired address, never the WiFi one.** They are on the same subnet and both
answer, so it is easy to pick the wrong one — the tunnel origin was briefly pointed at
`.116` (WiFi) before being corrected to `.103` (wired).

## Services on the head node

| Service | Port | Started by | Auth |
|---------|------|-----------|------|
| vLLM (in `vllm_node` container) | 8000 | `~/scripts/start-vllm.sh <recipe>` | none |
| LiteLLM proxy | 4000 | `~/spark_litellm_claude/start-litellm.sh` | master key |
| LMS vision (optional) | 11234 | `start-vllm.sh --vision` | none |

Paths: `VLLM_DIR=~/spark-vllm-docker`, `LITELLM_DIR=~/spark_litellm_claude`.

## Recipes

`~/scripts/start-vllm.sh list` shows what is available — `deepseek-v4-flash`,
`qwen3.6-35b-a3b-nvfp4`, `gemma4-26b-a4b`, `glm-4.7-flash-awq`, and others.

Every recipe is launched with `-- --served-model-name local-model`, so whatever is loaded
is always served as **`local-model`**. This is deliberate: LiteLLM's backend config and
every client keep working across model changes. A pinned real model name went stale once
already (Qwen3.6-35B-A3B-FP8) and that is why nothing pins one now.

Resolve what is actually loaded at call time rather than assuming:

```bash
fleet_llm_model          # from ~/.fleet-aliases.sh
```

## Capacity — read before scaling anything

The Spark is a **~4-concurrent-decode-stream device**; 273 GB/s shared LPDDR5x is the
wall. Official vLLM guidance is `max_num_seqs: 4` — raising it does not add throughput,
it just makes every stream slower.

One fully autonomous Claude Code worker (agent + supervisor + subagents) is **2–5
concurrent streams**. Plan for roughly **one** such worker at a time.

See `projects/quasar-deck` and its `docs/inference-resilience.md` for the detail.

## Memory / stability

Unified memory means CPU and GPU share the same 128 GB pool, and OOM tends to hang the
whole box rather than killing a process (PyTorch #174358). Mitigations live in
`scripts/dgx-spark-memory-fix.sh` in the quasar-deck repo: swappiness 10, earlyoom at 20%,
page cache flush before load.

Crashes previously blamed on memory turned out to be **thermal/power** and were fixed by
capping the GPU clock at 2100. Keep `gpu_memory_utilization <= 0.8`.
