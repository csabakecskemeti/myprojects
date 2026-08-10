---
title: Fleet Management
updated: 2026-08-10
---

# Fleet Management

How the machines are kept in sync. For *what* the machines are — hardware,
roles, tiers — see [README.md](./README.md).

---

## 1. The mental model

Three ideas explain everything else.

### Three layers, changing at different rates

| Layer | Encodes | Lives in | Changes when |
|---|---|---|---|
| **Hostname** | stable hardware identity | the machine itself | it is replaced |
| **SSH alias** | how you refer to it | `~/.ssh/config` | an address moves |
| **Role / tier** | what it is *for* | `fleet.json` | priorities change |

Keeping these separate is why roles are **never** encoded in hostnames, and
why shell aliases call `ssh opi` rather than `ssh kecso@192.168.7.100`. When
an address changes, exactly one line in one file changes.

### Three distributions, each failing differently

Passwordless SSH is not one thing. It is three, and having only some produces
confusing partial failures:

| Distribution | Symptom when missing |
|---|---|
| `~/.ssh/config` | `Could not resolve hostname macpro` |
| `authorized_keys` | resolves, then prompts for a **password** |
| `known_hosts` | connects, then prompts to **confirm the host key** — fatal for anything unattended |

They fail in that order as you fix them, which is why it feels like whack-a-mole.

### One managed block, everything else sourced

Shell rc files contain **only** this:

```sh
# BEGIN fleet-managed -- generated, do not edit by hand
# Source: myprojects/computers/fleet.json  ·  regenerate, never hand-patch.
[ -f ~/.fleet-prompt.sh ]  && . ~/.fleet-prompt.sh
[ -f ~/.fleet-aliases.sh ] && . ~/.fleet-aliases.sh
# END fleet-managed
```

