#!/bin/bash
# fleet-deploy.sh — push managed config from this repo to every machine.
#
# Closes the gap where fleet-check.sh could *detect* drift but nothing fixed
# it. Copies the managed files, then runs the two installers remotely.
#
# Idempotent. Safe to re-run. Machines that are unreachable are skipped and
# reported, not treated as errors.
#
# Usage:
#   ./fleet-deploy.sh              deploy to every reachable machine
#   ./fleet-deploy.sh macpro opi   deploy to specific ones
#   ./fleet-deploy.sh --local      only this machine

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
FLEET_JSON="$HERE/fleet.json"

# Files copied to ~ on each machine. fleet.json must travel with the ssh
# installer - it reads the machine list from it.
PAYLOAD="fleet-prompt.sh fleet-aliases.sh"
TOOLS="fleet.json fleet_ssh_install.py fleet_rc_install.py"

deploy_local() {
  cp "$HERE/fleet-prompt.sh"  ~/.fleet-prompt.sh
  cp "$HERE/fleet-aliases.sh" ~/.fleet-aliases.sh
  printf "  rc:  "; python3 "$HERE/fleet_rc_install.py"
  printf "  ssh: "; python3 "$HERE/fleet_ssh_install.py"
}

if [ "${1:-}" = "--local" ]; then
  echo "$(hostname -s) (local)"; deploy_local; exit 0
fi

TARGETS="${*:-}"
if [ -z "$TARGETS" ]; then
  TARGETS=$(python3 -c '
import json,sys,socket
me = socket.gethostname().split(".")[0].lower()
for m in json.load(open(sys.argv[1]))["machines"]:
    if m.get("alias_only") or not m.get("managed", True): continue
    if m["host"].split(".")[0].lower() == me: continue
    print(m["name"])
' "$FLEET_JSON")
fi

echo "$(hostname -s) (local)"; deploy_local; echo

for h in $TARGETS; do
  echo "$h"
  if ! ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$h" true 2>/dev/null; then
    echo "  unreachable — skipped"; echo; continue
  fi
  ( cd "$HERE" && scp -q $PAYLOAD "$h:/tmp/" && scp -q $TOOLS "$h:/tmp/" ) || {
    echo "  copy failed"; echo; continue; }
  ssh -n "$h" '
    cp /tmp/fleet-prompt.sh  ~/.fleet-prompt.sh
    cp /tmp/fleet-aliases.sh ~/.fleet-aliases.sh
    printf "  rc:  "; python3 /tmp/fleet_rc_install.py
    printf "  ssh: "; python3 /tmp/fleet_ssh_install.py
    rm -f /tmp/fleet-prompt.sh /tmp/fleet-aliases.sh /tmp/fleet.json \
          /tmp/fleet_ssh_install.py /tmp/fleet_rc_install.py' 2>/dev/null
  echo
done

echo "Verify:  ./fleet-check.sh"
