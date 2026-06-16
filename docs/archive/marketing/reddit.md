# Reddit playbook

> The build-in-public Reddit format, dialed for Unit. Source-of-truth for *how* we post on Reddit; templates live in `templates/reddit/`.

## Core thesis

The format that works for indie iOS B2C in 2025-2026: **vulnerable confession + specific tiny win + real screenshot**. Story > product. Numbers > superlatives. The post sounds like a friend texting you about something weird that happened — not an announcement.

The reader should feel: *"that could be me."* Not: *"this is a launch."*

## Title formula

`I built [oddly specific thing] for [oddly specific reason] and [unexpectedly small win]`

✅ Examples that fit Unit:
- "I built a 3-second gym logger because Hevy felt like a spreadsheet"
- "I quit Strong 4 months ago to write my own gym app — first 12 strangers signed up"
- "I logged my last 200 sets in a paper notebook because every gym app was too slow. So I built one."
- "After 3 months solo, I shipped a gym logger that doesn't tell you what to do"

❌ Examples that die:
- "Introducing Unit — the gym tracker for serious lifters" (pitchy)
- "Just launched my new app" (no story)
- "How I built a $9.99/mo subscription gym app in 90 days" (round-numbered, fake-feeling)
- "Day 12 of building in public 🚀" (slop signal)

The structural test: read the title aloud. If it sounds like a press release, rewrite. If it sounds like something you'd text a friend, ship it.

## Body structure (≤200 words, never more)

1. **Hook** (one line, restates title in different words)
2. **The "why I built this for myself"** paragraph — must mention a moment of irritation with an existing tool. Be specific: "Hevy's set log has 4 taps before the haptic", not "the existing apps are slow."
3. **Tech stack one-liner** — Swift 6, SwiftUI, SwiftData, RevenueCat. iOS devs upvote when they recognize their stack.
4. **The numbers** — always with a screenshot. RevenueCat Charts dashboard cropped to MRR + active subs is the most-replicated artifact. App Store Connect funnel is second. Even at $0 MRR, post the install count or trial-start curve. **Real screenshot, not Photoshop.**
5. **One genuine ask** — "what would you build next?", "is the price too low?", "brutal feedback welcome." Never "please try it 🙏".

**The link does NOT go in the title or body. Link goes in the FIRST COMMENT.** Subreddit filters auto-remove posts with App Store URLs in the body.

## Image rules

- Single image, attached to the post (not as a link in body)
- RevenueCat Charts → screenshot the Overview card (Active Subs / MRR / Revenue stacked vertically)
- Or App Store Connect → Analytics → Sales and Trends (line graph, NOT spreadsheet view)
- Real numbers only. Even tiny numbers. $0 MRR is fine if you frame it: *"Day 1, no installs, here's what the dashboard looks like before any signal."*
- ❌ Notion screenshots, hand-drawn roadmaps, AI-generated illustrations — read as content marketing.

## Subreddit selection

| Subreddit | Subs | Lenience | When to post here |
|---|---|---|---|
| **r/SideProject** | ~600k | High — explicitly allows self-promo if it's your project | Primary. First post goes here. |
| **r/microsaas** | smaller | High — niche, friendly | Secondary. Higher signal/noise than r/SaaS. |
| **r/iOSProgramming** | ~200k | Showcase Saturday only — strict otherwise | iOS-credibility post. Audience is devs not customers. |
| **r/SaaS** | large | Saturated — works but lower yield | Worth one post per launch cycle. |
| **r/EntrepreneurRideAlong** | medium | Journey-friendly | Use for "what I learned" recap posts, not launch posts. |
| **r/iosapps** | smaller | App-friendly | Useful as a 2nd-week post. |
| **r/homegym** | ~250k | Lifter-friendly, less anti-app than r/Fitness | Comment-only for first 6 months; mention app only when asked. |

**Stagger posts ≥1 week apart across subreddits.** Same-day cross-posting = pattern detection = shadowban.

## Hard "do nots" (codified in `anti-patterns.md`)

- ❌ Posting to **r/Fitness, r/weightroom, r/StrongerByScience, r/Bodybuilding** — instant removal + ban risk. Wiki-contributor path takes 6+ months.
- ❌ URL in title or body — link only in first comment.
- ❌ 3rd-party Reddit schedulers (Buffer, Postiz, etc.) — new-account filter.
- ❌ Going silent — 6-hour reply window after every BIP post is mandatory.
- ❌ More than 1 BIP post per subreddit per month — pattern detection.
- ❌ Pitchy titles, round-numbered fake-feeling MRR, AI-generated hero images.

## Frequency cap

**Max 1 build-in-public post per subreddit per month.** Don't risk the shadowban for one extra post.

Quarterly cadence target: ~1 BIP per subreddit per quarter on r/SideProject, r/microsaas, r/iOSProgramming + 1-2 ad-hoc per quarter on r/iosapps, r/EntrepreneurRideAlong = ~4-6 BIP posts per quarter total.

## Post-time discipline

1. **Pre-post checklist** (5 min):
   - Title sounds like a friend texting, not a press release ✓
   - Body ≤200 words, real numbers, real screenshot ✓
   - Link prepared for first comment ✓
   - Cleared 6 hours after posting time for replies ✓
2. **Post-and-pin**: post, immediately add link in first comment, pin if subreddit allows.
3. **6-hour reply window**: respond to every comment within ~10 min, especially the first hour. Reply depth signals authenticity to Reddit's algorithm. Don't disappear.
4. **24-hour post-mortem**: log views, upvotes, comments, profile visits, and any App Store install spike (App Analytics referrer). Add to `cadence.md` weekly metrics.

## Anti-pitfall: when posts die

Common reasons a BIP post flops:
- Title was pitchy ("Introducing X")
- Body was >300 words
- No screenshot
- Numbers felt fake (round, no source visible)
- Posted on a holiday / weekend / Friday afternoon
- Link in body got auto-removed by subreddit filter

**Don't repost.** Wait the cap (1/month/subreddit), revise based on what flopped, try a different subreddit next.

## Timing

Best windows for r/SideProject (per Vynixal r/SideProject analysis):
- **Tuesday / Wednesday morning ET** (8-11am)
- Avoid Sunday evenings (low traffic) and Friday afternoons (weekend dropoff)
- Avoid US holidays

Reddit's algorithm rewards early-window upvotes — first 30 min determines whether a post breaks out. So clear that window.

## First 3 posts to draft

1. **W3 launch post** — `templates/reddit/01-launch-week.md` — "I shipped a 3-second gym logger after 3 months solo"
2. **W4 free-tier post** — `templates/reddit/02-free-tier-philosophy.md` — "I gave away the core of my gym app forever — here's why I'm not worried about money"
3. **W8 recap post** — `templates/reddit/03-8-week-recap.md` — "8 weeks in, my indie gym app makes $X/mo — here's what worked"

All three are starters — fill in real numbers from RevenueCat / App Store Connect before posting.

## See also

- `templates/reddit/` — drafted starter posts
- `cadence.md` — when in the week to post
- `automation-map.md` — why Reddit posting stays manual
- `anti-patterns.md` — the "do nots" in one place
- `research/viral-patterns-2026-04-29.md` — full source research with verified examples
