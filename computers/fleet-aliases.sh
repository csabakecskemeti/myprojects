#!/bin/sh
# computers/fleet-aliases.sh — CANONICAL source for ~/.fleet-aliases.sh
#
# MANAGED FILE — identical on every machine. Edit THIS file in the myprojects
# tracker, then redistribute (see computers/README-fleet.md).
# Secrets never live here; they come from ~/.fleet-secrets.sh (chmod 600, not in git).

# --- secrets ----------------------------------------------------------------
# Provides SPARK_API_KEY, SPARK_BASE_URL_LAN, SPARK_BASE_URL_REMOTE.
[ -f ~/.fleet-secrets.sh ] && . ~/.fleet-secrets.sh

# --- ssh shortcuts ----------------------------------------------------------
# Addressing lives in ~/.ssh/config, never here. If a host moves, one line in
# that file changes and every alias below keeps working.
alias ssh_macpro="ssh macpro"
alias ssh_macbook="ssh macbook"
alias ssh_opi="ssh opi"
alias ssh_spark1="ssh spark-7ceb"
alias ssh_spark2="ssh spark-db71"
alias ssh_ws1="ssh ws1"

# --- local LLM cluster ------------------------------------------------------
# Override per machine by exporting FLEET_LLM_HOST before this file is sourced.
: "${FLEET_LLM_HOST:=spark-db71.local}"
: "${SPARK_BASE_URL_LAN:=http://${FLEET_LLM_HOST}:4000}"
: "${SPARK_BASE_URL_REMOTE:=https://spark.devquasar.com}"

# Pick an endpoint at call time: LAN when we're home, Cloudflare tunnel otherwise.
# No probe at source time - shell startup must stay instant.
fleet_llm_base() {
  if [ -n "$FLEET_LLM_FORCE" ]; then echo "$FLEET_LLM_FORCE"; return; fi
  if curl -s --max-time 1 -o /dev/null "${SPARK_BASE_URL_LAN}/health" 2>/dev/null; then
    echo "$SPARK_BASE_URL_LAN"
  else
    echo "$SPARK_BASE_URL_REMOTE"
  fi
}
alias fleet_use_lan='export FLEET_LLM_FORCE="$SPARK_BASE_URL_LAN"'
alias fleet_use_remote='export FLEET_LLM_FORCE="$SPARK_BASE_URL_REMOTE"'
alias fleet_use_auto='unset FLEET_LLM_FORCE'

# Model currently served by the cluster. Prints nothing if it is down.
# Goes through LiteLLM (:4000) so it works over the tunnel too, and so it needs
# the master key - vLLM's own :8000 is LAN-only and unauthenticated.
fleet_llm_model() {
  curl -s --max-time 3 "$(fleet_llm_base)/v1/models" \
    -H "Authorization: Bearer ${SPARK_API_KEY}" 2>/dev/null |
    grep -o '"id":"[^"]*"' | grep -v '"id":"claude-\*"' | head -1 | cut -d'"' -f4
}

# Run Claude Code against whatever the cluster is currently serving.
claude-local() {
  base=$(fleet_llm_base)
  model=$(fleet_llm_model)
  if [ -z "$model" ]; then
    echo "Error: no model available at ${base} (cluster down, or SPARK_API_KEY unset/stale)"
    return 1
  fi
  echo "Using model: $model  via $base"
  ANTHROPIC_BASE_URL="$base" \
  ANTHROPIC_API_KEY="$SPARK_API_KEY" \
  claude --model "$model" "$@"
}

# Consumed by the local-llm skill-vault plugin.
export LOCAL_LLM_URL="$SPARK_BASE_URL_LAN"
export LOCAL_LLM_API_KEY="$SPARK_API_KEY"

# LOCAL_LLM_MODEL is deliberately NOT set. Pinning a model name means it goes
# stale the moment the cluster loads something else - which already happened
# once (Qwen3.6-35B-A3B-FP8). The plugin resolves the served model at call
# time via fleet_llm_model(). Export it only to force a specific model.
