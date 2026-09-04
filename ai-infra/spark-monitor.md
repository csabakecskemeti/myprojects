---
title: Spark Monitor (OrangePi rack dashboard)
updated: 2026-09-03
---

# Spark Monitor

Touchscreen dashboard in the 1U rack, showing cluster state and offering buttons that run
commands on the head node. Code lives in the `quasar-deck` repo.

- Host: `server-opi5p` (OrangePi 5 Plus), display GeeekPi 6.91" 1424x280
- Also runs the `cloudflared` connector for `spark.devquasar.com` — see
  [remote-access.md](./remote-access.md)

## Config location — this trips people up

The deployed dashboard runs with **no `--config`**, so it loads:

```
~/.config/spark-monitor/config.json          <-- the live one
```

**Not** the `spark_monitor_gui.config.json` in the repo, which is only a template. The two
have genuinely drifted (the live one has a `DeepSeek+Vision` button the repo copy lacks).
Edit the `~/.config` copy to change the live dashboard.

Config is read **once at startup** and cached — edits need a dashboard restart.

## How the buttons work

Aliases execute **over SSH on the head node**, not on the OrangePi
(`spark_monitor_gui/detail_views.py:1044`):

```
ssh <target> 'source ~/.bashrc && nohup <alias> > /dev/null 2>&1 &'
```

The OrangePi has no `~/scripts/start-vllm.sh` at all, so there is exactly one copy of that
script to maintain: the head node's.

Current buttons, all calling `~/scripts/start-vllm.sh`:

| Label | Command |
|-------|---------|
| Start Qwen35B (nvfp4) | `start-vllm.sh qwen3.6-35b-a3b-nvfp4` (background) |
| DeepSeek+Vision | `start-vllm.sh deepseek-v4-flash --vision` (background) |
| Stop vLLM | `start-vllm.sh stop` (confirm) |
| vLLM Status | `start-vllm.sh status` |
| List Recipes | `start-vllm.sh list` |
| Nvidia SMI | `nvidia-smi` |

## Auth is handled — but only because of one line

The Start buttons restart LiteLLM. They come up **with** the master key because
`start-vllm.sh` launches it via `start-litellm.sh`, which loads `.env`. Before that fix
the script ran the `litellm` binary directly and would have silently brought the proxy up
keyless on a public endpoint.

Verified end to end: killed the proxy, started it through the GUI's exact SSH command
shape, then confirmed `LITELLM_MASTER_KEY` in the new process's environment and 401
without a key / 200 with one, on both LAN and tunnel.

## Careful: Start always reloads the model

`start_all()` **unconditionally** stops and removes the `vllm_node` container before
running the recipe, even when vLLM is already healthy and serving that same recipe. There
is no "already running, skip" guard like LiteLLM has.

So a Start button is never a no-op — it is always a full model reload. Fine when
deliberately switching models; expensive if tapped expecting nothing to happen.

## Restarting the dashboard

```bash
ssh kecso@server-opi5p.local "pkill -f spark_monitor_gui"
ssh kecso@server-opi5p.local "cd ~/Documents/workspace/quasar-deck && source .venv/bin/activate && \
  WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/\$(id -u) \
  nohup python -m spark_monitor_gui.main --screen 0 --fullscreen &"
```

Logs: `~/Documents/workspace/quasar-deck/spark_monitor_gui.log` (rotating).
