---
slug: quasar-deck
created: 2026-06-10
---

# Quasar Deck

Monitoring tools for NVIDIA DGX Spark clusters, including both TUI and GUI applications.

## Problem

- Need real-time visibility into DGX Spark cluster health (GPU utilization, memory, temperature)
- Rack-mounted LCD displays require specialized GUI for ultra-wide aspect ratios
- Multiple nodes need unified monitoring dashboard
- Services (vLLM, LiteLLM, Ray) need health status indicators

## Solution

Two monitoring tools:
1. **quasar_deck.py** - Terminal-based multi-pane SSH monitoring (TUI)
2. **spark_monitor_gui.py** - PyQt6 GUI for rack-mount LCD displays

The GUI is optimized for GeeekPi 6.91" 1424x280 LCD touchscreens and runs on OrangePi 5 Plus.

## Tech Stack

- **Language:** Python 3.12
- **GUI Framework:** PyQt6 (Wayland compatible)
- **Metrics:** SSH + nvidia-smi
- **Health Checks:** curl to service endpoints
- **Platform:** OrangePi 5 Plus (ARM64), macOS for development

## Current State

- [x] TUI monitoring (quasar_deck.py)
- [x] GUI monitoring for rack LCD (spark_monitor_gui.py)
- [x] GPU metrics (utilization, memory, temperature)
- [x] Service health indicators (vLLM, LiteLLM, Ray)
- [x] Touch navigation with detail views
- [x] Screen protection (burn-in prevention, screensaver)
- [x] Autostart on boot (GNOME autostart)
- [x] Light/dark theme toggle

## Getting Started

```bash
git clone git@github.com:csabakecskemeti/quasar-deck.git
cd quasar-deck
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run GUI
python spark_monitor_gui.py --fullscreen
```

## Key Files

- `spark_monitor_gui.py` - Main GUI application
- `spark_monitor_gui.config.json` - Node and service configuration
- `quasar_deck.py` - TUI monitoring application
- `README-spark-monitor-gui.md` - Full GUI documentation
- `assets/sparky.png` - Screensaver logo

## Deployment

Runs on OrangePi 5 Plus (`server-opi5p.local`) with auto-login and GNOME autostart.
See README-spark-monitor-gui.md for setup details.
