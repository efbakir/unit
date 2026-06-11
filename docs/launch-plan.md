# Unit — 8-Week Launch Plan (2026-04-19 → 2026-06-14)

## Context

You've built Unit for ~3 months and you're 95% ship-ready — feature-complete, in final polish, days from App Store submission. The product side is handled: positioning is sharp ("log a set in <3s, notebook replacement for intermediate-to-advanced lifters"), scope is disciplined, design system is tight. What's missing is everything *around* the product: you've never run a launch, never priced a product, never done PM, never done marketing beyond recording yourself. You asked for guidance grounded in research and case studies, and for one decisive path you can execute alone.

**This plan exists to take you from "builder" to "launched indie with paying users and a weekly rhythm" in 8 weeks.** Your decisions going in: subscription pricing experiment (your call — see §3 for the research you asked for), ship in 1 week, English-first content.

The meta-rule for 8 weeks: **ship, show up, say no.** Everything else is noise.

---

## 1. Ship First — Week 1 (Apr 19–26)

**Rule: don't touch product code this week except to fix bugs the Gym Test surfaces. No new features. No "one more polish pass." You've audited it 4 times already.**

Three blockers from your own submission checklist, in order:

1. **Domain + support email (PRO-9).** Register `tryunit.app` or `unitapp.io` today — don't agonize for more than 10 minutes. Deploy `app/(marketing)/` to Vercel. Point the `#download` placeholder to your future App Store URL (update after approval). Set up `support@[yourdomain]` and wire it to your inbox.
2. **Screenshots (PRO-6).** Run `capture-app-store-screenshots.sh` on a 6.9" device. Use real data, not lorem ipsum. First screenshot = the hero "<3s set logged" moment. Five screenshots total, one headline each.
3. **Gym Test (PRO-3).** 10 sets in a real gym on a real device, all ≤3s with last-time pre-fill. If it fails, fix only what broke. Do not refactor.

Then: Xcode archive → App Store Connect → submit. Expect 24–72h review. While waiting, do §2–§3.

**By Sun Apr 26: "Waiting for Review."**

---

## 2. Pricing Experiment — Decided, But Researched in Parallel

> **Resolved 2026-04-28.** Pricing for v1 is **$4.99 / $29.99 / $44.99** with $19.99/yr win-back, per `docs/pricing.md` (the authoritative source — see also `docs/product-compass.md` §Decision log). The $9/mo + $49/yr proposal below is preserved as the original aggressive thinking and as a Phase-3 target conditional on Week-8 conversion data; it is **not** what ships at the Week-5 paywall flip. Read the rest of this section as historical reasoning, not the current commitment.

You want a subscription experiment: **$9/mo, $49/yr, $30/yr win-back.** Good instinct to experiment — but the numbers need validation. Here's the known market and a research protocol you'll run this Sunday night.

### Competitor pricing snapshot (App Store, early 2026 — verify live before you ship)


| App           | Monthly | Yearly  | Trial  | Notes                                                      |
| ------------- | ------- | ------- | ------ | ---------------------------------------------------------- |
| **Strong**    | $4.99   | $29.99  | 7-day  | Original lifter tracker; also $29.99 lifetime historically |
| **Hevy**      | ~$6.99  | ~$39.99 | 7-day  | Free tier is generous; Pro adds routines + analytics       |
| **Liftosaur** | ~$4.99  | ~$29.99 | 7-day  | Solo indie; programmable routines                          |
| **Fitbod**    | $12.99  | $79.99  | 7-day  | AI programming — different category, not your comp         |
| **Jefit**     | ~$6.99  | ~$39.99 | Varies | Bloated free tier, aggressive upsell                       |


**Your proposed $9/mo + $49/yr sits at the TOP of the lifter-tool band, below Fitbod's AI premium.** That's positioning-consistent ("Unit is premium-quiet, not cheap-and-cluttered") but aggressive — you need to earn that price with obvious polish on first launch.

### Pricing recommendation (one decisive path)

