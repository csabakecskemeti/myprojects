---
slug: remote-access-infra
status: active
priority: high
created: 2026-06-14
target_date:
parent: unified-multi-machine-workflow
---

# Remote Access Infrastructure

## Description

Be able to access any machine from any other machine, securely and reliably. This includes SSH access, remote desktop when needed, and access to services running on each machine (like local LLM inference).

## Why It Matters

- Work from MacBook but run heavy jobs on workstation
- Access home machines while traveling
- Use DGX Spark cluster from any location
- Expose local services (LLM inference) to other machines

## Machines & Access Requirements

| From → To | SSH | Services | GUI |
|-----------|-----|----------|-----|
| Mac Pro → Workstation | yes | LLM API | optional |
| Mac Pro → DGX Sparks | yes | vLLM/llama.cpp | no |
| MacBook → Mac Pro | yes | all services | optional |
| MacBook → Workstation | yes | LLM API | optional |
| MacBook → DGX Sparks | yes | inference | no |
| Any → Any | yes | varies | varies |

## Components

### SSH Infrastructure
- [ ] SSH keys distributed to all machines
- [ ] SSH config with host aliases
- [ ] Jump host setup for external access (if needed)
- [ ] Passwordless sudo where appropriate

### Network Access
- [ ] Tailscale or similar mesh VPN
- [ ] Or: Dynamic DNS + port forwarding
- [ ] Or: WireGuard self-hosted
- [ ] Firewall rules configured

### Service Exposure
- [ ] LLM inference endpoints accessible
- [ ] agent-hub accessible from all machines
- [ ] Monitoring dashboards (quasar-deck) accessible

### Security
- [ ] 2FA where possible
- [ ] Fail2ban or similar
- [ ] Regular key rotation
- [ ] Audit logging

## Approach Options

| Approach | Pros | Cons |
|----------|------|------|
| **Tailscale** | Easy, secure, NAT traversal | Dependency on service |
| **WireGuard** | Self-hosted, fast | More setup |
| **SSH tunnels** | Simple, no extra software | Manual, per-service |
| **Cloudflare Tunnel** | No port forwarding needed | Another dependency |

## Success Criteria

- [ ] SSH to any machine from anywhere with single command
- [ ] Access LLM inference from any machine
- [ ] Access agent-hub from any machine
- [ ] Secure (no exposed ports to public internet)
- [ ] Works even when home IP changes

## Contributing Projects

| Project | Status | Contribution |
|---------|--------|--------------|
| dgx-spark-playbooks | backlog | DGX Spark access setup |
| agent-hub | active | Needs to be accessible from all machines |
| quasar-deck | active | Monitoring accessible remotely |

## Progress Notes

- 2026-06-14: Goal created as sub-goal of unified-multi-machine-workflow
