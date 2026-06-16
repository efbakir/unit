# Automation map

> What's automated, what's manual, why.
> The rule: anything where the platform's algorithm rewards "real human" gets done manually. Everything else gets scheduled.

## The map

| Activity | Mode | Tool | Why |
|---|---|---|---|
| **TikTok / IG Reels / YouTube Shorts scheduling** | Automated | Buffer | Saves the daily ritual. Algorithms don't penalize scheduled posts. |
| **X / Threads scheduling** | Automated | Buffer | Same. |
| **TikTok / IG / YT comment replies** | Manual | n/a | Auto-replies kill algo signal. Real reply within 24h is rewarded. |
| **TikTok / IG / YT DMs** | Manual | n/a | Auto-DMs are spam, often filtered, hurt account health. |
| **Reddit posting** | Manual | n/a | 3rd-party schedulers (even Buffer) trigger new-account filters → shadowban. |
| **Reddit replies (6h after post)** | Manual | n/a | Authenticity. Pattern detection if delegated. |
| **Reddit comments on others' threads** | Manual | n/a | Authenticity. |
| **App Store keyword monitoring** | Automated | AppFigures alerts | Email when ranking moves. No daily check. |
| **RevenueCat metrics → MRR screenshot** | Semi-automated | RevenueCat Charts UI | Already a screenshot in their UI — you copy + paste. No pipeline needed. |
| **Weekly metrics review (5 min)** | Manual | n/a | Decision-making, not data collection. Has to be human. |
| **Monthly content recording** | Manual | Phone + tripod + QuickTime | Only a human can do this. (And the human has to actually train.) |
| **UGC creator brief / cast / receive** | Manual | (varies by tier — see `tools.md` UGC ladder) | **DEFERRED for Q1** per 2026-05-02 budget decision. When reactivated: each quarter, run via TestFlight clips ($0) / Fiverr / Collabstr / reduced Billo. |
| **Submagic auto-captions + Auto Zooms + silence trim** | Automated | Submagic Pro | The whole point of Submagic. |
| **Submagic Magic Clips long → shorts** | Automated | Submagic Magic Clips (addon, conditional) | Replaces Opus Clip per the 2026-05-02 stack audit. Only used when a source rant exceeds 5min raw. |
| **CapCut final assembly** | Manual | CapCut Free | Editorial control on transitions, timer overlays, split-screen composites, B-roll choices. Free tier covers all of this for vertical 1080p. |
| **ElevenLabs voiceover** | Semi-automated | ElevenLabs | Script is manual, voice generation is automated. |
| **Email replies (support@)** | Manual | n/a | Customer trust. Auto-replies kill it. |
| **Discord moderation** (when launched) | Manual | n/a | 1 reply/day minimum for first 60 days per `launch-plan.md` §5. |

---

## The line: automated vs manual

**Automate**:
- Anything the platform algorithm *doesn't penalize* (scheduled video posts on TikTok/IG/YT/X)
- Anything that's pure data fetching (AppFigures alerts, Buffer analytics, RevenueCat Charts)
- Anything purely mechanical (Submagic captions, Magic Clips cutting)

**Don't automate**:
- Reddit anything (posting, replying, even commenting on others' posts) — single biggest ban risk
- Live engagement on TikTok/IG (replies, DMs, comments)
- Customer-facing email
- Decisions (the metrics review is decision-making, not data collection)
- The recording itself

The general principle: **automation that the algorithm can detect → don't.** Automation that's invisible to the platform → fine.

---

## Schedules

Tools that run on schedules:

| Schedule | Action | Tool | Frequency |
|---|---|---|---|
| **Sun 8pm** | Buffer queue check (from your Sunday checklist) | Buffer | Weekly |
| **Mon/Wed/Fri 10am** | Buffer publishes scheduled clips to TikTok + IG + YT | Buffer | 3x/week |
| **Tue or Wed 9am ET** | You manually post Reddit | (manual) | 1x/week |
| **Daily** | AppFigures keyword monitoring | AppFigures | Daily |
| **Weekly (Sun)** | RevenueCat dashboard check | (manual) | Weekly |
| **Monthly (last Sun)** | Recording session | (manual) | Monthly |
| **Quarterly (first Sun)** | UGC brief — **DEFERRED for Q1** (per 2026-05-02 budget decision); reactivate per `tools.md` ladder if Q2 evaluation warrants | (manual) | Dormant during launch |

---

## What about Claude Code scheduled agents?

Per `tools.md`, optional custom builds (NOT day-one):

| Custom build | What | Status |
|---|---|---|
| **Weekly metrics summary agent** | Claude pulls 5 metrics from RevenueCat + App Store Connect + Buffer, writes 1-line summary, drops it into a Notion page or local file. Triggered via `/schedule weekly Sunday`. | Optional. Can build via `claude-api` skill in ~1 day if/when desired. |
| **Buffer MCP server** | Custom MCP that posts to Buffer via API. | **Skip.** Buffer's UI is fine for one user. |
| **RevenueCat → Reddit screenshot pipeline** | Bash script that pulls Charts dashboard, formats it for Reddit aspect ratio (9:16 or 1:1). | Optional. ½ day to build. Worth it once you're posting BIPs monthly. |
| **ASO-recon Claude-in-Chrome scripts** | Browser-driven monthly scrape of Hevy/Strong/Liftosaur App Store screenshots to track A/B tests. | Optional. ~1 day. NOT for posting. |
| **Marketing dashboard SwiftUI view inside Unit** | Opt-in for founders, shows live MRR + install count from RevenueCat as a screenshot you can share. Could be a launch-week post itself. | Optional. ~2 days. |

Build these only after the basics are working. Per `anti-patterns.md`: "Building a custom MCP server / dashboard / pipeline before the basics work."

---

## Hands-off Reddit posting via Claude-in-Chrome MCP

**Possible, not recommended.**

The Claude-in-Chrome MCP server can drive your logged-in Reddit session and submit posts on your behalf. Technically this works.

**Why we don't do it**:
1. Reddit's filter detects browser automation patterns (timing, mouse path consistency, viewport fingerprints). Even with Claude-in-Chrome, repeated automated submissions from a new account get filtered.
2. The 6-hour reply window after each post is the part that actually drives engagement. Automating posting without automating replies is half-measure that breaks the engagement signal anyway.
3. The whole authenticity premise of the "build-in-public" format is that a real founder is actually posting and replying. Automating undermines the core trust transaction.

If you ever consider this: do it for *research-only* tasks (scraping Hevy/Strong screenshots, checking competitor App Store metadata) where Reddit/social ToS don't apply.

---

## See also

- `cadence.md` — the schedules above translated into a weekly checklist
- `tools.md` — what each automated tool costs
- `reddit.md` — why Reddit specifically stays manual
- `anti-patterns.md` — explicit anti-automation rules
