---
id: "003"
title: Enable linger on OrangePi so the tunnel survives reboot
status: active
priority: low
created: 2026-09-03
---

# Tunnel boot persistence

`cloudflared-spark.service` is a **user** systemd unit and is enabled, but user services
only start at boot when lingering is on. Needs a sudo password, which wasn't available
during setup:

```bash
ssh opi 'sudo loginctl enable-linger kecso'
```

## Decide first

Without linger, an OrangePi reboot takes the public endpoint down until someone starts
it. That may be **desirable** — it is the same kill switch that motivated putting the
connector on the OrangePi. Enable only if you want the endpoint to self-heal.

## Acceptance Criteria

- [ ] Decision made: self-healing vs. manual-start-after-reboot
- [ ] If self-healing: linger enabled and verified by rebooting the OrangePi
