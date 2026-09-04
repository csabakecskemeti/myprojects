#!/usr/bin/env bash
# fleet-push.sh — push fleet config to a machine.
#
#   ./fleet-push.sh ws1 macbook          # push to one or more ssh hosts
#
# Sends two files:
#   computers/fleet-aliases.sh (this repo, canonical) -> ~/.fleet-aliases.sh  0644
#   ~/.fleet-secrets.sh        (local, NOT in git)    -> ~/.fleet-secrets.sh  0600
#
# Also ensures the shell rc sources them. Secrets travel over scp only.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ALIASES="$REPO_DIR/fleet-aliases.sh"
SECRETS="$HOME/.fleet-secrets.sh"

[ -f "$ALIASES" ] || { echo "missing $ALIASES" >&2; exit 1; }
[ -f "$SECRETS" ] || { echo "missing $SECRETS - this machine has no fleet secrets" >&2; exit 1; }
[ $# -ge 1 ] || { echo "usage: $0 <ssh-host> [ssh-host...]" >&2; exit 1; }

BLOCK_BEGIN='# BEGIN fleet-managed -- generated, do not edit by hand'

for host in "$@"; do
  echo "==> $host"
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" true 2>/dev/null; then
    echo "    unreachable, skipped"; continue
  fi
  scp -q "$ALIASES" "$host:~/.fleet-aliases.sh"
  scp -q "$SECRETS" "$host:~/.fleet-secrets.sh"
  ssh "$host" "chmod 644 ~/.fleet-aliases.sh; chmod 600 ~/.fleet-secrets.sh"

  # Ensure the managed block exists in whichever rc files the host uses.
  ssh "$host" "for rc in ~/.zshrc ~/.bashrc; do
      [ -f \"\$rc\" ] || continue
      grep -q 'BEGIN fleet-managed' \"\$rc\" && continue
      {
        echo ''
        echo '$BLOCK_BEGIN'
        echo '# Source: myprojects/computers/  ·  regenerate, never hand-patch.'
        echo '[ -f ~/.fleet-prompt.sh ]  && . ~/.fleet-prompt.sh'
        echo '[ -f ~/.fleet-aliases.sh ] && . ~/.fleet-aliases.sh'
        echo '# END fleet-managed'
      } >> \"\$rc\"
      echo \"    added fleet block to \$rc\"
    done"

  ssh "$host" ". ~/.fleet-aliases.sh; printf '    base=%s model=%s\n' \"\$(fleet_llm_base)\" \"\$(fleet_llm_model)\""
done
echo "done."
