# Anti-patterns

> Codified "won't do" list. When in doubt, this file wins over your gut.
> Cited from `CLAUDE.md` §2 push-back mandate, `docs/launch-plan.md` §4, `PRODUCT.md` brand voice, and the 2026-04-29 industry research.

## Content & creator anti-patterns

| ❌ | Why |
|---|---|
| Using viral people's faces (without paid license) | Right of publicity / likeness law. DMCA + lawsuit risk. |
| Lifting existing TikTok / YouTube clips with text overlay | Copyright. Stitch/Duet are licensed reuse; raw lifts aren't. Account-nuke risk. |
| HeyGen / Synthesia / AutoShorts.ai / Pictory / InVideo — full AI talking head | Shadowbanned in fitness on TikTok/IG in 2025-2026. Most saturated category, most aggressive AI-slop filter. |
| ElevenLabs voice + Pexels stock B-roll combo | Slop signature → shadowban. |
| ElevenLabs voice + AI-generated visuals | Same slop signature. Voice-clone of YOU + REAL screen recording is the only allowed combo (see `elevenlabs-protocol.md`). |
| Casting UGC for demographic-clickbait reasons | "Woman faces get more views" → thirst-trap aesthetic → breaks `PRODUCT.md` brand voice (calm/expert/honest) and `launch-plan.md` §4 anti-thirst-trap rule. Cast for *authentic lifter signal*, not demographic. |
| Engagement bait | "Comment X for the link", "Like + follow for part 2" — tanks reach in 2025-2026. |
| Stock motivational quotes over stock footage | Generic, ignored, slop-flagged. |
| "Day in the life of a solo dev #1238" | Saturated format. Original founder-vlog (specific complaints, not generic "today I built") survives; this format doesn't. |
| Fitness influencer partnerships | `launch-plan.md` §4 ban. Off-brand and expensive. |
| Repurposed viral clips with text overlay | Copyright + slop combo. Triple risk. |

## Reddit anti-patterns

| ❌ | Why |
|---|---|
| Posting to r/Fitness, r/weightroom, r/StrongerByScience, r/Bodybuilding | Instant removal. App self-promo banned. Wiki-contributor path takes 6+ months. |
| URL in title or body | Removes via subreddit filter. Always link in first comment. |
| Same post to multiple subreddits within 24h | Pattern detection → shadowban. Stagger by ≥1 week. |
| 3rd-party Reddit schedulers (Buffer, Postiz, etc.) | New-account filter. Post manually. |
| Going silent in the 6-hour reply window | Kills the post — early replies signal authenticity to the algorithm. Block 6hrs after every BIP post. |
| Build-in-public posts more often than 1/month per subreddit | Pattern detection → shadowban. |
| Pitchy titles ("Introducing Unit", "Just launched my new app") | Dies in r/SideProject and r/microsaas. Story > product. |

## Distribution anti-patterns

| ❌ | Why |
|---|---|
| Buying ads | `launch-plan.md` §8: "Don't buy ads. Not this year." |
| Follow/unfollow growth | Algorithmic filter, no signal value. |
| Comment-stalking competitors' users | Reportable, ToS violation, low yield. |
| Apollo / Hunter / Smartlead cold email | B2B tools, wrong category for B2C iOS. |
| Press wires (PRWeb, PR Newswire, etc.) | 0-ROI for indie iOS B2C. |
| Generic directories (BetaList aside, the long tail) | 0-ROI traffic that doesn't convert. |
| Sensor Tower / MobileAction / AppTweak before $5k MRR | $400+/mo ASO platforms — premature optimization. AppFigures cheap tier is enough. |

## Tooling anti-patterns

| ❌ | Why |
|---|---|
| Stack > $60/mo at indie launch (Q1, no paid UGC) or > $130/mo if UGC reactivates Q2+ | The cap is the cap. Justify any addition against the 5 metrics in `cadence.md`. **Cap history**: $120 (original, based on stale $16 Submagic price) → $130 in the 2026-05-02 overlap audit (actual Submagic $39 monthly / $23 annual) → **$60 at indie launch** in the 2026-05-02 UGC budget cut (Q1 paid UGC skipped). |
| Multi-tool overlap (e.g., Buffer + Hypefury + Later) | Pick one scheduler. Switching costs are time, not money. |
| Building a custom MCP server / dashboard / pipeline before the basics work | The custom-builds list is "NOT day-one." First validate the playbooks. |

## Brand voice anti-patterns (cited from `PRODUCT.md`)

| ❌ | Why |
|---|---|
| Hype copy ("crush your goals", "transform your training") | `PRODUCT.md`: "no motivational copy". |
| Competitor framing ("unlike other apps") | `PRODUCT.md`: "no competitor framing". |
| Marketing superlatives ("the best", "revolutionary") | `PRODUCT.md` voice: "talk to the lifter as a peer". |
| Streak gamification, achievement badges | `PRODUCT.md` anti-references: Strava/NTC/Whoop. |
| "Are you sure?" / confirmation interruption copy | `PRODUCT.md` design principle 3: invisible UI. |

## When you're tempted to violate one

The push-back template (`CLAUDE.md` §2):

> "Before I do this — it conflicts with [rule] in [file:section]. The in-scope way to solve your underlying problem is [Y]. Want me to do Y instead, or is this an explicit override?"

If you (the founder) want to override anyway, do it explicitly and document the exception in `docs/product-compass.md` decision log with the date and the evidence that justified it. **Don't drift silently.**
