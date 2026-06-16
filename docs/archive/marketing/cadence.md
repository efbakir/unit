# Weekly + monthly cadence

> The exact rhythm. ~3.5 hours per week, including a Sunday checklist that takes 30 minutes.

## Daily rhythm

**Nothing.** No daily marketing chore. The whole point of this engine is that scheduled posts handle the surface area while you don't think about it.

Exception: the day of a Reddit post, you block 6 hours after posting time for replies. That's once per week max.

## Weekly rhythm — Sunday evening (30 min)

The Sunday checklist:

- [ ] **Pick 3 clips** from the ~30 monthly clips in your library (mix of formats per `tiktok-ig.md`)
- [ ] **Schedule via Buffer** to TikTok + IG Reels + YouTube Shorts for Mon/Wed/Fri
- [ ] **Cross-post 1 to X** with a different framing (text-first, not video-first)
- [ ] **Schedule the Reddit post for the upcoming week** — pick day (Tue/Wed best), pick subreddit (rotate per `reddit.md` priority list, respecting 1/month/subreddit cap)
- [ ] **Block calendar**: 6 hours after Reddit post time for replies (do not schedule meetings or focus blocks)
- [ ] **Review last week's metrics** (5 min) — see "Weekly metrics review" below
- [ ] **Adjust** if anything stands out (skip a format that flopped, double a format that hit)

That's it. Sunday is set; Mon-Sat the engine runs.

## Weekly metrics review (5 min, Sunday)

Same five product metrics as `launch-plan.md` §5, plus one marketing metric:

1. **Installs** (App Store Connect)
2. **DAU / WAU** (Apple App Analytics)
3. **Sets logged per active session** (TelemetryDeck)
4. **D7 retention** (Apple App Analytics)
5. **Trial starts + conversion** (RevenueCat) — from W5 onward
6. **NEW: Marketing funnel per post** (Buffer analytics + Apple App Analytics referrer):
   - Views, likes, replies per post
   - Profile visits per post
   - App Store taps per post (where measurable)

Log to a Notion page (per `launch-plan.md` §9 "Notion page: Unit metrics") or a single weekly markdown entry — you pick. Keep it brief: 5 numbers + 1 line of "what stood out."

## Monthly rhythm — last Sunday (3 hours)

The recording session per `content-engine.md` Source A:
- **Hour 1**: gym recording (3 exercises × 3 sets, multiple angles, screen-record)
- **Hour 2**: 4 talking-head rants (~5-7 min raw)
- **Hour 3**: ingest in Submagic + CapCut → ~15-20 vertical clips (Magic Clips addon only if any rant exceeded 5min raw — see `tools.md`)

Output goes into the `clips/` library that the weekly Sunday checklist draws from.

## Quarterly rhythm — DEFERRED for Q1

> **Status (2026-05-02): DORMANT.** Q1 paid UGC is skipped per the budget decision in `tools.md`. There is no quarterly rhythm to run during the launch ramp. Reclaim the first-Sunday-of-the-quarter hour for product polish or a metrics-deep-dive.
>
> Re-evaluate at Q2 (~2026-08-02). If reactivated, follow the ladder in `tools.md` UGC section. Steps below are preserved for re-activation.

When reactivated, the UGC brief per `content-engine.md` Source B:
- **Pick a tier** from `tools.md` UGC ladder (TestFlight clips → Fiverr → Collabstr → reduced Billo)
- **Paste the brief** from `ugc-brief.md`
- **Cast** per tier budget
- **Wait** 1-2 weeks for raw footage delivery (or same-day for TestFlight clips)
- **Ingest** through the same Submagic + CapCut pipeline

Output (when reactivated): ~5-15 short pieces per quarter depending on tier.

## Reddit-post day (1 specific weekday per week)

When the schedule calls for a Reddit post that week:

| Time | Action |
|---|---|
| **T-30 min** | Pre-post checklist: title, body, screenshot, link in clipboard |
| **T+0** | Post manually (no schedulers). Drop link in first comment immediately. Pin if subreddit allows. |
| **T+0 to T+1h** | Reply to every comment within ~10 min. The first hour determines breakout. |
| **T+1h to T+6h** | Reply within ~30 min of new comments. Slow down but don't disappear. |
| **T+24h** | Log views, upvotes, comments, profile visits, App Store install spike. Add to weekly metrics. |

## Ad-hoc rhythm — when something surprising happens

If a single post breaks 10x your average:
- **Don't react in real-time** to the spike — let it run
- The next Sunday, analyze: which format, which hook, which platform
- Record more of that format next monthly session
- Don't change everything; one signal is one data point

If a post flops:
- Don't repost
- Don't react
- Note it in the weekly metrics review
- The next Sunday, decide whether to skip that format for 2 weeks

## Holidays / off-weeks

You will skip weeks. Plan for it.

- **Holiday weeks** (Christmas / New Year / national holidays): pre-schedule 2 weeks of evergreen reposts via Buffer in advance. Skip Reddit during holiday weeks (low traffic, post will flop).
- **Travel weeks**: same. Pre-schedule. Don't try to record on the road.
- **Sick weeks**: skip the Sunday checklist entirely. Buffer continues whatever was already scheduled.

The rule: never miss two Sundays in a row. One missed Sunday is fine; two is the start of drift.

## When to skip the whole week

Per the failure criterion in `launch-plan.md` §13:
- 4 weeks with <10 installs and posts averaging <100 views each → **stop posting, run a 1-week analysis sprint, resume only after diagnosis.**

Don't grind through bad signal. Re-research, fix the format, then resume the engine.

## See also

- `content-engine.md` — the recording side of the rhythm
- `automation-map.md` — what's scheduled vs manual at each step
- `reddit.md` — Reddit-post-day specifics
- `tiktok-ig.md` — the 5 formats fed by the engine
- `launch-plan.md` §5 — the product metrics that drive the marketing-funnel decisions
