#!/bin/bash
# fleet-check.sh — verify managed config is deployed and identical fleet-wide.
#
# Answers "is the fleet actually in the state I think it is?" — the question
# hand-deployment can never answer. Run from any machine that can reach the
# others (currently only the MacBook reaches all; see the connectivity matrix
# in computers/README.md).
#
# Usage:  ./fleet-check.sh [hosts...]      default: macpro opi spark-7ceb spark-db71

HOSTS=${*:-"macpro opi spark-7ceb spark-db71"}
REPO="$(cd "$(dirname "$0")" && pwd)"

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
  rc=0; for f in ~/.zshrc ~/.bashrc ~/.bash_profile; do
    [ -f "$f" ] && rc=$((rc + $(grep -c 'BEGIN fleet-managed' "$f")))
  done
  sc=$(grep -c 'BEGIN fleet-managed' ~/.ssh/config 2>/dev/null || echo 0)
  printf "%-10s %-10s %-8s %-8s\n" "$ps" "$as" "$rc" "$sc"
}

check_local

for h in $HOSTS; do
  printf "%-12s " "$h"
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" '
    s() { [ -f "$1" ] && (shasum -a 256 "$1" 2>/dev/null || sha256sum "$1") | cut -c1-8 || echo "-------"; }
    p=$(s ~/.fleet-prompt.sh); a=$(s ~/.fleet-aliases.sh)
    rc=0; for f in ~/.zshrc ~/.bashrc ~/.bash_profile; do
      [ -f "$f" ] && rc=$((rc + $(grep -c "BEGIN fleet-managed" "$f")))
    done
    sc=$(grep -c "BEGIN fleet-managed" ~/.ssh/config 2>/dev/null || echo 0)
    echo "$p $a $rc $sc"' 2>/dev/null | {
    read -r p a rc sc
    if [ -z "$p" ]; then printf "%-10s\n" "UNREACHABLE"; else
      [ "$p" = "$REF_PROMPT" ] && ps="ok" || ps="DRIFT"
      [ "$a" = "$REF_ALIAS" ] && as="ok" || as="DRIFT"
      printf "%-10s %-10s %-8s %-8s\n" "$ps" "$as" "$rc" "$sc"
    fi; }
done
