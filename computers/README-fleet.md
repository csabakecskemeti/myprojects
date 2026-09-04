---
title: Fleet config & secret distribution
updated: 2026-09-03
---

# Fleet config

Every machine sources two managed files from a `# BEGIN fleet-managed` block in its
`~/.zshrc` / `~/.bashrc`:

| File | Source of truth | Mode | In git? |
|------|-----------------|------|---------|
| `~/.fleet-aliases.sh` | `computers/fleet-aliases.sh` (this repo) | 0644 | **yes** |
| `~/.fleet-prompt.sh` | (not yet canonicalised) | 0644 | not yet |
| `~/.fleet-secrets.sh` | nowhere — lives only on machines | **0600** | **never** |

## Distributing

```bash
./computers/fleet-push.sh ws1 macbook opi     # any ssh hosts from ~/.ssh/config
```

Pushes the canonical aliases + this machine's `~/.fleet-secrets.sh` over scp, fixes
permissions, appends the `fleet-managed` block to any rc file missing it, and prints the
resolved endpoint and model per host. Unreachable hosts are skipped, so re-running it is
how you catch machines that were powered off.

## Secrets

`~/.fleet-secrets.sh` holds `SPARK_API_KEY` (the LiteLLM master key for the DGX Spark
cluster) plus the LAN and tunnel base URLs. It is **deliberately not in this repo** —
this repo is `github.com/csabakecskemeti/myprojects` and secrets don't belong in git even
in a private repo. A `.gitignore` blocks `*fleet-secrets*`, `.env`, `*.key`, `*.pem` as a
backstop, but the real rule is: distribute over scp, never commit.

Rotating the key:

1. On `spark-db71`: new value into `~/spark_litellm_claude/.env`, restart via
   `start-litellm.sh` (see `projects/dgx-spark-tiny-rack/docs/spark-remote-endpoint.md`).
2. Update `~/.fleet-secrets.sh` on the machine you're on.
3. `./computers/fleet-push.sh <all hosts>`.

## Endpoint selection

`fleet_llm_base()` probes the LAN endpoint with a 1s timeout and falls back to
`https://spark.devquasar.com`, so the same config works at home and on the road. No probe
happens at shell startup — only when a function that needs it is called. Force either way
with `fleet_use_lan` / `fleet_use_remote`, back to probing with `fleet_use_auto`.

## History

- 2026-09-03: `SPARK_API_KEY` added; LiteLLM went from unauthenticated to master-key
  enforced when `spark.devquasar.com` was exposed. The old hardcoded `ANTHROPIC_API_KEY=vllm`
  and `LOCAL_LLM_API_KEY=vllm` were replaced with the real key — any machine still on the
  old file gets 401. `fleet-aliases.sh` and `fleet-push.sh` canonicalised into this repo
  for the first time (previously the managed file existed only on the machines, with a
  header pointing at a `computers/fleet-aliases.sh` that did not yet exist).
