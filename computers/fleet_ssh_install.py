#!/usr/bin/env python3
"""Install a fleet-managed block into ~/.ssh/config.

Strips any hand-written Host blocks for fleet-managed names (wherever they sit
in the file) and appends one marker-delimited block. Everything else survives,
including vendor-managed Include lines such as NVIDIA Sync's.

Idempotent. Backs up before writing.
"""
import os
import re
import shutil
import socket
import time

BEGIN = "# BEGIN fleet-managed"
END = "# END fleet-managed"

# Single source of truth for the fleet's addressing.
FLEET = [
    ("macpro",     "Mac-Pro.local",            "csabakecskemeti", 22),
    ("macbook",    "MacBook-Pro-2.local",      "kecso",           22),
    ("opi",        "server-opi5p.local",       "kecso",           22),
    ("spark-7ceb", "spark-7ceb.local",         "kecso",           22),
    ("spark-db71", "spark-db71.local",         "kecso",           22),
    ("ws1",        "workstation2deb12.local",  "kecso",           22),
    ("macpro-wan", "71.202.66.108",            "csabakecskemeti", 8822),
]
MANAGED = {name for name, *_ in FLEET}

# Do not give a machine an alias pointing at itself.
me = socket.gethostname().split('.')[0].lower()


def render():
    lines = [f"{BEGIN} -- generated, do not edit by hand",
             "# Source: myprojects/computers/  ·  regenerate, never hand-patch."]
    for name, host, user, port in FLEET:
        if host.split('.')[0].lower() == me:
            continue
        lines += [f"\nHost {name}",
                  f"    HostName {host}",
                  f"    User {user}",
                  f"    Port {port}",
                  "    IdentityFile ~/.ssh/id_rsa",
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