All real content lives in the two sourced files. Updating the fleet means
**replacing those files**, never editing anything inside an rc file. The same
marker convention is used in `~/.ssh/config`, so regeneration replaces only
what is between the markers — hand-written and vendor-managed config outside
them survives (notably NVIDIA Sync's `Include`).

---

## 2. The files

Everything lives in `computers/` in the `myprojects` tracker.

### Data — the single source of truth

| File | What |
|---|---|
| **`fleet.json`** | Every machine: name, host, user, port, roles, tier, prompt colour, endpoints. **Edit this, not the scripts.** |

JSON rather than YAML deliberately: `python3` parses it on every fleet host,
while PyYAML is missing on the Mac Pro.

### Managed files — deployed to every machine

| File | Becomes | Contains |
|---|---|---|
| `fleet-prompt.sh` | `~/.fleet-prompt.sh` | unified prompt: per-host colour, git branch |
| `fleet-aliases.sh` | `~/.fleet-aliases.sh` | `ssh_*` shortcuts, `claude-local`, `fleet_llm_model`, `LOCAL_LLM_URL` |

### Tools

| Script | Does | Run it |
|---|---|---|
| `fleet-bootstrap.sh` | keys, keypairs, `known_hosts` — builds passwordless SSH from scratch | once per new machine |
| `fleet-deploy.sh` | copies managed files, runs both installers everywhere | after any change |
| `fleet-check.sh` | verifies deployment, detects drift and duplicates | any time |
| `fleet_ssh_install.py` | writes the `~/.ssh/config` managed block from `fleet.json` | via deploy |
| `fleet_rc_install.py` | writes the rc managed block, strips hand-placed copies | via deploy |
| `fleet_known_hosts_clean.py` | removes malformed `known_hosts` lines | repair only |

---

## 3. Common tasks

### Check the current state

```sh
cd ~/myprojects/computers
./fleet-check.sh
```

```
HOST         PROMPT     ALIASES    RC-BLOCK SSH-BLOCK
MacBook-Pro-2 ok         ok         3/3      1
macpro       ok         ok         3/3      1
opi          ok         ok         1/1      1
```

- **PROMPT / ALIASES** — `ok` means the deployed file matches the repo by
  checksum; `DRIFT` means it does not.
- **RC-BLOCK** — `files-with-block / rc-files-present`. "rc" is shell shorthand
  for **run-commands** (`~/.zshrc`, `~/.bashrc`, `~/.bash_profile`). The
  denominator varies: the OrangePi has only `.bashrc`.
- **SSH-BLOCK** — should always be `1`.
- A trailing **`!`** means a file holds *more than one* block — a duplicate.

### Change something everywhere

```sh
vim fleet-aliases.sh          # or fleet-prompt.sh, or fleet.json
./fleet-deploy.sh
./fleet-check.sh
git commit -am "fleet: ..." && git push
```

### Add a machine

1. Add an entry to `fleet.json`
2. `./fleet-bootstrap.sh` — reachability, keypair, keys, host keys
3. `./fleet-deploy.sh` — config and shell environment
4. `./fleet-check.sh`
5. Update the inventory table in [README.md](./README.md)

### Change a machine's address

Edit its `host` in `fleet.json`, then `./fleet-deploy.sh`. Nothing else
references the address — that is the entire point of the alias layer.

### Rebuild from scratch

Assumes bare machines with SSH enabled and this repo cloned somewhere.

```sh
# 1. One machine needs manual bootstrap - nothing can reach anything yet
ssh-copy-id kecso@server-opi5p.local      # per machine, prompts for password

# 2. From that machine, build the mesh
cd ~/myprojects/computers
./fleet-bootstrap.sh                      # prompts before each change

# 3. Deploy config and shell environment
./fleet-deploy.sh

# 4. Verify
./fleet-check.sh
```

`fleet-bootstrap.sh --check` reports without changing anything, and tells you
exactly which machines still need `ssh-copy-id`.

**What it cannot do for you:** the very first password-authenticated login.
Something has to establish the first trust, and that is a human typing a
password.

---

## 4. Troubleshooting

Every entry below is a bug that actually happened here.

### `Could not resolve hostname macpro`

`~/.ssh/config` is missing the managed block on that machine. The alias exists
(from `fleet-aliases.sh`) but there is no `Host` entry to resolve it.

```sh
./fleet-deploy.sh <machine>
```

### Resolves, then asks for a password

`authorized_keys` lacks that machine's key. Config was distributed, keys were
not — two separate distributions.

```sh
./fleet-bootstrap.sh
```

### `Are you sure you want to continue connecting (yes/no)?`

`known_hosts` has not been seeded. Harmless interactively, **fatal for
unattended use** — an agent cannot answer the prompt.

```sh
./fleet-bootstrap.sh      # step 5 seeds host keys
```

### `no such identity: ~/.ssh/id_ed25519`

The generated ssh block listed a key that does not exist on that machine.
`fleet_ssh_install.py` now emits `IdentityFile` only for keys actually present.
Re-run `./fleet-deploy.sh`.

### A machine can reach nothing, though its key is everywhere

Its ssh config pinned an `IdentityFile` it does not have, with
`IdentitiesOnly yes` — so it offered no usable identity. This hit the DGX
Sparks, which carry `id_ed25519` while everything else carries `id_rsa`.
Same fix: re-deploy.

### `command not found: ssh opi` at shell startup

An orphaned value. A cleanup pattern once matched only the assignment prefix
(`alias ssh_opi=`), leaving `"ssh opi"` alone on its line for the shell to
execute. `fleet_rc_install.py` now matches to end-of-line and strips orphans —
any line containing nothing but a quoted string.

```sh
./fleet-deploy.sh
zsh -lic exit          # should print nothing
```

### A duplicate definition that silently shadows another

`fleet-check.sh` shows `3/3!`. The later definition wins in shell, so the stale
one is invisible until read by eye — this happened with two `claude-local`
definitions, one holding a hardcoded IP. Re-deploy; the installer strips
prior copies.

### `known_hosts` full of garbage lines

`ssh-keyscan` with too short a timeout emits truncated, interleaved output.

```sh
python3 fleet_known_hosts_clean.py     # keeps valid entries, backs up first
./fleet-bootstrap.sh
```

### `REMOTE HOST IDENTIFICATION HAS CHANGED` — on a machine that was not rebuilt

The alarming one, and here it was **not** an attack: the name was resolving to a
**different machine**.

The AI workstation holds `192.168.200.2` on the QSFP fabric, and so does
spark-7ceb. mDNS on the Sparks answers `ai-workstation.local` with that fabric
address rather than the LAN one, and ARP awards it to whichever host replies
first — so `ssh ai-workstation.local` from spark-db71 reached **spark-7ceb**,
presenting spark-7ceb's host key.

What made it confusing is that the tools disagreed:

```sh
getent hosts ai-workstation.local     # 192.168.7.117   (correct)
ssh-keyscan ai-workstation.local      # correct key
avahi-resolve -n ai-workstation.local # 192.168.200.2   (the collision)
ssh -v ai-workstation.local           # Connecting to ... [192.168.200.2]
```

`ssh -v` is the one that settles it — it prints the address actually dialled.
Compare the fingerprint against every fleet host to identify the impostor:

```sh
for h in spark-7ceb.local spark-db71.local server-opi5p.local; do
  printf '%-22s ' "$h"
  ssh-keyscan -T 6 -t ed25519 "$h" 2>/dev/null | ssh-keygen -lf - | awk '{print $2}'
done
```

**Do not just delete the known_hosts line** — that is the standard advice and
here it would have papered over an IP conflict. Fix the address, or pin the
machine to its LAN IP in `fleet.json` (which is what `ws1` does today).

### Letter case in hostnames

Case is **irrelevant for reaching a host**: OpenSSH lowercases the target before
resolving, and writes `known_hosts` lowercased. `ssh -G AI-workstation.local`
reports `hostname ai-workstation.local`, and mDNS is case-insensitive.

Case **is** significant for `Host` **patterns** in `~/.ssh/config`. Keep
everything generated in lowercase and the question never arises.

### A loop that only processes the first machine

`ssh` inside a `while read` loop consumes the loop's stdin. Use `ssh -n`.
Not a fleet bug as such, but it bit these scripts twice.

---

## 5. Local LLM helpers

Provided by `~/.fleet-aliases.sh` on every machine:

```sh
fleet_llm_model     # prints the model the cluster is serving, or nothing
claude-local        # runs Claude Code against that model via the proxy
```

```
$ claude-local
Using model: deepseek-ai/DeepSeek-V4-Flash
```

`FLEET_LLM_HOST` (default `spark-db71.local`) overrides the cluster host.

**`LOCAL_LLM_MODEL` is deliberately unset.** Pinning a model name means it goes
stale the moment the cluster loads something else — which already happened
once, with `Qwen/Qwen3.6-35B-A3B-FP8`. The `local-llm` skill-vault plugin now
resolves the served model at call time. Export it only to force a specific
model.

> That bug is worth remembering: the plugin read its config from **`~/.zshenv`**
> — a third copy, beyond `~/.zshrc` and `~/.fleet-aliases.sh` — and because
> `~/.zshenv` is sourced by *every* zsh, the stale values were in every shell's
> environment and won over anything set later. Config in three places is how
> things break quietly.

---

## 6. Connectivity

Full mesh — every machine reaches every other without a password or prompt.
Verified 2026-08-10 across all six; regenerate with `./fleet-bootstrap.sh --check`.

|            | macpro | macbook | opi | spark-7ceb | spark-db71 | ws1 |
|------------|--------|---------|-----|------------|------------|-----|
| **macbook**   | OK   | –       | OK  | OK         | OK         | OK  |
| **macpro**    | –    | OK      | OK  | OK         | OK         | OK  |
| **opi**       | OK   | OK      | –   | OK         | OK         | OK  |
| **spark-7ceb**| OK   | OK      | OK  | –          | OK         | OK  |
| **spark-db71**| OK   | OK      | OK  | OK         | –          | OK  |
| **ws1**       | OK   | OK      | OK  | OK         | OK         | –   |

Each machine authenticates outbound with its **own** key: Macs and the
OrangePi carry `id_rsa`, the Sparks and the workstation carry `id_ed25519`.

A machine is deliberately given **no alias pointing at itself** — so testing the
mesh with a nested `ssh $a "ssh $b true"` makes the diagonal machine's whole row
fail for a reason that has nothing to do with connectivity. Test the local
machine's row directly, without the outer hop.

Host keys were seeded with `ssh-keyscan` — trust-on-first-use over the LAN.
Re-seed if a machine is rebuilt.

**Security note.** Every machine can now log into every other, so a compromise
anywhere reaches everywhere. That is deliberate — cross-machine agent work
needs it — but the Sparks arguably do not, being pure inference targets.
Narrow it by removing their keys from the others' `authorized_keys`.

---

## 7. Deliberately not in this repo

The fleet's **data** is excluded even though the tooling is committed:

| Artefact | Why not here |
|---|---|
| collected public keys | identifies every machine and account in one file |
| collected host keys | same, and regenerable with `ssh-keyscan` |

Public keys are not secrets, but they are the "mildly sensitive inventory" case
from [the `fleetz` idea](../ideas/fleetz.md): the generator is publishable, the
fleet data is not. Once `myprojects-private` exists (Phase 2 of the steward
roadmap) that is where they belong. Regenerate rather than store.

---

## 8. Known gaps

| Gap | Impact |
|---|---|
| `ws1` is addressed by **IP**, not name | a DHCP lease change breaks it silently. Forced by the `192.168.200.2` collision; needs a reservation, or the fabric renumbered |
| Prompt colour map is a hardcoded `case` | duplicated on every box; `prompt_color` already exists in `fleet.json` but nothing consumes it yet — adding `ws1` meant hand-editing the `case` again |
| `fleet-aliases.sh` `ssh_*` list is hand-written | same: `ssh_ws1` had to be added by hand, though `fleet.json` already knows the machine |
| `README.md` inventory is hand-written | should be generated from `fleet.json`; the two can drift |
| `.bak.*` files accumulate | every install leaves timestamped backups on every machine |
| No deployment record | the repo holds tooling, not a log of what was installed where and when |

All of these are what [the `fleetz` idea](../ideas/fleetz.md) exists to close —
turning this directory into a proper generator published to `skill-vault`.

---

## Related

- [README.md](./README.md) — machine inventory: hardware, roles, tiers
- [the `fleetz` idea](../ideas/fleetz.md) — generalising this into a skill
- [the `sync-dev-environment` goal](../goals/sync-dev-environment.md)
- [the steward architecture doc](../projects/steward/docs/steward-architecture.md)