- **Free forever**: Full core logging — templates, Last time pre-fill, rest timer + Dynamic Island, history, calendar, PRs, haptics, custom exercises. Everything in the MVP Ships list. You promised this in `privacy/page.tsx`; keep the promise — it's your credibility moat.
- **Unit Pro — subscription with 7-day free trial**:
  - **Monthly: $9.99** (round up from $9 — App Store tier is cleaner, and psychological delta is zero)
  - **Yearly: $49.99** (effective $4.17/mo — beats Hevy's yearly, matches Strong)
  - **Win-back offer: $29.99/yr** triggered via Apple promotional offer after (a) trial expiry without conversion, or (b) subscription cancellation. StoreKit 2 supports this natively.
  - **Founding member lock-in**: anyone who subscribes in launch month keeps their rate forever, even on future price rises. Converts early adopters into lifetime evangelists.
- **What Pro unlocks at launch** (this is the honest gap — you need to build enough value to justify $9.99/mo):
  - CSV + Markdown export of all training data
  - Apple Health workout sync (bidirectional)
  - Custom app icons (4-6 variants)
  - Custom template accent colors
  - "Founding supporter" in-app badge
  - **Commitment**: every future v2 feature (Apple Watch companion, ProgressionEngine opt-in, cloud backup) ships inside Pro. No second paywall ever.

### Infrastructure decision: use RevenueCat, not raw StoreKit 2

You have StoreKit 2 wired. Migrate to **RevenueCat** (free up to $2.5k MTR). Why: you explicitly said "experiment." RevenueCat gives you A/B testing on prices, built-in win-back offers, abandoned-cart recovery, charts, and cross-platform portability in ~1 hour of wiring. Trying to build this yourself is how you lose a week you don't have.

### Research protocol — Sunday Apr 26 (90 minutes)

Do this before you turn the paywall on in Week 5. You asked for research; here's how to do it decisively:

1. **Reddit** (30 min): search r/Liftosaur, r/weightroom, r/bodybuilding, r/Fitness, r/Strong for: `"Hevy premium" worth`, `"gym tracker" subscription`, `paying for logging app`, `switched from Strong`. Read 20 threads. You're looking for: what people LOVE paying for, what they resent paying for, the ceiling price they'll tolerate. Take notes.
2. **App Store reviews** (30 min): Hevy, Strong, Liftosaur top reviews + 1-star reviews. Quote the recurring complaints about pricing. Ask: would Unit's free tier close the most common 1-star complaint? (Hint: yes, for Hevy — users hate their aggressive paywall.)
3. **Indie dev writeups** (30 min): search `indie ios app subscription pricing`, `"7 day trial" conversion rate ios`, `"revenuecat" benchmarks 2025`. RevenueCat publishes annual "State of Subscription Apps" — read the fitness category data.

Write a one-page "pricing journal" entry with what you found. If the data contradicts $9.99/$49.99, adjust before you flip the paywall on in Week 5. **Don't change prices without data.**

### Launch sequencing — this matters

- **Weeks 1–4: ship paywall code, but free tier = everything.** Add a subtle "Unit Pro coming soon — founding members get locked-in pricing" banner. Collect emails of interested users.
- **Week 5**: flip the paywall on. Gate the Pro features listed above. Everyone who signed up for "founding member" gets a promo code for $29.99/yr lock-in, no trial required.
- **Weeks 5–8**: measure trial starts, trial → paid conversion, monthly vs yearly mix, churn at D30. Adjust only if data says so.

---

## 3. Launch Sequence — Weeks 2–3 (Apr 27 – May 10)

### Week 2: TestFlight beta (20–50 testers)

Recruit from:

- **Personal network**: gym friends, dev friends (10–15 people)
- **LifeOS Türk audience**: one post — *"3 aydır geliştirdiğim spor uygulamasını test etmek ister misin? Sadece iPhone."* (15–25 people). Secondary, not primary — per your English-first decision.
- **r/weightroom, r/Liftosaur**: humble "solo dev built this, looking for brutal feedback" comment on an existing relevant thread (not a drop). 5–15 people.

**Feedback form (Google Forms, 3 questions)**: Did you log a workout? Was it faster than your previous tracker? What would make you uninstall?

### Week 3: Public launch (target Wed May 6 or Wed May 13)

**Ranked channels, best ROI first:**


| #   | Channel                          | Expected                                              | Effort |
| --- | -------------------------------- | ----------------------------------------------------- | ------ |
| 1   | **r/Liftosaur + r/weightroom**   | Warm — they respect lifter-first tools                | Low    |
| 2   | **English TikTok (gym POV)**     | Your strongest lever; your content is proof           | Medium |
| 3   | **Product Hunt (Tuesday)**       | Decent for indie iOS; real launch surface             | Medium |
| 4   | **Hacker News "Show HN"**        | Hit or miss; worth one shot                           | Low    |
| 5   | **Indie dev Twitter/X**          | Small but high-intent; maker culture loves solo ships | Low    |
| 6   | **r/bodybuilding, r/Fitness**    | Cold — "why not Hevy" skepticism                      | Low    |
| 7   | **r/xxfitness, r/fitness30plus** | Wrong ICP — skip                                      | —      |


### Copy to prep (before launch day)

All anchored to **notebook replacement**:

1. **Universal launch paragraph (90 words)**: *"I'm an intermediate lifter who kept a paper notebook for years because every tracker felt slower than writing. Three months ago I started building Unit — a gym logger designed around one rule: log a set in under 3 seconds, one-handed, sweaty. Last time's weight and reps prefill from your last session so you tap once to confirm. No AI coach. No social feed. No algorithm telling you what to lift. Free core logging — never paywalled. Pro is $9.99/mo or $49.99/yr, 7-day free trial. Built solo. Brutal feedback welcome. [link]"*
2. **60-sec TikTok (gym POV)**: quick cut of writing in a notebook → *"still faster than Strong or Hevy"* → cut to Unit, tap once, haptic confirm, timer overlay shows 2.4s → *"I built the tracker I wanted. Free on App Store."*
3. **Three tweet drafts**: (a) notebook vs app side-by-side photo + one line, (b) 5-tweet build-in-public thread covering the 3 months, (c) pricing philosophy tweet (*"core logging will never be paywalled"*).
4. **Launch email** to every contact who should know (~30 people). One paragraph. Personal.

---

## 4. Content Strategy — English-First, Ongoing from Week 2

**Cadence: 3 posts/week minimum. Non-negotiable. Miss one, don't make two — move on.**

Content pillars (rotate):


| Pillar                 | Example                                                  | Why it works                                     |
| ---------------------- | -------------------------------------------------------- | ------------------------------------------------ |
| **Gym POV logs**       | "POV: logging 5×5 squats in 15 seconds total"            | Shows the product in its native habitat          |
| **Kill-the-incumbent** | "Why I deleted Strong and built my own tracker"          | Controversial = shareable, honest = credible     |
| **Notebook test**      | Paper vs Unit side-by-side timing                        | Your defining claim, visually proven             |
| **Indie build log**    | "I built an iOS app solo in 3 months — here's the stack" | Maker/indie Twitter + YouTube Shorts loves this  |
| **LifeOS crossover**   | "A new tool in my LifeOS" (English version)              | Bridge the Turkish audience into English content |


**The one rule: every video shows the app running in a real gym on a real iPhone. No mockups. No After Effects fakery. This is your unfair advantage over faceless competitors.**

**Platforms, in priority order**:

1. TikTok (30-60s, vertical)
2. Instagram Reels (same edits, cross-post)
3. YouTube Shorts (same edits, cross-post — long tail SEO)
4. Twitter/X (clips + screenshots)

**Stay away from**: paid ads, growth hacks, follow/unfollow, stalking competitor users in comments, AI-generated hooks, fake urgency ("24 hours only!"), thirst-traps, fitness influencer partnerships. Your brand is calm and serious. Match it.

---

## 5. First 100 Installs → First 10 Paying Subscribers (Weeks 4–6)

### Measure only these five (weekly Notion page, 5 min review):

1. Installs (App Store Connect)
2. DAU / WAU
3. Sets logged per active session (goal: >8 = real use)
4. Day-7 retention (goal: >30%)
5. Trial starts + trial → paid conversion (from Week 5 on)

### Feedback channel — pick ONE, commit

**Recommendation: Discord server, "Unit early users".** Discord over Telegram for English-first audience. One channel each: #bugs, #feature-requests, #show-off-your-lifts. Invite everyone who fills the feedback form or emails support. Cap at 100 for first-come intimacy.

### Paywall flip signal (Week 5)

Turn Pro on when: **≥30 users have logged 3+ sessions per week for 2 consecutive weeks.** That's intent-to-keep, which is what converts to paid. If you're under 100 installs by end of Week 6, the problem is distribution, not pricing — double content cadence, don't discount.

---

## 6. Solo PM Rhythm — Weeks 4+

**Weekly 30-min review (Sunday evening).** Three questions only:

1. What did the metrics say this week?
2. What's the single loudest user signal?
3. What am I shipping next week? (At most one thing.)

**The "5-user rule"**: A feature request does not get built until **5 independent users** ask for the same thing. Track in a single markdown file with a count column. Most will never hit 5 — that's the point. Your "v1 does not ship" list stays sacred post-launch.

**Monthly decision log (1 paragraph, last day of month)**: what I shipped, what I killed, what I learned. In 6 months this is gold for a retrospective post or investor conversation (if you ever want one).

---

## 7. Case Studies (study these — they walked your road)

**Strong (Lucas Whittaker, solo → acquired, ~2015)**

- What he nailed: lifter-first UX before anyone else; clean, quiet, opinionated.
- Monetization: $29.99 one-time + optional $4.99/mo log sync. Hybrid that respected buyers.
- Lesson for you: lifter-first + fair pricing is a proven indie playbook. Your positioning walks a paved road.

**Liftosaur (Anton Drukh, solo, ~2020)**

- What he nailed: brutal focus on programmable routines; open-source; organic Reddit growth.
- Monetization: ~$4.99/mo, ~$29.99/yr subscription. Modest but steady.
- Lesson for you: one founder + one subreddit + one niche = profitable indie. Don't try to be everywhere. r/weightroom is your beachhead.

**Hevy (Milo Khan, solo → team, ~2019)**

- What he nailed: launched free with a generous tier; added social + subscription as the userbase grew; used Reddit + TikTok heavily.
- Monetization: currently ~$6.99/mo, ~$39.99/yr. Large free tier, aggressive feature gating.
- Lesson for you: **you don't need the monetization figured out on day one.** Launch free, learn, flip the paywall once retention is proven. This is exactly your Week 1–4 free, Week 5 paywall plan.

---

## 8. What NOT To Do (explicit — scope creep is your #1 risk)

- Don't rebuild onboarding. It ships.
- Don't widen the ICP to "everyone who wants to get in shape." It kills your positioning.
- Don't add social / AI coach / ProgressionEngine to "look competitive." Your compass is your moat.
- Don't buy ads. Not this year.
- Don't build Android, Apple Watch, iPad, or Mac until 1,000+ active iPhone users.
- Don't hire, don't co-found, don't take investment. A $49.99/yr app with a solo dev is a beautiful business.
- Don't ship on Black Friday, a holiday week, or a Friday. Ship a boring Wednesday.
- Don't change prices without data. Don't add a feature without the 5-user rule.
- Don't go silent on your Discord / feedback channel. 1 reply/day minimum for the first 60 days.

---

## 9. Verification Milestones


| By                  | Signal                                                                                                                 |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Week 1 (Apr 26)** | App Store "Waiting for Review". Domain live. Pricing research journal written.                                         |
| **Week 2 (May 3)**  | 20+ TestFlight testers logging real workouts. Launch copy drafted.                                                     |
| **Week 3 (May 10)** | App LIVE. 20+ installs from personal network + Reddit + TikTok. Discord server open.                                   |
| **Week 4 (May 17)** | 50+ installs. 3 TikToks published. First feedback themes emerging.                                                     |
| **Week 5 (May 24)** | Paywall flipped on. Founding-member promo sent. First trial starts logged.                                             |
| **Week 6 (May 31)** | 100+ installs. 10+ users logging 3x/week. First trial → paid conversion OR clear "not enough users yet" signal.        |
| **Week 8 (Jun 14)** | First 10 paying subscribers OR a behavior-driven decision on what to change (distribution, Pro feature set, or price). |


If Week 8 shows zero conversions, the answer is not "lower the price." It's either (a) not enough users (distribution problem — double down on content) or (b) Pro isn't compelling (product problem — ship one more Pro feature, not a discount). The five metrics in §5 tell you which.

---

## Critical Artifacts To Reference / Update

**In repo (no code changes needed for this plan — this is strategy):**

- [docs/product-compass.md](docs/product-compass.md) — positioning source of truth (anchor copy here)
- [docs/goals.md](docs/goals.md) — v1 Ships / Does-not-ship list (keep sacred)
- [app/(marketing)/page.tsx](app/(marketing)/page.tsx) — ~~update `#download` to real App Store URL post-approval~~ **Done 2026-06-11**: `NEXT_PUBLIC_APP_STORE_URL` set in Vercel + `.env.example`; badges link to the live listing
- [app/(marketing)/privacy/page.tsx](app/(marketing)/privacy/page.tsx) — update `[pending-domain]` email
- [Unit/Features/Subscription/PaywallView.swift](Unit/Features/Subscription/PaywallView.swift) — flip to subscription products (monthly + yearly) when RevenueCat wired in Week 5
- `capture-app-store-screenshots.sh` — run Week 1

**New artifacts to create (live outside repo, by design — they'd bloat a code repo):**

- Notion page: "Unit metrics" (5 metrics, weekly)
- Notion page: "Pricing journal" (Week 1 research)
- Notion page: "Feature requests" (with 5-user count column)
- Discord server: "Unit early users"
- Google Form: 3-question beta feedback

---

## The 80/20

If you read nothing else: **submit in Week 1, ship free with a "Pro coming soon" banner, post 3 gym POV TikToks per week, open a Discord, flip the $9.99/$49.99 paywall in Week 5 with a 7-day trial and $29.99/yr win-back, run RevenueCat, keep the free tier sacred.** Everything else is detail.

---

## See also

The strategic timeline above (WHEN) is paired with operational scaffolding (HOW) in [`docs/marketing/`](marketing/):

- [`docs/marketing/README.md`](marketing/README.md) — folder index
- [`docs/marketing/tools.md`](marketing/tools.md) — the ~$60/mo (~$43/mo annual) stack (Buffer, Submagic, AppFigures, ElevenLabs; CapCut Free; Opus Clip dropped per the 2026-05-02 overlap audit)
- [`docs/marketing/reddit.md`](marketing/reddit.md) — Reddit BIP playbook with frequency caps
- [`docs/marketing/tiktok-ig.md`](marketing/tiktok-ig.md) — 5 TikTok/IG formats ranked by conversion
- [`docs/marketing/content-engine.md`](marketing/content-engine.md) — monthly recording workflow (3 sources: DIY + UGC + ElevenLabs voiceover over screen recordings)
- [`docs/marketing/ugc-brief.md`](marketing/ugc-brief.md) — Billo/Insense casting brief (real lifters, not models)
- [`docs/marketing/cadence.md`](marketing/cadence.md) — weekly rhythm + Sunday checklist
- [`docs/marketing/automation-map.md`](marketing/automation-map.md) — what's scheduled vs manual, with rationale
- [`docs/marketing/anti-patterns.md`](marketing/anti-patterns.md) — codified won't-do list
- [`docs/marketing/templates/`](marketing/templates/) — drafted starter posts for Reddit, TikTok/IG, X
- [`docs/marketing/research/`](marketing/research/) — dated agent reports (2026-04-29)

When playbooks in `docs/marketing/` conflict with this file, **this file wins.** Update launch-plan.md first, cascade to `docs/marketing/` second.