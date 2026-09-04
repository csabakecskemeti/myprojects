---
id: "002"
title: Push SPARK_API_KEY to ws1 (was offline)
status: active
priority: medium
created: 2026-09-03
---

# Finish the fleet rollout

Rolled out 2026-09-03 via `computers/fleet-push.sh`:

| Machine | Status |
|---------|--------|
| Csabas-Mac-Pro | done |
| server-opi5p | done |
| macbook | done |
| **ws1** | **pending — unreachable (connection timed out)** |

Until ws1 gets the key, `claude-local` and the `local-llm` plugin there will fail with
401: it still carries the old file with `ANTHROPIC_API_KEY=vllm` hardcoded, and LiteLLM
now enforces auth.

## Do this when it's up

```bash
~/my-projects/computers/fleet-push.sh ws1
```

Skips unreachable hosts, safe to run repeatedly.

## Acceptance Criteria

- [ ] ws1: `fleet_llm_model` returns the served model
- [ ] Old `ANTHROPIC_API_KEY=vllm` gone from ws1
- [ ] macbook: re-push for route-printout update (has key, works, just older aliases)
- [ ] macbook re-verified **off the LAN** (should fall back to `https://spark.devquasar.com`)
