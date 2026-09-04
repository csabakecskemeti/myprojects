---
id: "001"
title: Give the rack stable addressing (QNAP switch reservation, or its own subnet)
status: active
priority: high
created: 2026-09-03
---

# Give the rack stable addressing

## Why

`spark.devquasar.com` currently reaches the cluster via a **hardcoded IP**:
`http://192.168.7.103:4000` in the OrangePi's `~/.cloudflared/config.yml`.

That IP is a **dynamic DHCP lease** on spark-db71's wired interface (`enP7s7`). When the
lease moves, the public endpoint silently 502s and nothing tells you why.

The hostname is not an option as-is: cloudflared uses Go's resolver, which cannot resolve
mDNS `.local` names — that already caused the first 502 during setup.

## Options

| Option | Effort | Notes |
|--------|--------|-------|
| DHCP reservation on the QNAP managed switch | low | Pins `.103` to the NIC's MAC. Smallest change, fixes it today. |
| Static IP on the Spark nodes | low | Config lives on the nodes; no switch dependency. |
| **Own tiny-rack subnet** (preferred) | medium | VLAN on the QNAP for the rack: static addressing, isolates cluster traffic from house LAN, room to grow. |

The nodes already have a private link between them (`192.168.200.1` on
`enp1s0f1np1` -> `192.168.200.2`), so a dedicated rack subnet fits the existing shape.

## Acceptance Criteria

- [ ] spark-db71 wired interface holds a stable address across reboots and lease renewals
- [ ] spark-7ceb likewise
- [ ] OrangePi `~/.cloudflared/config.yml` origin updated if the address changes
- [ ] Endpoint verified after the change: `curl -s -o /dev/null -w '%{http_code}' https://spark.devquasar.com/v1/models` -> 401
- [ ] Decision recorded in `docs/spark-remote-endpoint.md`

## Notes

Documented only for now, per decision on 2026-09-03 — not changing switch or node
network config in the same session that stood up the tunnel.
