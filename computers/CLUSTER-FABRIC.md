---
title: DGX Cluster Fabric
updated: 2026-08-10
status: unresolved — blocked on sudo access
---

# DGX Cluster Fabric

The high-speed interconnect between the two DGX Sparks and the AI workstation,
separate from the `192.168.4.0/22` LAN that [README.md](./README.md) covers.

**Why this file exists:** an IP collision on this fabric makes
`ai-workstation.local` resolve to the wrong machine from the Sparks. The fleet
works around it by pinning `ws1` to its LAN IP. Fixing it properly needs one
decision and root on the workstation.

---

## 1. Verified runtime state (2026-08-10)

Read from `/sys/class/net` and `ip addr` on each machine. Facts, not intent —
the netplan files are root-only and could not be read.

### spark-db71 (Spark 2)

| Interface | Speed | Carrier | Address |
|---|---|---|---|
| `enp1s0f0np0` | 100 G | up | **192.168.201.1/24** |
| `enp1s0f1np1` | 200 G | up | **192.168.200.1/24** |
| `enP2p1s0f0np0` | 100 G | up | *(none)* |
| `enP2p1s0f1np1` | 200 G | up | *(none)* |
| `enP7s7` | 10 G | up | 192.168.7.103/22 (LAN) |
| `wlP9s9` | — | up | 192.168.7.116/22 (wifi) |

### spark-7ceb (Spark 1)

| Interface | Speed | Carrier | Address |
|---|---|---|---|
| `enp1s0f0np0` | — | **down** | *(none)* |
| `enp1s0f1np1` | 200 G | up | **192.168.200.2/24** |
| `enP2p1s0f0np0` | — | **down** | *(none)* |
| `enP2p1s0f1np1` | 200 G | up | *(none)* |
| `enP7s7` | 10 G | up | 192.168.4.77/22 (LAN) |
| `wlP9s9` | — | up | 192.168.7.251/22 (wifi) |

### AI-workstation

| Interface | Speed | Carrier | Address |
|---|---|---|---|
| `enp1s0f0np0` | 100 G | up | **192.168.200.2/24** ← the collision |
| `enp1s0f1np1` | — | **down** | *(none)* |
| `eno1np0` | — | down | *(none)* |
| `eno2np1` | 10 G | up | 192.168.7.117/22 (LAN) |

Config lives in `/etc/netplan/99-rdma.yaml` on all three (with a
`.bu20260123` / `.old` backup alongside) — same filename everywhere, so they
were set up as one exercise.

---

## 2. What is proven

**The Spark ↔ Spark link works and is correct.**

```
spark-db71 enp1s0f1np1 (200 G, 192.168.200.1)
        ↕  ARP: 4c:bb:47:2a:7c:ed ⇄ 4c:bb:47:2d:db:73, both REACHABLE
spark-7ceb enp1s0f1np1 (200 G, 192.168.200.2)
```

Each has the other in its ARP table with the matching MAC. This is the real
cluster interconnect and nothing here should change.

**The collision is real.** The AI workstation's `enp1s0f0np0` also carries
`192.168.200.2/24` — the same address as spark-7ceb's fabric port. Consequences:

- `avahi-resolve -n ai-workstation.local` on spark-db71 returns `192.168.200.2`
- spark-db71 routes `192.168.200.0/24` via `enp1s0f1np1` — i.e. **to spark-7ceb**
- so `ssh ai-workstation.local` from spark-db71 reaches spark-7ceb and reports
  `REMOTE HOST IDENTIFICATION HAS CHANGED`
- spark-db71's `/etc/hosts` line `192.168.200.2 workstation` is wrong for the
  same reason — it points at spark-7ceb
- the workstation has **no ARP neighbours at all** on the fabric: it is talking
  `200.x` into a wire whose far end is not on that subnet

---

## 3. What is NOT proven — the open question

**Which port is the workstation's `enp1s0f0np0` actually cabled to?**

By elimination it looks like spark-db71's `enp1s0f0np0` (192.168.201.1): both
are 100 G, both have carrier, and the alternatives on both Sparks are down.
That would make the intended address **`192.168.201.2/24`** and the whole thing
a one-digit subnet typo.

**But this was not confirmed.** Two attempts failed and neither is evidence:

| Attempt | Why it proved nothing |
|---|---|
| `ip addr add 192.168.201.2/24` then ping | `sudo: interactive authentication is required` — the address was never added |
| broadcast ping, watching RX counters | control showed **TX delta 0** — Linux refuses broadcast ping below a 1000 ms interval, so nothing was sent |

`arping` is not installed on the Sparks. The counter method is still sound —
it just needs `-i 1` and enough packets to beat the multicast noise floor
(spark-db71's fabric ports see ~4–7 background packets per test window).

Remaining candidates if it is *not* spark-db71 `enp1s0f0np0`: spark-db71's
`enP2p1s0f0np0` (100 G, up, unaddressed) is the strongest, since it is the only
other 100 G port with carrier and no address.

---

## 4. Next steps

Needs root on the AI workstation, so it needs the user at a keyboard.

**Step 1 — prove the pairing.** Non-destructive; adds a second address:

```sh
# on AI-workstation
sudo ip addr add 192.168.201.2/24 dev enp1s0f0np0
ping -c3 -I enp1s0f0np0 192.168.201.1          # spark-db71's 100 G port
sudo ip addr del 192.168.201.2/24 dev enp1s0f0np0   # roll back either way
```

If that replies, the cabling is confirmed and the fix is a subnet correction.

Alternative if it does not reply — repeat with the counter method, correctly:

```sh
# baseline, then 10 broadcasts at the minimum legal interval, then compare
cat /sys/class/net/<port>/statistics/rx_packets     # on each candidate Spark port
ping -b -c 10 -i 1 -I enp1s0f0np0 192.168.200.255   # on the workstation
```

**Step 2 — apply the fix.** Edit `/etc/netplan/99-rdma.yaml` on the workstation,
change the address on `enp1s0f0np0` from `192.168.200.2/24` to the proven
subnet, then `sudo netplan try` (auto-reverts in 120 s if it goes wrong) before
`sudo netplan apply`. The LAN port `eno2np1` is untouched, so there is no
lockout risk.

**Step 3 — clean up the consequences.**

- Fix `192.168.200.2 workstation` in spark-db71's `/etc/hosts` (points at
  spark-7ceb today)
- Clear the stale entry: `ssh-keygen -f ~/.ssh/known_hosts -R ai-workstation.local`
  on spark-db71
- Restore the hostname in `fleet.json`: set `host` back to `ai-workstation.local`
  and drop the `hostname` field, then `./fleet-deploy.sh`
- Tick the open items in [README.md](./README.md)

**Do not** simply delete the `known_hosts` line and move on — that is the
standard advice for this error and here it would hide a live IP conflict.

---

## 5. Interim workaround (in place now)

`fleet.json` pins `ws1` to `192.168.7.117` with the name recorded separately in
a `hostname` field. This is immune to the mDNS ambiguity, and the full 6×6 mesh
works today.

Its cost: **a DHCP lease change silently breaks `ws1`.** Either give
`192.168.7.117` a reservation on the router, or land the fix above and go back
to the name.

---

## Related

- [README.md](./README.md) — machine inventory, LAN addressing
- [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md#4-troubleshooting) — the
  `REMOTE HOST IDENTIFICATION HAS CHANGED` entry, written from this incident
- [the `fleetz` idea](../ideas/fleetz.md)
