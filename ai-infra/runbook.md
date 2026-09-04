---
title: Runbook
updated: 2026-09-03
---

# Runbook

## Is everything up?

```bash
fleet_llm_status                                   # from any fleet machine
ssh kecso@spark-db71.local '~/scripts/start-vllm.sh status'
ssh opi 'export XDG_RUNTIME_DIR=/run/user/$(id -u); systemctl --user is-active cloudflared-spark.service'
```

## Use the cluster

```bash
claude-local                # Claude Code, auto LAN-or-tunnel, key applied
fleet_use_lan               # force LAN
fleet_use_remote            # force tunnel
fleet_use_auto              # back to probing (default)
```

## Restart LiteLLM only (model stays loaded)

Config changes need this — LiteLLM reads `rpm`/`tpm` at startup. vLLM is untouched.

```bash
ssh kecso@spark-db71.local
pgrep -af 'bin/[l]itellm'
kill -9 <PID>
setsid nohup ~/spark_litellm_claude/start-litellm.sh </dev/null >/tmp/litellm.log 2>&1 &
disown
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4000/health    # expect 401
```

**Always via `start-litellm.sh`.** Running the `litellm` binary directly = no master key.

## Restart the tunnel

```bash
ssh opi
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user restart cloudflared-spark.service
```

## Take the public endpoint down

Power off the OrangePi, or `systemctl --user stop cloudflared-spark.service`. LAN serving
is unaffected either way.

## Roll the key out to a machine

```bash
~/my-projects/computers/fleet-deploy.sh
```

Skips unreachable hosts, so re-run it to catch machines that were asleep.

---

# Footguns

Every one of these was hit for real.

## `pkill -f litellm` kills your own SSH session

The pattern matches the shell running the command. The old proxy is left in graceful
drain and the connection dies. Use a bracket-escaped pattern:

```bash
pgrep -f 'bin/[l]itellm'
```

...and make sure the literal pattern does not appear **elsewhere in the same command** —
a kill and a start in one line will still self-match on the start command's path.

## cloudflared cannot resolve `.local`

Go's resolver, no mDNS. Origins must be IPs. Symptom: 502 plus
`lookup ... server misbehaving` in the connector log.

## `.116` is WiFi, `.103` is wired

Same subnet, both answer. The tunnel origin must be `.103`.

## `cloudflared tunnel route dns` can target the wrong tunnel

A `tunnel:` key in `~/.cloudflared/config.yml` overrides the name you pass. Use
`--config /dev/null` and the tunnel **UUID**.

## `/health` returns 401 now, and that is correct

Anything grepping it for `"healthy"` breaks. `check_litellm_running` in `start-vllm.sh`
did exactly this and reported a live proxy as down — fixed to accept 200/401/403.

## A wrong key returns 400, not 401

LiteLLM rejects it before the auth layer. Health checks and error messages should treat
400 as "bad key" too.

## Cloudflare 524s at 100s to first byte

Non-streaming long generations fail. Stream.

## Start buttons always reload the model

`start_all()` removes the vLLM container unconditionally. Never a no-op.

## The live monitor config is not the repo one

`~/.config/spark-monitor/config.json`, read once at startup.
