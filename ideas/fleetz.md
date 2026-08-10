---
slug: fleetz
status: brainstorming
created: 2026-08-09
updated: 2026-08-09
tags: [skill-vault, dotfiles, ssh, multi-machine, codegen]
converted_to:
---

# fleetz — generate SSH config and aliases from a machine inventory

A `skill-vault` skill that takes a **declarative fleet description** and
generates the SSH config, shell aliases and helper functions on every machine —
so cross-machine access is defined once and applied everywhere.

Sibling to [[projectz]]: same pattern, different domain. `projectz` tracks
projects in git; `fleetz` tracks *machines* and renders working config from it.

## The Idea

Today the fleet's addressing lives in four places that drift independently:

- `~/.ssh/config` on each machine, hand-edited
- `~/.zshrc` aliases, hand-edited
- `~/.bash_profile` aliases, hand-edited — **already drifted**, held a stale IP
  while `.zshrc` held the hostname
- `computers/README.md`, written by hand after the fact

One source of truth should generate the other three.

```
computers/fleet.yaml   ← the only thing edited by hand
        │
        ├──▶ ~/.ssh/config           (managed block)
        ├──▶ ~/.zshrc / ~/.bashrc    (managed block)
        ├──▶ ~/.fleet-prompt.sh      (unified prompt, per-host colour)
        ├──▶ helper functions        (claude-local, tunnels, …)
        └──▶ computers/README.md     (generated inventory table)
```

**Three of these five outputs already exist by hand** (2026-08-09): the ssh
config blocks, `~/.fleet-prompt.sh`, and `claude-local` were deployed manually
across five machines. That is the proof the generator is worth writing — the
manual version took a dozen ssh round-trips and produced one wrong hostname
(`Csabas-MacBook-Pro.local` instead of the canonical `MacBook-Pro-2.local`).

## Problem It Solves

- Same alias should mean the same thing on every machine; today it does not
- Adding a machine means editing N files on M machines by hand
- Addresses change (DHCP, new hardware, Tailscale rollout) and drift silently
- No single place answers "what machines do I have and how do I reach them"
- Onboarding a new machine is manual and error-prone

## Proposed Design

### Input: `computers/fleet.yaml`

```yaml
machines:
  - name: spark-db71
    aliases: [spark-db71, spark2]
    host: spark-db71.local
    user: kecso
    identity: ~/.ssh/id_rsa
    roles: [inference]
    tier: A+
    endpoints:
      vllm: http://spark-db71.local:8000
      proxy: http://spark-db71.local:4000
  - name: server-opi5p
    aliases: [opi]
    host: server-opi5p.local
    user: kecso
    roles: [always-on, display]
    tier: C
```

### Output: marker-delimited managed blocks

```
# BEGIN fleetz — generated, do not edit by hand
Host opi
    HostName server-opi5p.local
    ...
# END fleetz
```

**Marker-delimited blocks are the whole trick.** Regeneration replaces only
what is between the markers, so hand-written config outside them survives —
including vendor-managed blocks like NVIDIA Sync's `ssh_config`. Without this,
a generator eats your dotfiles the first time you run it twice.

### Commands (sketch)

| Command | Description |
|---------|-------------|
| `/fleetz` | Show the fleet: machines, roles, tiers, reachability |
| `/fleetz apply [machine]` | Render managed blocks locally, or on one/all machines |
| `/fleetz add <name>` | Interactively register a new machine |
| `/fleetz check` | Probe every machine: reachable? passwordless? drifted? |
| `/fleetz keys` | Distribute the public key fleet-wide |
| `/fleetz endpoints` | Show live service endpoints and health |

## Public vs private split

The reason this can be a public skill at all:

| Layer | Contents | Where |
|---|---|---|
| **Skill** | schema, generator, templates, commands | `skill-vault` — public, anonymous |
| **Data** | real hostnames, users, IPs, roles | the user's own tracker repo |

The skill ships an `example-fleet.yaml` with `machine-a.local` placeholders and
never contains anyone's addressing. Same model that already makes `projectz`
publishable while the tracker repo stays personal.

Open question: hostnames, internal IPs and usernames are mildly sensitive. If
`myprojects` is public, `fleet.yaml` may belong in `myprojects-private`
(see [steward architecture §7.5](../projects/steward/docs/steward-architecture.md))
with only the anonymized inventory rendered into the public repo. **Leaning
private for the source, public for the generated summary.**

## Brainstorm Notes

- Generalizes cleanly beyond SSH: `claude-local` and `~/.fleet-prompt.sh` are
  already per-machine artefacts that must exist identically everywhere —
  exactly the class of thing this generates
- The prompt's **per-host colour** is derived data: it should come from the
  machine's `roles`/`tier` in `fleet.yaml`, not a hand-maintained `case`
  statement duplicated on every box (which is what exists today)
- Shell rc hooks already use `# BEGIN fleet-prompt` markers — the same
  convention the generator needs, so the migration path is clean
- Tailscale (Phase 0) changes every address at once. That migration is the
  strongest argument for generating rather than hand-editing: one file edit
  instead of 5 machines × 3 files
- Could render `computers/README.md` directly, replacing today's hand-written
  inventory with generated output
- Should probably *verify* as well as generate — `/fleetz check` catches drift,
  which is how the stale `.bash_profile` IP would have been caught
- Endpoint definitions (vLLM, proxy, agent-hub) overlap with the steward's
  `steward/inference.yaml` tier list. Possibly the same file — worth deciding
  before both exist

## Viability Assessment

### Pros

- Small, self-contained, useful immediately, independent of the steward
- Directly serves the [sync-dev-environment](../goals/sync-dev-environment.md)
  goal, which currently has only one contributing project
- Publishable to `skill-vault` with no anonymization difficulty
- The Tailscale migration gives it an immediate, concrete first job

### Cons

- Writing to dotfiles on remote machines is destructive if the marker logic is
  wrong. Needs backups and a dry-run mode before it ever writes
- Shell differences (zsh vs bash) and OS differences (macOS vs Debian vs DGX
  OS) mean templates, not one-size output
- Small enough that hand-editing 5 machines occasionally may just be cheaper —
  the honest counterargument

### Effort Estimate

- Prototype (yaml → ssh config + aliases, local only): a weekend
- Multi-machine apply with dry-run and backups: another weekend
- `skill-vault` release with anonymized example: small on top

## Decision

**Status: brainstorming**

Next steps:

1. Decide whether `fleet.yaml` lives in `myprojects` or `myprojects-private`
2. Decide whether it shares the endpoint list with `steward/inference.yaml`
3. Prototype the generator against the current five machines, dry-run only
4. Reassess when Tailscale lands — that migration is the real test

## Related

- [personal-ai-os](./personal-ai-os.md) — the umbrella
- [Machine fleet inventory](../computers/README.md) — today's hand-written version
- [sync-dev-environment](../goals/sync-dev-environment.md)
- [skill-vault](../projects/skill-vault/MAP.md)
