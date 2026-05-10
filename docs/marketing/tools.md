# Tools

> The minimum stack to run Unit's marketing. Resolved 2026-04-29; revised 2026-05-02 after overlap audit (dropped Opus Clip; corrected Submagic price; clarified CapCut Free is sufficient); revised 2026-05-02 again after UGC budget cut (Q1 paid UGC skipped; Billo demoted from default).
> Total: **~$60/mo monthly billing**, or **~$43/mo on annual billing**. **Q1 paid UGC: $0** (skipped — see UGC ladder). All-in indie-launch cap: **~$60/mo**. Resumes to ~$110-130/mo only if UGC re-activates at Q2 evaluation.

## The stack

| # | Tool | Tier | $/mo monthly | $/mo annual | Set up by | Why |
|---|---|---|---|---|---|---|
| 1 | [Buffer](https://buffer.com) | Essentials | $6 | ~$5 | W1 | Multi-platform scheduler. Essentials covers IG + TikTok + X + Threads. Critical for the ≥24h cross-post stagger that Submagic's direct-publish can't do (and for X / Threads, which Submagic doesn't post to at all). |
| 2 | [Submagic](https://submagic.co) | Pro | $39 | ~$23 (41% annual discount) | W2 | Auto-captions + B-roll + AI Auto Zooms + silence trim + native clip selection on sources up to 5min. Replaces ~70% of what CapCut and Opus Clip did before. |
| 2a | Submagic Magic Clips *(addon, conditional)* | – | +$19 | +$19 | only if needed | Long-video → AI-selected shorts. **Add only if a monthly rant runs >5min raw** (Submagic Pro caps source at 5min). For ≤5min rants, skip — Submagic Pro alone handles clip selection. **Replaces what used to be Opus Clip Pro.** |
| 3 | [AppFigures](https://appfigures.com) | Insights starter | ~$10 | ~$10 | W3 | ASO + competitor monitoring + ranking alerts. Unique capability — no overlap with the rest of the stack. |
| 4 | [CapCut](https://www.capcut.com) | **Free** | $0 | $0 | W1 | Assembly + transitions + timer overlays + split-screen composites + manual timeline cuts. Free covers all of this at 1080p vertical, which is the spec for every TikTok / IG / YT clip. **CapCut Premium is not needed** — its 4K export and premium effects don't apply to vertical Shorts. **Downgrade to Free if currently on Premium.** |
| 5 | [RevenueCat](https://www.revenuecat.com) | Free | $0 | $0 | already wired | Subs analytics + the Charts dashboard you screenshot for Reddit BIPs. |
| 6 | [TelemetryDeck](https://telemetrydeck.com) | Free | $0 | $0 | W2 | Privacy-first Swift-native event analytics. Free <10k signals/mo. |
| 7 | Apple App Analytics | Free | $0 | $0 | already on | Built-in install / retention / source data. |
| 8 | [Apple Search Ads keywords](https://searchads.apple.com) | Free | $0 | $0 | W3 | Free ASO keyword research baseline. Complements AppFigures (search volumes), doesn't replace it (no rank tracking, no competitor monitoring). |
| 9 | [ElevenLabs](https://elevenlabs.io) | Starter | $5 | $5 | already set up | Clone your own voice for voiceover over screen recordings (Source C in `content-engine.md`). Unique — no overlap. |

**Tooling subtotal**:
- Monthly billing: **$60/mo** without Magic Clips, **$79/mo** with.
- Annual billing: **~$43/mo** without Magic Clips, **~$62/mo** with.

Recommended: **annual Submagic + skip Magic Clips + skip Q1 paid UGC**. Lands at **~$43/mo all-in** during the launch ramp. Add Magic Clips only if your real rant footage exceeds the 5-minute Submagic source cap (verify on the May 31 monthly recording session). Add UGC back per the ladder below only after the Q2 evaluation point.

## UGC creator budget — DEFERRED for Q1

**Decision 2026-05-02**: Q1 paid UGC is skipped. The original $200/quarter Billo plan exceeds the indie launch budget at $0 MRR. DIY content (Source A — `content-engine.md`) + ElevenLabs voiceover (Source C) cover ~25 clips/month, sufficient for the W1-W12 launch ramp.

**Q2 evaluation point** (around 2026-08-02): re-activate UGC only if (a) cornerstone-format DIY clips average <5k views post-launch, AND (b) the failure isn't a positioning problem (in which case re-research format/hook before paying for creators).

If/when UGC resumes, the ladder cheapest-first:

| Option | Cost | Authenticity | Notes |
|---|---|---|---|
| **TestFlight real-user clips** | $0 | **Highest** — actual ICP | DM 5-10 W2 beta testers, send the `ugc-brief.md` hooks, offer Pro lifetime as thanks. **Recommended Q2 default.** |
| **Fiverr — hand-picked lifter** | $50-100 / video | High if cast right | [`fiverr.com/gigs/fitness-ugc`](https://www.fiverr.com/gigs/fitness-ugc). Paste `ugc-brief.md` verbatim. Test 1 video before committing to volume. |
| **Collabstr — direct booking** | <$100 / video | Variable, public rates | [`collabstr.com`](https://collabstr.com). Browse free, pick fitness creators with prior real-gym UGC history. |
| **Dans UGC — experimental, brand-voice-flagged** | $9 / video custom (20-min order = $180) or $3-5 / video shared B-roll | ⚠️ **Brand-voice risk** | Their library is reaction-format (surprise, shock, GRWM, lip-sync) which violates `PRODUCT.md` §Brand Personality and `ugc-brief.md` casting filter. **If you trial them anyway**: insist on custom + non-reaction format, paste `ugc-brief.md` verbatim, reject any submission with hype language or bedroom/car shots instead of a real gym. Treat as an experiment, not a content pillar. |
| **Reduced Billo** | $50-100 / quarter (1-2 videos) | High (cast filter holds) | Same `ugc-brief.md` workflow, lower volume. |
| ~~Full Billo~~ | ~~$200 / quarter~~ | High | **Dropped** from default plan — exceeds indie launch budget. Re-evaluate at $1k MRR. |
| ~~Insense / JoinBrands~~ | ~~$200-300 / quarter~~ | High | Same — too expensive at $0 MRR. |

Casting brief: `ugc-brief.md` (currently dormant — preserved for re-activation).

## Account checklist

> ⚠️ Don't commit credentials to this file. List of *which accounts to create*, not where to store secrets.

- [ ] Buffer account
- [ ] Submagic account (Pro tier; annual billing recommended)
- [ ] AppFigures account
- [ ] CapCut — keep on **Free** tier (downgrade if currently on Premium)
- [ ] TelemetryDeck account + token wired into `Unit/Configuration/`
- [x] ElevenLabs account (already set up)
- ~~Billo account~~ — **DEFERRED** (Q1 paid UGC skipped per 2026-05-02 budget decision). Re-evaluate at Q2. If/when reactivating, pick from the UGC ladder above (TestFlight clips → Fiverr → Collabstr before Billo).

Credentials → 1Password. App tokens (TelemetryDeck) → `Unit/Configuration/` private build settings, never committed.

## Skip permanently at this stage

| Tool | Why skip |
|---|---|
| **Opus Clip** | Removed in the 2026-05-02 overlap audit — Submagic Magic Clips addon does the same job inside the same tool. |
| HeyGen, Synthesia, AutoShorts.ai, Pictory, InVideo | Full AI talking heads — research-confirmed shadowban risk in fitness 2025–2026. |
| Hypefury | X-heavy, overkill at $0 MRR. |
| Later | Pricier than Buffer for the same job. |
| Mixpanel, Amplitude | Heavier than indie scale needs. |
| Sensor Tower, MobileAction, AppTweak | $400+/mo ASO platforms — wait for $5k+ MRR. |
| Apollo, Hunter, Smartlead | B2B cold outreach — wrong category for B2C iOS. |
| 3rd-party Reddit schedulers | Ban risk on new accounts. |
| CapCut Premium | Free tier covers every CapCut job in Unit's content workflow (assembly, timer overlays, split-screen, vertical 1080p). Premium's 4K + advanced effects aren't used. |

## Total cost ceiling

**Indie-launch cap (Q1, no paid UGC): ~$60/mo** (or ~$43/mo with annual Submagic + skip Magic Clips).

If UGC resumes Q2+: the cap rises to ~$110-130/mo depending on tier (TestFlight clips = $0, Fiverr trial = +$50/mo, reduced Billo = +$33/mo, full Billo = +$67/mo).

**Cap history**:
- Original cap: $120/mo (based on stale $16 Submagic price; actual is $39 monthly / $23 annual).
- 2026-05-02 audit revised to $130/mo accounting for actual Submagic pricing.
- 2026-05-02 UGC budget cut: indie-launch cap dropped to **~$60/mo** by skipping Q1 paid UGC entirely.

If a tool would push past the active cap, justify the new spend against the 5 metrics in `cadence.md` first. No exceptions for "growth hacks."

## See also

- `cadence.md` — when to use which tool in the weekly rhythm
- `content-engine.md` — Submagic + CapCut workflow (was Submagic + Opus Clip + CapCut before the 2026-05-02 audit)
- `automation-map.md` — what each tool gets used for vs what stays manual
- `anti-patterns.md` — tools deliberately not in this stack and why
