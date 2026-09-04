---
title: Spark Remote Endpoint (Cloudflare Tunnel + LiteLLM auth)
created: 2026-09-03
updated: 2026-09-03
---

# Spark Remote Endpoint

Public, authenticated access to the DGX Spark cluster's LiteLLM proxy from any machine.

**Endpoint:** `https://spark.devquasar.com` (OpenAI- and Anthropic-compatible)

Kept deliberately separate from `inference.devquasar.com`, which is the business endpoint.

## Topology

```
client (anywhere)
  -> https://spark.devquasar.com        Cloudflare edge
  -> cloudflared "spark-cluster"        OrangePi  (server-opi5p)
  -> http://192.168.7.103:4000          spark-db71 wired iface, LiteLLM
  -> http://localhost:8000              vLLM
```

The connector runs on the **OrangePi, not the Spark nodes**. Powering off the OrangePi
takes the public endpoint down while leaving LAN serving completely unaffected — that
is the intended kill switch. It also means nothing on the Spark nodes had to change to
expose them.

| Item | Value |
|------|-------|
| Tunnel name | `spark-cluster` |
| Tunnel ID | `cf88eb4f-7dbd-4aa2-896b-f397ae38e472` |
| Connector host | `server-opi5p` (`~/.local/bin/cloudflared`, user install, no sudo) |
| Config | `~/.cloudflared/config.yml` on the OrangePi |
| Service | `systemctl --user cloudflared-spark.service` |
| Connector metrics | `127.0.0.1:20241` on the OrangePi |

## Auth

LiteLLM previously ran with `general_settings.disable_key_check: true` and **no master
key** — the endpoint accepted unauthenticated inference. That was fine LAN-only; it is
not fine behind a public hostname. Now:

```yaml
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  disable_key_check: false
```

The key itself is **never in the YAML** (the config gets timestamped `.bak` copies on
every edit, which would multiply the secret). It lives in `~/spark_litellm_claude/.env`
(chmod 600) and is loaded by `~/spark_litellm_claude/start-litellm.sh`.

Clients send `Authorization: Bearer $SPARK_API_KEY`. See `computers/README-fleet.md`
for how that reaches each machine.

## Operating it

```bash
# tunnel (on the OrangePi)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user status|start|stop cloudflared-spark.service

# LiteLLM (on spark-db71) - does NOT touch vLLM, model stays loaded.
# Kill by PID with a bracket-escaped pattern: a plain `pkill -f litellm` matches
# the SSH shell running it and self-kills the session.
PIDS=$(pgrep -f 'bin/[l]itellm'); kill -9 $PIDS
setsid nohup ~/spark_litellm_claude/start-litellm.sh </dev/null >/tmp/litellm.log 2>&1 &
```

## Verify

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://spark.devquasar.com/v1/models          # 401
curl -s https://spark.devquasar.com/v1/models -H "Authorization: Bearer $SPARK_API_KEY" # 200
```

## Gotchas hit while building this

- **cloudflared cannot resolve `.local`.** It uses Go's resolver, which asks
  systemd-resolved directly and never does mDNS — so a hostname that works in your
  shell yields `server misbehaving` and a 502. The origin must be an IP (or a real
  DNS name). This is why the DHCP reservation task exists.
- **`192.168.7.116` is spark-db71's WiFi**; `192.168.7.103` is the wired port. Use wired.
- **`cloudflared tunnel route dns <name>` can target the wrong tunnel.** With a
  `tunnel:` key in `~/.cloudflared/config.yml`, older cloudflared (2025.8.0 on the Mac)
  overrides the name given on the command line — the first DNS record was created
  pointing at `ollama-tunnel1`. Use `--config /dev/null` and address the tunnel by UUID.
- **Cloudflare's edge times out a request at 100s without a first byte.** Long
  non-streaming generations will 524. Stream, or keep them short.
