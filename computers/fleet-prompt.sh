#!/bin/sh
# ~/.fleet-prompt.sh — unified shell prompt across the fleet.
# Same layout everywhere; the host segment is colour-coded per machine so you
# can tell at a glance which box you are on. Works in zsh and bash.
#
# Layout:  user@host ~/path (branch) %
#
# Managed file — see ideas/fleetz.md in the myprojects tracker.

# --- git branch, cheap ------------------------------------------------------
# Deliberately avoids `git status`: on large repos (llama.cpp, executorch)
# that makes every prompt slow. symbolic-ref is O(1).
__fleet_git_branch() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) ||
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return 0
  [ -n "$branch" ] && printf ' (%s)' "$branch"
}

# --- per-host colour --------------------------------------------------------
# 1 red · 2 green · 3 yellow · 4 blue · 5 magenta · 6 cyan
case "$(hostname -s 2>/dev/null)" in
  *MacBook*|*macbook*)   __FLEET_COLOR=6 ;;  # cyan    - travel
  *Mac-Pro*|*mac-pro*)   __FLEET_COLOR=2 ;;  # green   - desktop
  AI-workstation|ai-workstation|workstation*)
                         __FLEET_COLOR=1 ;;  # red     - heavy compute
  spark-*)               __FLEET_COLOR=5 ;;  # magenta - inference cluster
  server-opi5p|opi*)     __FLEET_COLOR=3 ;;  # yellow  - always-on
  *)                     __FLEET_COLOR=4 ;;  # blue    - unknown
esac

# --- prompt -----------------------------------------------------------------
if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST 2>/dev/null
  PROMPT="%F{${__FLEET_COLOR}}%n@%m%f %F{4}%~%f%F{3}\$(__fleet_git_branch)%f %# "
elif [ -n "$BASH_VERSION" ]; then
  PS1="\[\e[3${__FLEET_COLOR}m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\[\e[33m\]\$(__fleet_git_branch)\[\e[0m\] \$ "
fi
