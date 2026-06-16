# Indie iOS marketing tool stack — research note (2026-04-29)

> Source: general-purpose research agent commissioned during marketing-infra planning chat 2026-04-29. Agent's knowledge cutoff is January 2026; tools/prices drift quarterly — verify current tiers before subscribing.
> Confidence: high on patterns, medium on exact pricing, low on platform-specific shadowban triggers (which shift monthly).

---

## Caveat up front

The agent did not have live web access during this research. Findings are synthesized from training data through January 2026 with explicit confidence flags where knowledge is thin or stale. Prices and exact features drift quarterly — verify on each tool's site before subscribing.

---

## 1. Social media scheduling

| Tool | What it does | Price | Indie-friendly (1-5) | Notes |
|---|---|---|---|---|
| **Buffer** | Multi-platform scheduler, clean UI | Free 3 channels / $6/ch/mo Essentials | 5 | Default for solo founders. AI assistant decent. No TikTok video upload via API on free. |
| **Postiz** | Open-source Buffer clone, self-host or cloud | Free self-host / $29/mo cloud | 4 | Took off mid-2025 on r/selfhosted. Self-hosting is real work; cloud tier removes the appeal. |
| **Hypefury** | X/Threads scheduler with auto-retweet, auto-DM | $19-$49/mo | 3 | Heavy X focus. Overkill if you hate social. |
| **Publer** | Cheap multi-platform | $4-$10/mo | 4 | Threads + Bluesky support is good. Honest underdog. |
| **Metricool** | Scheduling + analytics in one | Free / $22/mo | 4 | Strong analytics. Heavier UI. |
| **OneUp** | Recurring posts, Google Business Profile | $12/mo | 3 | Niche; not relevant for B2C iOS. |
| **Later** | IG-first, link-in-bio | $25-$45/mo | 2 | Pricier. Skip unless you go heavy on IG. |
| **Make.com / Zapier** | Glue between APIs | Free-$30/mo | 4 | Useful as backbone (RevenueCat → Discord → Buffer). Not a scheduler itself. |

**Buffer vs Postiz for 30 min/week**: Buffer. Postiz is interesting if you'd self-host anyway, but the cloud price ($29) is *more* than Buffer's $6 Essentials and you lose the polish. The "I hate marketing, want it to just work" answer is Buffer free tier → upgrade to Essentials when you add a 4th channel.

Named indie: Pieter Levels uses essentially nothing — manual posting on X. Marc Lou (ShipFast) uses Buffer. Tony Dinh (TypingMind) batches via Buffer + Hypefury for X.

---

## 2. AI video / Reels / Shorts (without getting flagged)

The honest answer first: TikTok and IG started actively down-ranking obvious AI-generated content in 2024-2025. Pure AI-avatar tools (HeyGen, Synthesia full-avatar reads) hit the algorithm wall hard, especially in fitness — the most saturated category on TikTok. The tools that *don't* get flagged are the ones where a human does the recording and AI does the editing.

| Tool | What it does | Price | Indie-friendly | Slop risk |
|---|---|---|---|---|
| **Submagic** | Auto-captions, B-roll, sound FX on real footage | $16-$50/mo | 5 | Low — your face, your voice |
| **Opus Clip** | Long video → shorts with auto-reframe + captions | Free / $19-$59/mo | 5 | Low — repurposes real footage |
| **CapCut** | Mobile/desktop editor, AI auto-captions | Free / $8 Pro | 5 | Low |
| **Captions** | iOS app, AI eye-contact, teleprompter | Free / $10-$25/mo | 5 | Low for editing, medium for AI clone feature |
| **HeyGen** | Full AI avatar, voice clone | $24-$72/mo | 2 | **High** — TikTok actively suppresses |
| **Synthesia** | Corporate AI avatars | $29-$89/mo | 1 | High — and B2B framed |
| **ElevenLabs** | Voice cloning + TTS | Free / $5-$22/mo | 4 | Medium if used as voice-over alone |
| **Veo (Google) / Runway Gen-3** | Generative video | Veo via Gemini Advanced ~$20/mo / Runway $15-$95 | 3 | Medium — okay for B-roll inserts, not whole videos |
| **AutoShorts.ai / Pictory / InVideo** | Fully AI-generated shorts | $20-$80/mo | 1 | **Very high** — slop factories the algorithms target |

