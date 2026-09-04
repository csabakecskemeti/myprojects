---
id: "002"
title: Push SPARK_API_KEY to ws1 and macbook (were offline)
status: active
priority: medium
created: 2026-09-03
---

# Finish the fleet rollout

Secret distribution is now part of `computers/fleet-deploy.sh` (it copies
`~/.fleet-secrets.sh` at 0600 from the operator's home). Rolled out 2026-09-03:

| Machine | Status |
|---------|--------|
| macpro | done |
| opi | done |
| spark-db71 | done |
| spark-7ceb | done |
| macbook | key delivered; missed the later aliases update (asleep) |
| **ws1** | **pending - unreachable** |

`fleet-check.sh` reports `ok` with no drift for every reachable machine.

Until ws1 gets the key, `claude-local` and the `local-llm` plugin there fail with 401:
it carries the old file with `ANTHROPIC_API_KEY=vllm` hardcoded, and the proxy now
enforces auth.

## Do this when they are up

```bash
~/my-projects/computers/fleet-deploy.sh        # all reachable machines
~/my-projects/computers/fleet-check.sh         # confirm no DRIFT
```

## Acceptance Criteria

- [ ] `fleet-check.sh` shows `ok` for ws1 and macbook
- [ ] `fleet_llm_status` on each returns the served model
- [ ] macbook verified **off the LAN** (falls back to `https://spark.devquasar.com`)
- [ ] Old `ANTHROPIC_API_KEY=vllm` gone from ws1
