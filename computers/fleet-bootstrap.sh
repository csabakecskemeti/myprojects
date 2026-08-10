#!/bin/bash
# fleet-bootstrap.sh — build (or rebuild) fleet-wide passwordless SSH.
#
# Three distributions are required. Having only some produces confusing
# partial failures:
#
#   ~/.ssh/config     missing -> "Could not resolve hostname macpro"
#   authorized_keys   missing -> resolves, then prompts for a password
#   known_hosts       missing -> connects, then prompts to confirm the host key
#                                (fatal for anything unattended)
#
# Reads computers/fleet.json. Idempotent — safe to re-run. Prompts before any
# change unless --yes is given.
#
# Usage:
#   ./fleet-bootstrap.sh            interactive
#   ./fleet-bootstrap.sh --yes      assume yes
#   ./fleet-bootstrap.sh --check    report only, change nothing

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
FLEET_JSON="$HERE/fleet.json"
ASSUME_YES=0; CHECK_ONLY=0
for a in "$@"; do
  case "$a" in
    --yes|-y) ASSUME_YES=1 ;;
    --check)  CHECK_ONLY=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ -f "$FLEET_JSON" ] || { echo "error: $FLEET_JSON not found" >&2; exit 1; }

ask() {  # ask "question" -> 0 yes, 1 no
  [ "$ASSUME_YES" = 1 ] && return 0
  [ "$CHECK_ONLY" = 1 ] && return 1
  printf "%s [y/N] " "$1" >&2; read -r r </dev/tty || return 1
  case "$r" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# name<TAB>host<TAB>user<TAB>port for real machines (skips alias_only entries)
MACHINES=$(python3 -c '
import json,sys
for m in json.load(open(sys.argv[1]))["machines"]:
    if m.get("alias_only") or not m.get("managed", True): continue
    print("\t".join([m["name"], m["host"], m["user"], str(m.get("port",22))]))
' "$FLEET_JSON")

echo "Fleet from $FLEET_JSON:"
echo "$MACHINES" | awk -F'\t' '{printf "  %-12s %-26s %s@:%s\n", $1, $2, $3, $4}'
echo

# --- 1. reachability --------------------------------------------------------
echo "== 1. reachability =="
REACHABLE=""
while IFS=$'\t' read -r name host user port; do
  [ -z "$name" ] && continue
  printf "  %-12s " "$name"
  # -n is essential: without it ssh consumes the loop's stdin (the here-string)
  # and the loop silently processes only the first machine.
  if ssh -n -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        -p "$port" "$user@$host" true 2>/dev/null; then
    echo "ok (passwordless)"; REACHABLE="$REACHABLE $name"
  elif ping -c1 -W 2000 "$host" >/dev/null 2>&1; then
    echo "up, but NOT passwordless — run: ssh-copy-id -p $port $user@$host"
  else
    echo "unreachable (powered off?)"
  fi
done <<< "$MACHINES"
echo

[ "$CHECK_ONLY" = 1 ] && { echo "(--check: stopping before any change)"; exit 0; }

# --- 2. keypairs ------------------------------------------------------------
echo "== 2. keypairs =="
for name in $REACHABLE; do
  line=$(echo "$MACHINES" | awk -F'\t' -v n="$name" '$1==n')
  host=$(echo "$line" | cut -f2); user=$(echo "$line" | cut -f3); port=$(echo "$line" | cut -f4)
  printf "  %-12s " "$name"
  keys=$(ssh -n -p "$port" "$user@$host" 'ls ~/.ssh/id_*.pub 2>/dev/null | xargs -n1 basename 2>/dev/null | tr "\n" " "' 2>/dev/null)
  if [ -n "$keys" ]; then
    echo "has: $keys"
  else
    echo "NO KEYPAIR"
    if ask "     generate an ed25519 keypair on $name?"; then
      ssh -p "$port" "$user@$host" 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q && echo "     generated"' 2>/dev/null
    fi
  fi
done
echo

# --- 3. collect public keys -------------------------------------------------
echo "== 3. collecting public keys =="
BUNDLE=$(mktemp); trap 'rm -f "$BUNDLE" "$KH"' EXIT
for name in $REACHABLE; do
  line=$(echo "$MACHINES" | awk -F'\t' -v n="$name" '$1==n')
  host=$(echo "$line" | cut -f2); user=$(echo "$line" | cut -f3); port=$(echo "$line" | cut -f4)
  ssh -n -p "$port" "$user@$host" 'cat ~/.ssh/id_*.pub 2>/dev/null' 2>/dev/null >> "$BUNDLE"
done
sort -u "$BUNDLE" -o "$BUNDLE"
echo "  $(wc -l < "$BUNDLE" | tr -d ' ') unique public keys"
awk '{print "    " $1 "  " $3}' "$BUNDLE"
echo

# --- 4. distribute authorized_keys -----------------------------------------
echo "== 4. authorized_keys =="
if ask "  append missing keys to authorized_keys on every reachable machine?"; then
  for name in $REACHABLE; do
    line=$(echo "$MACHINES" | awk -F'\t' -v n="$name" '$1==n')
    host=$(echo "$line" | cut -f2); user=$(echo "$line" | cut -f3); port=$(echo "$line" | cut -f4)
    printf "  %-12s " "$name"
    ssh -p "$port" "$user@$host" '
      mkdir -p ~/.ssh && chmod 700 ~/.ssh
      touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
      a=0; while IFS= read -r k; do [ -z "$k" ] && continue
        grep -qF "$k" ~/.ssh/authorized_keys || { printf "%s\n" "$k" >> ~/.ssh/authorized_keys; a=$((a+1)); }
      done; echo "added $a"' < "$BUNDLE" 2>/dev/null
  done
else
  echo "  skipped"
fi
echo

# --- 5. seed known_hosts ----------------------------------------------------
echo "== 5. known_hosts =="
KH=$(mktemp)
while IFS=$'\t' read -r name host user port; do
  [ -z "$name" ] && continue
  # -T 10: a short timeout silently truncates output and can interleave lines
  ssh-keyscan -T 10 -p "$port" -t rsa,ecdsa,ed25519 "$host" 2>/dev/null >> "$KH"
done <<< "$MACHINES"
sort -u "$KH" -o "$KH"
echo "  scanned $(wc -l < "$KH" | tr -d ' ') host keys (trust-on-first-use over the LAN)"
if ask "  merge into known_hosts on every reachable machine?"; then
  for name in $REACHABLE; do
    line=$(echo "$MACHINES" | awk -F'\t' -v n="$name" '$1==n')
    host=$(echo "$line" | cut -f2); user=$(echo "$line" | cut -f3); port=$(echo "$line" | cut -f4)
    printf "  %-12s " "$name"
    ssh -p "$port" "$user@$host" '
      mkdir -p ~/.ssh; touch ~/.ssh/known_hosts; chmod 600 ~/.ssh/known_hosts
      a=0; while IFS= read -r l; do [ -z "$l" ] && continue
        grep -qF "$l" ~/.ssh/known_hosts || { printf "%s\n" "$l" >> ~/.ssh/known_hosts; a=$((a+1)); }
      done; echo "added $a"' < "$KH" 2>/dev/null
  done
else
  echo "  skipped"
fi
echo

echo "== next =="
echo "  Deploy config and shell environment:"
echo "    for h in <aliases>; do"
echo "      scp fleet.json fleet_ssh_install.py fleet_rc_install.py \\"
echo "          fleet-prompt.sh fleet-aliases.sh \$h:"
echo "    done"
echo "  Then verify:  ./fleet-check.sh"