**For a fitness/gym app specifically**: the working pattern is record yourself logging a real workout on your phone (screen recording + face cam) → Opus Clip or Submagic for captions and clipping → post natively. Anything pretending a generated avatar is a real person dies in fitness. The niche is too watched, too memed, too aware.

Named indie: Daniel Vassallo, Ben Tossell, Marc Lou — all use real face + Submagic/Opus pattern. No fitness indie I can name with confidence is succeeding on pure AI video.

---

## 3. Reddit for indie iOS

**Subreddit reality 2025-2026**:

- **r/SideProject** — friendliest. Build-in-public + MRR screenshots welcome. Self-promo allowed if it's your project. ~250k members.
- **r/iOSProgramming** — strict on self-promo. "Showcase Saturday" thread is the safe slot. Outside that, posting "look at my app" gets removed.
- **r/SaaS** — works but saturated. MRR posts under $1k get less traction now than 2023.
- **r/microsaas** — smaller, friendlier, ironically better signal.
- **r/EntrepreneurRideAlong** — okay for journey posts, not launch posts.
- **r/apple** — do not. Removed instantly.
- **r/Fitness, r/xxfitness, r/weightroom** — *highly* anti-promo. Lurk for months, contribute as a user, mention the app in a comment when genuinely relevant. Posting the app gets you banned.

**The "I built a walkie-talkie for my kids" format works because**:
1. Personal hook (kids, specific use)
2. Modest ask ("3 strangers are paying")
3. No URL in title, in comments only
4. Real numbers, not hype

**Format that's working**: title is the story not the product, screenshot in body, link in first comment, answer every comment for 6 hours. Frequency: one of these per *month* per subreddit, max. More = pattern detection = shadowban.

**Scheduling Reddit via 3rd-party tools = ban risk.** Reddit's API terms post-2023 lockdown are hostile to schedulers. Buffer/Later technically support it but new accounts using them get filtered. Post manually for the first 6 months.

Confidence: high on the pattern, medium on subreddit-specific rules (they shift).

---

## 4. ASO tools

| Tool | Price | Worth it sub-$5k MRR? |
|---|---|---|
| **AppFigures** | $10-$60/mo | Yes — entry tier is the indie default |
| **Sensor Tower** | $400+/mo | No |
| **MobileAction** | $69+/mo | No until $5k+ |
| **AppTweak** | $69+/mo | No |
| **Asolytics** | $29/mo | Maybe — newer, decent at indie price |
| **Apple Search Ads keyword tool (free)** | Free | Yes — start here |
| **Keyword Tool (.io)** | Free / $69/mo | Free tier fine |

**Sub-$5k MRR answer**: AppFigures cheapest tier ($10-ish) + free Apple Search Ads keyword research. That's it. Sensor Tower-tier spend is throwing money away pre-product-market-fit.

Named indie: Marco Arment (Overcast) used AppFigures historically. Most indie iOS devs talk about AppFigures + manual ASO experiments.

---

## 5. Indie analytics stack

| Tool | What | Price | Indie fit |
|---|---|---|---|
| **RevenueCat** | Subscriptions infra + analytics | Free <$2.5k MTR / 1% after | 5 — non-negotiable |
| **TelemetryDeck** | Privacy-first product analytics | Free <10k signals / $9-$33/mo | 5 — Swift indie favorite |
| **Aptabase** | Open-source analytics | Free / self-host | 4 |
| **PostHog** | Full product analytics | Free <1M events | 4 — overkill at zero users |
| **Mixpanel** | Product analytics | Free <20M events | 3 — heavier, not iOS-native |
| **Amplitude** | Product analytics | Free <50k MTU | 2 — enterprise feel |
| **Apple App Analytics** | Built-in | Free | 5 — always on |

**Lean stack 0-100 paying users**: RevenueCat + TelemetryDeck + Apple App Analytics. Three tools, all free at this scale, all Swift-friendly. Add PostHog later only if you need funnels.

**MRR-screenshot pipeline**: RevenueCat → webhook → Make.com or a tiny Swift cron → screenshot template → manual post. Don't auto-post; the manual step is what makes it work on Reddit. RevenueCat's Charts feature gives you the screenshot directly — that's what 80% of the "MRR-screenshot" Reddit posts you've seen are showing.

---

## 6. Content batching / repurposing

