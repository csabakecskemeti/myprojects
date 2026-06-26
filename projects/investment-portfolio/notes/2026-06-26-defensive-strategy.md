---
date: 2026-06-26
tags: [defensive-strategy, stop-loss, ibkr, travel, sentiment-risk]
---

# Defensive Strategy Session — Pre-Hungary Travel

## Context

Owner is traveling to Hungary from **June 30 – July 15, 2026**. Very limited ability to react to market moves during this period. Session focused on setting up GTC stop-loss orders in IBKR as a hands-off defense.

## Market Context (June 2026)

- **June 23 sell-off:** NVDA -6%, TSM -5%, KOSPI -10% (circuit breakers triggered)
- ~$1.4T wiped from AI/semi sector in a single session
- **South Korea KOSPI** had rallied ~90% YTD on AI chip mania — Samsung + SK Hynix = 40% of index. When sentiment cracks, Korea leads the move.
- **TSMC ITC patent investigation** (Longitude Licensing + Marlin Semiconductor): preliminary ruling expected end of June 2026. Potential US import ban on AI chip tech = live binary event risk.
- **Samsung strike** averted via $26.6B bonus pool, but labor risk narrative lingers.
- **NVDA headwinds:** H200 China sales stalling, Huawei Ascend 910B displacing in Chinese market, custom chip competition from hyperscalers (Google TPU, Amazon Trainium).

## Investor Thesis (unchanged)

- Long-term AI bull. Believes AI Capex cycle through 2026-2027 has real upside.
- Revenue is real, demand is real.
- Main worry: **sentiment-driven panic** (like Korea) pushing prices down short-term regardless of fundamentals.
- Does NOT want to exit positions — wants to stay invested and capture long-term upside.

## Key Risk Identified: Reflexivity / Sentiment Loop

Stock price and sentiment feed each other. Retail panic (like Korea -10%) can cause fundamentally unwarranted drawdowns. NVDA is especially exposed due to massive retail ownership and large options market (delta-hedging amplifies moves).

**Gap risk** is the real concern: stop-losses don't fully protect against overnight headline gaps (ITC ruling, geopolitical event). Options (protective puts) are the cleaner instrument for that — but not pursued this session.

## Stop-Loss Orders Placed in IBKR

| Ticker | Stop | Buffer | Notes |
|--------|------|--------|-------|
| TSM | $350 | -17.5% from $424 | Protects ~70% of unrealized gain; still above $304 avg |
| NVDA | $160 | -17.8% from $193 | Caps further loss; $193 already below prior $195 support |
| GOOG | $300 | -11.8% from $340 | Catastrophic backstop; still above $239 avg |

**Order specs (all three):** STP (stop-market), GTC, RTH only, AllOrNone unchecked, SMART routing, Destination SMART.

## IBKR Setup Notes

- Stop-loss = conditional sell order (STP) with GTC time-in-force
- **RTH only** (not outside RTH): extended hours liquidity too thin for stop-market orders on TSM/NVDA
- AllOrNone = unchecked (want partial fills in a panic, not no fill)
- Adaptive algorithm on main order is fine; SMART routing handles execution

## Position Status at Time of Session

- **TSM:** Biggest winner (+39%), biggest daily loser (-$440 on June 26). Most important to protect.
- **NVDA:** Already underwater (-14% from $224 avg, currently $193). $195 support already broken. Stop at $160 = catastrophic backstop only.
- **GOOG:** Solid gain (+42%). Least volatile of the three. Wide stop appropriate.

## Watch Before Boarding (June 30)

- **TSMC ITC ruling** — if negative before departure, reassess TSM position or buy protective put
- If ruling is neutral/positive, stops are sufficient, go to Hungary with confidence

## Portfolio Defense Summary

Already defensive: 49% in SGOV + BOXX. AI/semi = only 21% of total. Even a 30% panic in all AI names = ~6% total portfolio impact. SGOV absorbs it.

Stops are catastrophic backstops, not panic exits. Long-term thesis intact.
