---
title: Auth and secrets
updated: 2026-09-03
---

# Auth and secrets

## The boundary

**LiteLLM on :4000 is the only thing that checks credentials.** vLLM on :8000 is
completely unauthenticated. Anything that exposes :8000 beyond the LAN exposes the whole
cluster with no key at all.

## How it was before (and why it changed)

LiteLLM ran with `disable_key_check: true` and **no master key**. Fine while the endpoint
was LAN-only. The moment `spark.devquasar.com` went live, anyone who found the hostname
could run unlimited inference on the cluster — this was confirmed by getting a real
completion with no credentials. The tunnel was taken down until auth was in place.

## How it works now

```yaml
# ~/spark_litellm_claude/litellm-config.yaml
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  disable_key_check: false
```

The key is **not in the YAML** — that file gets a timestamped `.bak` on every edit, so a
literal key would multiply into every backup. It lives in:

```
~/spark_litellm_claude/.env        (chmod 600, on the head node)
```

and is loaded by `~/spark_litellm_claude/start-litellm.sh`, which is the **only**
supported way to start the proxy. Running the `litellm` binary directly starts it with no
key and silently drops authentication on a publicly reachable endpoint.

## Getting it to clients

`~/.fleet-secrets.sh` on each machine (chmod 600, **never in git**):

```sh
export SPARK_API_KEY=sk-spark-...
export SPARK_BASE_URL_LAN=http://spark-db71.local:4000
export SPARK_BASE_URL_REMOTE=https://spark.devquasar.com
```

Distributed over scp by `computers/fleet-deploy.sh`. Sourced automatically via
`~/.fleet-aliases.sh`, which the `fleet-managed` block in each shell rc sources. See
`computers/FLEET-MANAGEMENT.md`.

The tracker repo has a `.gitignore` blocking `*fleet-secrets*`, `.env`, `*.key`, `*.pem`
as a backstop — but the rule is *distribute over scp, never commit*, not *rely on the
ignore file*.

## Rotating

1. New value into `~/spark_litellm_claude/.env` on the head node.
2. Restart the proxy (see [runbook.md](./runbook.md) — vLLM is unaffected).
3. Update `~/.fleet-secrets.sh` on the machine you are sitting at.
4. `~/my-projects/computers/fleet-deploy.sh`
5. Anything given the key out-of-band (see below) needs the new value by hand.

## Known caveat: one shared key

There is a single master key; everyone and every machine uses it. LiteLLM can mint
per-user virtual keys instead, but that requires a database, which this deployment does
not have. Consequence: **revoking access for one consumer means rotating for all of them.**

Currently that includes a standalone copy given to a family member for a corporate Mac
(tunnel-only, HTTPS/443, works from behind VPN). If that ever needs revoking, it is a
full rotation.

## Verifying auth is actually on

`/health` returning **401 is correct** — it proves the proxy is up *and* enforcing. A 200
from `/health` means the master key did not load.

```bash
. ~/.fleet-secrets.sh
curl -s -o /dev/null -w 'no key:   %{http_code}\n' https://spark.devquasar.com/v1/models
curl -s -o /dev/null -w 'with key: %{http_code}\n' https://spark.devquasar.com/v1/models \
  -H "Authorization: Bearer $SPARK_API_KEY"
# expect 401 then 200
```

A **wrong** key returns **400**, not 401 — LiteLLM rejects the malformed/unknown key
before the auth layer reports. Worth knowing when writing health checks or error messages.
