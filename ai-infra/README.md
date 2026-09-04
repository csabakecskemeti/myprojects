---
title: AI Infrastructure
updated: 2026-09-03
---

# AI Infra

Everything behind "run a model locally": the DGX Spark cluster, how it is served, how it
is reached from anywhere, and how the credentials get to each machine.

Sibling of `computers/` — that directory is *which machines exist and what config they
share*; this one is *the inference infrastructure they all point at*.

| Doc | Covers |
|-----|--------|
| [spark-cluster.md](./spark-cluster.md) | Nodes, vLLM, LiteLLM, recipes, model aliasing |
| [remote-access.md](./remote-access.md) | `spark.devquasar.com`, the Cloudflare tunnel |
| [auth-and-secrets.md](./auth-and-secrets.md) | Master key, distribution, rotation |
| [spark-monitor.md](./spark-monitor.md) | The OrangePi rack dashboard and its buttons |
| [runbook.md](./runbook.md) | Day-to-day commands, and the footguns |
| [spark-request-path.html](./spark-request-path.html) | Drawn version of the flow below - open in a browser |

## The whole thing at a glance

```
        any machine, anywhere
                 |
     LAN? ------yes------> http://spark-db71.local:4000 ---+
       |                                                   |
       no                                                  |
       |                                                   |
       v                                                   |
  https://spark.devquasar.com   (Cloudflare edge, 443)      |
       |                                                   |
       v                                                   |
  cloudflared "spark-cluster"   (OrangePi, server-opi5p)    |
       |                                                   |
       +--------> http://192.168.7.103:4000 <--------------+
                          |
                     LiteLLM proxy  (auth boundary: master key)
                          |
                  http://localhost:8000
                          |
                     vLLM  (tensor-parallel across both Sparks)
                          |
            spark-db71  <--200GbE-->  spark-7ceb
             (head)      192.168.200.x   (worker)
```

Two entry points, one auth boundary. **LiteLLM is the only thing that checks the key** —
vLLM on `:8000` is unauthenticated and must never be exposed beyond the LAN.

## Endpoints

| What | Address | Auth | Reachable from |
|------|---------|------|----------------|
| LiteLLM (OpenAI + Anthropic compatible) | `http://spark-db71.local:4000` | master key | LAN |
| Same, public | `https://spark.devquasar.com` | master key | anywhere |
| vLLM raw | `http://spark-db71.local:8000` | **none** | LAN only |
| LMS vision (optional) | `http://spark-db71.local:11234` | none | LAN only |

`inference.devquasar.com` is a **different, business** endpoint. Not this.

## Design decisions worth remembering

- **The tunnel connector runs on the OrangePi, not the Sparks.** Powering off the OrangePi
  kills public access and leaves LAN serving completely intact — a physical kill switch.
  It also meant exposing the cluster required zero changes on the Spark nodes.
- **The key is never in a config file that gets backed up.** `litellm-config.yaml` gets a
  timestamped `.bak` on every edit; a literal key there would multiply into every copy.
- **The served model is always aliased `local-model`.** Recipes come and go; clients never
  need editing. Nothing pins a real model name anywhere.
