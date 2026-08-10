#!/bin/bash
# fleet-check.sh — verify managed config is deployed and identical fleet-wide.
#
# Answers "is the fleet actually in the state I think it is?" — the question
# hand-deployment can never answer. Run from any machine that can reach the
# others (currently only the MacBook reaches all; see the connectivity matrix
# in computers/README.md).
#
# Usage:  ./fleet-check.sh [hosts...]      default: every managed machine
#                                          except the one you are running on
#
# The default list comes from fleet.json, not a hardcoded string: a hardcoded
# list silently omits new machines, which is exactly how ws1 stayed invisible
# after it was added.

REPO="$(cd "$(dirname "$0")" && pwd)"
HOSTS=${*:-$(python3 -c '
import json,sys,socket
me = socket.gethostname().split(".")[0].lower()
for m in json.load(open(sys.argv[1]))["machines"]:
    if m.get("alias_only") or not m.get("managed", True): continue
    names = {m["host"].split(".")[0].lower(),
             m.get("hostname", m["host"]).split(".")[0].lower()}
    if me in names: continue
    print(m["name"])
' "$REPO/fleet.json")}

sum() { [ -f "$1" ] && (shasum -a 256 "$1" 2>/dev/null || sha256sum "$1") | cut -c1-8 || echo "-------"; }

echo "Reference (repo: $REPO)"
REF_PROMPT=$(sum "$REPO/fleet-prompt.sh")
REF_ALIAS=$(sum "$REPO/fleet-aliases.sh")
echo "  fleet-prompt.sh  $REF_PROMPT"
echo "  fleet-aliases.sh $REF_ALIAS"
echo
printf "%-12s %-10s %-10s %-8s %-8s\n" HOST PROMPT ALIASES RC-BLOCK SSH-BLOCK

check_local() {
  printf "%-12s " "$(hostname -s)"
  p=$(sum ~/.fleet-prompt.sh); a=$(sum ~/.fleet-aliases.sh)
  [ "$p" = "$REF_PROMPT" ] && ps="ok" || ps="DRIFT"
  [ "$a" = "$REF_ALIAS" ] && as="ok" || as="DRIFT"
  # Report have/total, and flag any file carrying more than one block -
  # a bare sum cannot tell "3 files x 1" from "1 file x 3", which is the
  # duplicate case this check exists to catch.
  have=0; tot=0; dup=""
  for f in ~/.zshrc ~/.bashrc ~/.bash_profile; do
    [ -f "$f" ] || continue
    tot=$((tot + 1)); n=$(grep -c 'BEGIN fleet-managed' "$f")
    [ "$n" -ge 1 ] && have=$((have + 1))
    [ "$n" -gt 1 ] && dup="!"
  done
  rc="$have/$tot$dup"
  sn=$(grep -c 'BEGIN fleet-managed' ~/.ssh/config 2>/dev/null || echo 0)
  [ "$sn" -gt 1 ] && sc="$sn!" || sc="$sn"
  printf "%-10s %-10s %-8s %-8s\n" "$ps" "$as" "$rc" "$sc"
}

check_local

for h in $HOSTS; do
  printf "%-12s " "$h"
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" '
    s() { [ -f "$1" ] && (shasum -a 256 "$1" 2>/dev/null || sha256sum "$1") | cut -c1-8 || echo "-------"; }
    p=$(s ~/.fleet-prompt.sh); a=$(s ~/.fleet-aliases.sh)
    have=0; tot=0; dup=""
    for f in ~/.zshrc ~/.bashrc ~/.bash_profile; do
      [ -f "$f" ] || continue
      tot=$((tot + 1)); n=$(grep -c "BEGIN fleet-managed" "$f")
      [ "$n" -ge 1 ] && have=$((have + 1))
      [ "$n" -gt 1 ] && dup="!"
    done
    sn=$(grep -c "BEGIN fleet-managed" ~/.ssh/config 2>/dev/null || echo 0)
    [ "$sn" -gt 1 ] && sc="$sn!" || sc="$sn"
    echo "$p $a $have/$tot$dup $sc"' 2>/dev/null | {
    read -r p a rc sc
    if [ -z "$p" ]; then printf "%-10s\n" "UNREACHABLE"; else
      [ "$p" = "$REF_PROMPT" ] && ps="ok" || ps="DRIFT"
      [ "$a" = "$REF_ALIAS" ] && as="ok" || as="DRIFT"
      printf "%-10s %-10s %-8s %-8s\n" "$ps" "$as" "$rc" "$sc"
    fi; }
done
