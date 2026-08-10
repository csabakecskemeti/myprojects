#!/bin/sh
# ~/.fleet-aliases.sh — shared aliases and helper functions across the fleet.
#
# MANAGED FILE — identical on every machine. Do not edit on one box only;
# edit computers/fleet-aliases.sh in the myprojects tracker and redistribute.
# See ideas/fleetz.md for the generator that will eventually own this.

# --- ssh shortcuts ----------------------------------------------------------
# Addressing lives in ~/.ssh/config, never here. If a host moves, one line in
# that file changes and every alias below keeps working.
alias ssh_macpro="ssh macpro"
alias ssh_macbook="ssh macbook"
alias ssh_opi="ssh opi"
alias ssh_spark1="ssh spark-7ceb"
alias ssh_spark2="ssh spark-db71"

# --- local LLM cluster ------------------------------------------------------
# Override per machine by exporting FLEET_LLM_HOST before this file is sourced.
: "${FLEET_LLM_HOST:=spark-db71.local}"

# Model currently served by vLLM on the cluster. Prints nothing if it is down.
fleet_llm_model() {
  curl -s --max-time 2 "http://${FLEET_LLM_HOST}:8000/v1/models" 2>/dev/null |
    grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4
}

# Run Claude Code against whatever the cluster is currently serving.
claude-local() {
  model=$(fleet_llm_model)
  if [ -z "$model" ]; then
    echo "Error: vLLM not running or no model loaded on ${FLEET_LLM_HOST}"
    return 1
  fi
  echo "Using model: $model"
  ANTHROPIC_BASE_URL="http://${FLEET_LLM_HOST}:4000" \
  ANTHROPIC_API_KEY=vllm \
  claude --model "$model" "$@"
}

# Consumed by skill-vault/plugins/local-llm/scripts/local-llm.sh.
export LOCAL_LLM_URL="http://${FLEET_LLM_HOST}:4000"

# STOPGAP: this plugin takes a pinned model name via env, so it cannot follow
# the cluster. It was already stale once (Qwen3.6-35B-A3B-FP8, no longer
# served). Resolving a model here would mean a curl on every shell start, which
# is slow and fails when the cluster is off — so the fix belongs in the plugin:
# it should call fleet_llm_model() at use time. Tracked in computers/README.md.
export LOCAL_LLM_MODEL="deepseek-v4"