| Tool | Price | Best at |
|---|---|---|
| **Opus Clip** | Free / $19-$59/mo | Long → 30 shorts with virality scoring |
| **Submagic** | $16-$50/mo | Captions + B-roll on existing clips |
| **Riverside** | Free / $15-$24/mo | Record + auto-clip in one tool |
| **Repurpose.io** | $15-$35/mo | Cross-post automation; clunkier |

**For "one 30-min recording → 30 short clips"**: Riverside to record (separate audio/video tracks) → Opus Clip for the 30 cuts → Submagic only if Opus's captions look generic. That's the standard 2025-2026 indie loop.

---

## 7. Claude Code / Anthropic skills for marketing (Jan 2026)

**Honest disclosure**: I don't have the live skill marketplace state. What I can confirm exists in the official + community ecosystem as of my cutoff:

- **Anthropic Skills (official)** — the marketplace is Anthropic-curated agent skills. As of late 2025 the marketing-specific ones are thin; most are dev-focused (code review, refactor, doc generation).
- **Claude Code plugins (community, GitHub)** — search `awesome-claude-code` and `claude-code-plugins`. Marketing-relevant ones with medium confidence:
  - `content-generator` / `content-writer` skills (community) — blog post + social copy
  - `seo-audit` / `aso-audit` (community) — keyword research wrappers
  - `screenshot-to-tweet` patterns (community) — image input → social copy
- **MCP servers relevant here**: GitHub MCP, Filesystem MCP, Browserbase MCP (browser automation), Slack/Discord MCPs for cross-posting.

**Honest answer**: the marketing-skill ecosystem in the official marketplace is immature compared to dev skills. Most indie devs writing this with Claude in 2025-2026 build their own one-off skill (or just prompt directly) rather than installing a community one. **Don't burn a day shopping skills — write a tight prompt.**

---

## 8. Browser automation for hands-off social posting

| Tool | What | Price | Practical for IG/TikTok/Reddit? |
|---|---|---|---|
| **Browserbase** | Headless browser infra | $39+/mo | Backbone, not the agent |
| **Stagehand** | AI browser actions on top of Playwright/Browserbase | OSS + Browserbase costs | Best agent layer 2025 |
| **Skyvern** | Visual browser agent | OSS / hosted | Decent, less polished |
| **Claude-in-Chrome MCP** | Claude controlling local Chrome | Free | Promising, fragile |

**Reality check**: automating IG/TikTok/Reddit posts via headless browsers violates ToS. Accounts get shadowbanned within weeks. Use it for *research* (scraping competitor metrics, ASO competitor screenshots) — not posting. The 30-second/post manual penalty is worth keeping the account alive.

---

## 9. Cold outreach (Apollo, Hunter, Smartlead)

Confirmed: **not relevant for B2C iOS.** These are B2B SaaS tools. The exception is press outreach to journalists (TechCrunch indie corner, MacStories, 9to5Mac) — and for that, manual research + a 3-line email beats any automation. Skip.

---

## Minimum viable stack — $0 MRR, < $100/mo

**Buffer free tier + Submagic ($16) + Opus Clip free + RevenueCat free + TelemetryDeck free + AppFigures cheapest tier ($10) + manual Reddit posting.** Total: ~$26/mo. Add Opus Clip Pro ($19) only when you commit to one 30-min recording per month. Don't pay for ASO platforms, AI avatars, or browser automation until you're past $5k MRR — every dollar above this baseline is solving a problem you don't have yet.

---

## Confidence notes

Prices and exact features drift quarterly — verify current tiers on each tool's site before subscribing. Reddit subreddit rules and TikTok algorithm behavior shift even faster; the patterns above held through late 2025 but treat them as 6-month-shelf-life guidance.

For Unit specifically (post-research conversation 2026-04-29), the resolved stack is:
- Buffer Essentials ($6) — multi-channel from day one
- Submagic Pro ($16)
- Opus Clip Pro ($19) — committed to monthly recording
- AppFigures Insights ($10)
- ElevenLabs Starter ($5, when needed)
- All free analytics (RevenueCat, TelemetryDeck, Apple App Analytics, Apple Search Ads keywords)
- Total tooling: ~$51/mo
- + UGC creator budget ~$67/mo amortized
- All-in cap: ~$120/mo

See `tools.md` for the active stack.
