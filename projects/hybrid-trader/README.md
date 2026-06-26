---
slug: hybrid-trader
created: 2025-06-25
---

# Hybrid Trader

AI-assisted options trading system combining Claude research with automated monitoring.

## Problem

- Manual options trading requires constant monitoring and research
- Fully automated trading systems are risky and opaque
- Need a balance between AI assistance and human control
- Tracking Greeks, news, and market context is time-consuming

## Solution

A **hybrid** approach to options trading:
- **Research Phase**: Use Claude (web UI) to find trades, analyze stocks, select contracts
- **Monitoring Phase**: Automated daily dashboard tracks positions, Greeks, alerts, news
- **Execution**: Manual - you stay in the loop for all trades

This balances automation with control, perfect for learning and managing risk.

## Tech Stack

- **Language:** Python 3
- **Data Source:** Yahoo Finance (free)
- **AI Analysis:** Claude API (optional, for news/geopolitical analysis)
- **Interface:** Terminal dashboard + Web dashboard

## Current State

- [x] Core terminal dashboard with position tracking
- [x] Options Greeks calculation and display
- [x] Paper trading simulator
- [x] Claude-powered news analysis
- [x] Geopolitical analysis layer
- [x] Live web dashboard with auto-refresh
- [ ] Replay/backtesting with historical data
- [ ] Telegram/Discord notifications
- [ ] IBKR API integration for automated execution

## Getting Started

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config/.env.example config/.env
# Add ANTHROPIC_API_KEY to config/.env

# Paper trading (recommended first)
python main.py paper

# Terminal dashboard
python main.py terminal --news
```

## Key Files

- `main.py` - Entry point with CLI commands
- `src/data/` - Layer 1: Data & Valuation
- `src/analytics/` - Layer 2: Portfolio Analytics
- `src/market/` - Layer 3: Market Context
- `src/alerts/` - Layer 4: Alerts & Dashboard
- `src/simulator/` - Paper trading system
- `config/portfolio.yaml` - Position configuration
- `prompts/research_prompts.md` - Claude prompts for research phase

## Commands

| Command | Description |
|---------|-------------|
| `python main.py terminal` | Run options terminal dashboard |
| `python main.py terminal --news` | Include Claude news analysis |
| `python main.py terminal --full` | All analyses (news + geopolitical) |
| `python main.py paper` | Interactive paper trading |
| `python main.py value` | Quick portfolio valuation |
| `python main.py macro` | Quick macro check |
