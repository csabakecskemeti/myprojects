---
id: "001"
title: Phase 0 - Harden agent-hub
status: active
priority: high
created: 2026-08-08
---

# Phase 0 - Harden agent-hub

`agent-hub` is the linchpin of four goals and is currently 1 commit,
`repo: (local only - not pushed to remote yet)`, with no service unit. This is
the only phase that is urgent rather than merely next.

## Acceptance Criteria

- [ ] Pushed to a GitHub remote; `projects/agent-hub/MAP.md` updated with the
      real repo URL
- [ ] `systemd` unit on the OrangePi, enabled, restarts on failure
- [ ] Reachable over Tailscale from every machine
- [ ] SQLite marked vault-class: excluded from any public or cloud backup
- [ ] Health endpoint the router can probe

## Done When

Reboot the OrangePi and every machine can send and receive a message with zero
manual steps.

## Unblocks

UC-5 (delegate heavy compute), UC-8 (always-on box dies)
