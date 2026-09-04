---
title: Remote access — spark.devquasar.com
updated: 2026-09-03
---

# Remote access

`https://spark.devquasar.com` — the cluster, reachable from anywhere over 443. Built
2026-09-03. Kept separate from `inference.devquasar.com`, which is the business endpoint.

## Path

```
client -> Cloudflare edge -> cloudflared "spark-cluster" (OrangePi) -> 192.168.7.103:4000
```

| Item | Value |
|------|-------|
| Tunnel name | `spark-cluster` |
| Tunnel ID | `cf88eb4f-7dbd-4aa2-896b-f397ae38e472` |
| Connector host | `server-opi5p` — `~/.local/bin/cloudflared`, user install, **no sudo** |
| Config | `~/.cloudflared/config.yml` on the OrangePi |
| Credentials | `~/.cloudflared/cf88eb4f-*.json`, 0600 |
| Service | `systemctl --user cloudflared-spark.service` (enabled) |
| Metrics | `127.0.0.1:20241` on the OrangePi |

## Why the OrangePi

Powering it off takes the public endpoint down and leaves LAN serving untouched — a
physical kill switch. It also meant nothing on the Spark nodes had to change to expose
them, which matters given how carefully that hardware is treated.

Cost: one extra LAN hop, and the origin must be an IP (below).

## Operating

```bash
ssh opi
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user status  cloudflared-spark.service
systemctl --user restart cloudflared-spark.service
journalctl --user -u cloudflared-spark.service -f
```

**Boot persistence is NOT enabled.** It is a user service, which needs
`sudo loginctl enable-linger kecso` to start at boot. Left off deliberately — without it,
a reboot drops the endpoint, which is the same kill switch behaviour. Enable only if you
want it to self-heal. Tracked in `projects/dgx-spark-tiny-rack/tasks/003-*`.

## Verify

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://spark.devquasar.com/v1/models   # 401
. ~/.fleet-secrets.sh
curl -s -o /dev/null -w '%{http_code}\n' https://spark.devquasar.com/v1/models \
  -H "Authorization: Bearer $SPARK_API_KEY"                                      # 200
```

## Traps, all of which were hit for real

**cloudflared cannot resolve `.local`.** It uses Go's resolver, which queries
systemd-resolved directly and never does mDNS. A hostname that works fine in your shell
produces `lookup spark-db71.local ... server misbehaving` and a **502**. The origin must
be an IP. This is the sole reason the DHCP-reservation task exists.

**`.116` is WiFi, `.103` is wired.** Both answer on the same subnet. Use wired.

**`cloudflared tunnel route dns <name>` can create the record on the wrong tunnel.** With
a `tunnel:` key in `~/.cloudflared/config.yml`, cloudflared 2025.8.0 (the Mac's version)
overrides the name given on the command line — the first `spark.devquasar.com` record was
created pointing at `ollama-tunnel1`. Always:

```bash
cloudflared --config /dev/null tunnel route dns --overwrite-dns <TUNNEL-UUID> <hostname>
```

**Cloudflare returns 524 if the origin sends no complete response in ~120s** (the limit on
this zone; it is not configurable below Enterprise). Measured 2026-09-04 through the tunnel:

| Request | Time to first byte | Verdict |
|---|---|---|
| streaming, small prompt | 0.31s | safe |
| streaming, 100 KB prompt | 3.3s | safe - prefill is not the problem |
| **non-streaming, long generation** | **61s (nothing until the end)** | **524 once it passes ~120s** |

So the clock is satisfied by the *first byte*, not by finishing. Anything that streams is
effectively immune; anything that buffers is on a 120s budget.

**Mitigations, in order of effort:**

1. **Stream everything.** The cheapest fix and it covers the common case.
2. **Do not queue behind other requests.** vLLM runs `max-num-seqs 4` and LiteLLM has
   `max_queue_size: 20`. A queued request sends *no bytes while it waits*, so time in
   queue counts against the 120s. Concurrent agents are a likely 524 cause even when
   every individual request is fast. Keep to ~1 autonomous worker.
3. **Use the LAN when home** — `fleet_use_lan`, or just let `fleet_llm_base` probe. No
   Cloudflare in the path, no 524.
4. **Bypass the HTTP proxy entirely** for the travelling case: Tailscale (already Phase 0
   of the steward roadmap) or a `cloudflared access tcp` sidecar. Either turns this into a
   raw connection with no HTTP timeout. This is the only real fix for long buffered calls.

## Other tunnels on this account

| Tunnel | Runs on | Serves |
|--------|---------|--------|
| `spark-cluster` | OrangePi | `spark.devquasar.com` |
| `ollama-tunnel1` | Mac Pro | `ollama1.devquasar.com` -> localhost:11434 |
| `llama-inference` | a linux_arm64 host at the same public IP | presumably `inference.devquasar.com` |
| `ai-model-tracker` | no connector | — |
