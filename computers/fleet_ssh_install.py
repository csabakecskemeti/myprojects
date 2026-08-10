#!/usr/bin/env python3
"""Install a fleet-managed block into ~/.ssh/config.

Strips any hand-written Host blocks for fleet-managed names (wherever they sit
in the file) and appends one marker-delimited block. Everything else survives,
including vendor-managed Include lines such as NVIDIA Sync's.

Idempotent. Backs up before writing.
"""
import json
import os
import re
import shutil
import socket
import time

BEGIN = "# BEGIN fleet-managed"
END = "# END fleet-managed"

# Machine list comes from fleet.json - the single source of truth. Looked for
# next to this script, then ~/.fleet.json. JSON not YAML: python3 parses it on
# every fleet host, PyYAML is missing on the Mac Pro.
def load_fleet():
    here = os.path.dirname(os.path.abspath(__file__))
    for cand in (os.path.join(here, "fleet.json"),
                 os.path.expanduser("~/.fleet.json")):
        if os.path.isfile(cand):
            data = json.load(open(cand))
            return [(m["name"], m["host"], m["user"], m.get("port", 22),
                     m.get("hostname", m["host"]))
                    for m in data["machines"] if m.get("managed", True)], cand
    raise SystemExit("error: fleet.json not found next to this script or at ~/.fleet.json")


FLEET, FLEET_SRC = load_fleet()
MANAGED = {name for name, *_ in FLEET}

# Emit IdentityFile only for keys that exist on THIS machine. The Macs and the
# OrangePi carry id_rsa, the DGX Sparks carry id_ed25519. Listing both
# unconditionally works, but ssh prints "no such identity: ..." on every
# connection for the missing one - noise on every command.
_CANDIDATES = ["id_ed25519", "id_rsa", "id_ecdsa"]
IDENTITY_LINES = [f"    IdentityFile ~/.ssh/{k}" for k in _CANDIDATES
                  if os.path.isfile(os.path.expanduser(f"~/.ssh/{k}"))] or \
                 [f"    IdentityFile ~/.ssh/{k}" for k in ("id_ed25519", "id_rsa")]

# Do not give a machine an alias pointing at itself.
me = socket.gethostname().split('.')[0].lower()


def render():
    lines = [f"{BEGIN} -- generated, do not edit by hand",
             "# Source: myprojects/computers/fleet.json  ·  regenerate, never hand-patch."]
    for name, host, user, port, hostname in FLEET:
        # `host` may be a pinned IP (see ws1 in fleet.json), which can never
        # match a hostname - so check the optional `hostname` field too.
        if me in (host.split('.')[0].lower(), hostname.split('.')[0].lower()):
            continue
        lines += [f"\nHost {name}",
                  f"    HostName {host}",
                  f"    User {user}",
                  f"    Port {port}",
                  *IDENTITY_LINES,
                  "    IdentitiesOnly yes"]
    lines.append(END)
    return "\n".join(lines) + "\n"


def strip_managed_hosts(text):
    """Remove Host blocks whose first pattern is a fleet-managed name."""
    out, skipping = [], False
    for line in text.split('\n'):
        m = re.match(r'^\s*Host\s+(.+?)\s*$', line, re.I)
        if m:
            skipping = m.group(1).split()[0] in MANAGED
        elif re.match(r'^\s*Match\s', line, re.I):
            skipping = False
        if not skipping:
            out.append(line)
    return '\n'.join(out)


path = os.path.expanduser('~/.ssh/config')
os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
original = open(path).read() if os.path.isfile(path) else ""

text = re.sub(re.escape(BEGIN) + r'.*?' + re.escape(END) + r'[^\n]*\n?', '',
              original, flags=re.S)
text = strip_managed_hosts(text)
text = re.sub(r'\n{3,}', '\n\n', text).strip()
text = (text + "\n\n" if text else "") + render()

if text == original:
    print("unchanged")
else:
    if os.path.isfile(path):
        shutil.copy2(path, f"{path}.bak.{time.strftime('%Y%m%d-%H%M%S')}")
    open(path, 'w').write(text)
    os.chmod(path, 0o600)
    print("updated")
