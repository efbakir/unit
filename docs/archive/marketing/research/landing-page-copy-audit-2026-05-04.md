# Landing page copy audit — 2026-05-04

> Section-by-section audit of `app/(marketing)/page.tsx` against persona, brand voice, product reality, and the existing research base. Drives a focused edit pass before the W3 launch window (May 6–13).
> Resolved: 2026-05-04. Author: Claude (under Efe's direction).

---

## §1. Scope & non-goals

This doc **extends** the existing research, it does not duplicate it. The repo already has a deep marketing base — `aso-keywords.md` (100-keyword strategy), `screenshot-strategy-final.md`, `app-store-copy-variants.md`, `industry-tools-2026-04-29.md`, `viral-patterns-2026-04-29.md`, `anti-patterns.md` — and a locked persona in `PRODUCT.md` §Users. None of that gets re-litigated here.

**In scope (what this doc adds):**

1. Honesty audit of the marketing-page Pro feature claims against shipped code.
2. Persona objection map specific to the *web* landing surface (the existing research is App Store-focused).
3. Web-SEO overlay — how Bucket 1/2 keywords from `aso-keywords.md` show up (or don't) in visible H2/H3 slots of the page.
4. Section-by-section verbatim → finding → recommended replacement audit of `app/(marketing)/page.tsx`.
5. Conversion-blocker shortlist with severity + recommended fix.
6. Competitor landing teardown — what NOT to echo, with verbatim hero/CTA copy from Strong, Liftosaur, Hevy.

**Out of scope:**

- Apple ASO Keywords field (locked in `aso-keywords.md`, requires App Store Connect review cycle).
- App Store screenshot redesign (locked in `screenshot-strategy-final.md`).
- Content/social playbook (Reddit, TikTok, X — separate workstream per `12-week-calendar.md`).
- A/B testing infrastructure (no traffic at zero install volume; revisit at W6 per `screenshot-strategy-final.md` §A/B test plan).
- Major page restructure / new sections — only the smallest edit set that addresses the audit findings.

**Citation discipline:** every finding cites a source — research doc (path:section), code file (path:line), `PRODUCT.md`/`CLAUDE.md`/decision-log, or verbatim WebFetch quote with date. No "I think" claims.

---

## §2. Honesty audit — Pro feature claims

The current page makes Pro feature claims in three places: the Pro section ([page.tsx:312-340](../../../app/(marketing)/page.tsx)), the `secondaryFeatures` grid ([page.tsx:89-96](../../../app/(marketing)/page.tsx)), and the FAQ ([page.tsx:48-51](../../../app/(marketing)/page.tsx)).

**Source-of-truth for what actually ships:** [PaywallView.swift:60-61](../../../Unit/Features/Subscription/PaywallView.swift) lists the paid feature set as exactly two entries: "Custom template accent colors" and "Founding supporter badge". The paywall itself is gated off in `ContentView.swift` per the [decision-log 2026-04-28 entry](../../decision-log.md) — **free everything at launch**. Pro flips on at W5+ if and only if retention targets are met.

**Verification greps run 2026-05-04:**
- `grep -RIn "HealthKit\|WCSession\|HKQuantity\|HKWorkout" Unit/` → **0 hits**
- `grep -RIn "export.*csv\|exportCSV\|Markdown\|exportMarkdown" Unit/` → **0 hits**
- `grep -RIn "setAlternateIconName\|alternateIcon" Unit/` → **0 hits** (the `AppIcon` enum in `DesignSystem.swift` is the SF Symbol icon set, not iOS alternate-icon assets)

### Claim-by-claim table

| Where | Claim (verbatim) | Ships today? | Action | Why |
|---|---|---|---|---|
| Pro module 1 (`page.tsx:100-103`) | "CSV & Markdown export." / "Every set, every session — yours. No lock-in, no portability tax." | ❌ No implementation | **REMOVE** | Calm-expert-honest voice doesn't ship vapor. Ship in v1.1 if/when implementation lands. |
| Pro module 2 (`page.tsx:104-108`) | "Sync workouts back to Health." / "Two-way sync for workouts, weight, and energy. On your terms." | ❌ Zero `HealthKit` references | **REMOVE** | Same. |
| Pro module 3 (`page.tsx:109-113`) | "Custom home-screen icons." / "Tonal, mono, off-black — pick the icon that disappears into your screen." | ❌ No `setAlternateIconName` | **REMOVE** | Same. |
| Pro module 4 (`page.tsx:114-118`) | "$29.99/year, locked in." / "Founding members keep launch pricing for life. 7-day free trial." | ⚠️ Pricing is in StoreKit but paywall is gated off; "founding member" badge ships but isn't sold | **REMOVE** | Per [decision-log 2026-04-28](../../decision-log.md), launch ships free. No paywall = no "founding member" purchase to lock in. Restore when paywall flips on. |
| Pro section heading (`page.tsx:319-326`) | "Unit Pro" / "Go further when you're ready." / "Core logging stays free forever. Pro is for the bits that matter once your data is worth something — exports, sync, and a touch of home-screen vanity." | N/A — frames the unshipped features | **REMOVE entire section** | Without the four modules below, the section has no content to frame. |
| Secondary features (`page.tsx:91`) | "Apple Health sync" / "Workouts and PRs flow to Health when you want them there." | ❌ Same as Pro module 2 | **REMOVE** | |
| Secondary features (`page.tsx:92`) | "Markdown export" / "Every session, every set — yours to take anywhere." | ❌ Same as Pro module 1 | **REMOVE** | |
| Secondary features (`page.tsx:95`) | "Custom app icons" / "Pick the icon that matches your home screen." | ❌ Same as Pro module 3 | **REMOVE** | |
| FAQ "Is Unit free?" (`page.tsx:48-51`) | "Core logging — sets, ghost values, rest timer, full history, PR detection, all templates — is free forever, with no ads. Unit Pro adds CSV/Markdown export, Apple Health sync, and custom app icons for $4.99/month or $29.99/year, with a 7-day free trial." | First half ships ✓ / Second half: vapor ❌ | **REWRITE** | Rewrite to: "Yes — completely free at launch. No ads, no account, no paywall on any logging feature. I may add a small Pro tier later for power-user extras; if I do, core logging stays free." |
| Footer pricing line (`page.tsx:480-484`) | "Founding members lock in $29.99/year forever." | ⚠️ Conditional on `isLaunched`; gated off pre-launch | **REMOVE** | No paywall to lock into at launch. |
| `metadata.description` (`page.tsx:17-18`) | "Unit is a fast, local-first iOS gym tracker and workout log. Log a set in under 3 seconds — ghost values pre-fill from your last session. No AI, no social, no account." | ✓ All claims ship | **KEEP** | Honest. |
| `softwareLd` JSON-LD (`page.tsx:59-69`) | `"offers": { "@type": "Offer", "price": "0", "priceCurrency": "USD" }` | ✓ Correct | **KEEP** | Already correctly says free. |

### Cross-surface honesty issue (not in scope, but flag)

The same false Pro claims appear in [`docs/marketing/app-store-copy-variants.md`](../app-store-copy-variants.md) — every variant's full description body ends with: *"Unit Pro adds export (CSV, Markdown), Apple Health sync, custom app icons, and custom template colors. $4.99/month or $29.99/year — 7-day free trial included."*

**Action:** out of scope for this audit (App Store copy is a separate surface and submission is on a review cycle), but Efe should review and trim this line before App Store submission to keep cross-surface consistency. Filed as a follow-up — not blocking the W3 web-page rewrite.

### Free-at-launch positioning gain

Removing the Pro section is not just an honesty fix; it's a **positioning win**. Per [`PRODUCT.md` §Anti-references](../../../PRODUCT.md), Unit must not look like "generic fitness SaaS" with "pricing tiers up front". Removing the Pro upsell removes a category-conformist surface. Strong leads with "Strong Accounts are Free Forever" then upsells; Liftosaur leads with "most powerful tracker"; both have a Pro upsell visible on landing. Unit can credibly differentiate by not having one at launch — the smallest, calmest, most honest thing it could do. The Pro upsell returns at W5+ as a v1.1 page-edit task with real claims to make.

---

## §3. Persona objection map (web landing surface)

The locked persona ([`PRODUCT.md` §Users](../../../PRODUCT.md)): *"Intermediate-to-advanced lifter (1–10+ years training) who already knows their program… currently logs in a Notes app or paper notebook, has abandoned at least one 'smart' tracker for being too slow, too rigid, or too noisy."*

A skeptical version of this persona walks onto the landing page with the following objections. For each: where the page currently answers it, and what to add/sharpen.

### O1. "I have months/years of history in Notes/paper. I'm not re-entering it."

| Currently | Recommended fix |
|---|---|
| Section 4 mentions "Paste from Notes" but reads as program-import (the routine), not history-import. The persona reads this and thinks: "OK my routine, but what about my last 6 months of weights?" | Add one line after the "Paste from Notes. Done." subhead that addresses history specifically. Either honestly ("Start fresh. Ghost values catch up to your recent weights inside 1–2 sessions per exercise.") or reframe ("Paste your latest workout — Unit pre-fills from there going forward."). The honest framing is on-brand. |

**Severity:** P1. Real conversion blocker for the 1–10y persona.

### O2. "I just abandoned [Strong/Hevy/Fitbod] for being too slow. Why is this different?"

| Currently | Recommended fix |
|---|---|
| Section 10 ("Not an AI coach", "Not a social platform", "Not for beginners", "Not subscription-locked") is the closest. It answers "what Unit is not" but doesn't directly address the "is this just another smart app?" anxiety. | The current section already does most of the work. Optional: add ONE line at the top of the "What Unit is not" section: "I built Unit because the apps I tried got slower with each release." (First-person, on-brand, calibrates expectation.) |

**Severity:** P2. The "What Unit is not" section already does most of the work; this is a polish.

### O3. "Will the rest timer actually fire when my phone is locked?"

| Currently | Recommended fix |
|---|---|
| Section 6 says "Lives in the Dynamic Island and on the Lock Screen. No need to reopen the app between sets." — strong claim. Verified shipped ([`RestTimerAttributes.swift`](../../../Unit/Features/Today/RestTimerAttributes.swift), `ActivityKit` import in `ActiveWorkoutView.swift`). | Claim is honest and well-placed. **No edit needed.** Consider adding "ActivityKit" or "iOS 16.1+" hint somewhere subtle if the persona is the kind who wants the technical confirmation, but this is optional. |

**Severity:** P3. Already covered well.

### O4. "What if I lose my phone? Where's my data?"

| Currently | Recommended fix |
|---|---|
| Section 9 (Privacy slab): "Local-first. Stays on your phone." / "No account. No sync. No internet. Your full workout history and PRs live on-device, where they belong." Strong, honest, on-brand. **But:** doesn't answer the implicit "what if I lose my phone" question. iCloud Backup covers this for free, but the page doesn't say so. | Add ONE line to the Privacy section: "iCloud Backup covers your data the same way it covers your photos — no Unit account needed." Light, factual, addresses the unasked question. |

**Severity:** P1. This is the #1 unasked question for any local-first app and the easiest addressable trust gap.

### O5. "How is this different from a notebook? Why do I need an app?"

| Currently | Recommended fix |
|---|---|
| Hero answers it: "Faster than paper." Also section 6 (rest timer on Lock Screen — paper can't do this) and section 5 (PR detection — paper can't do this either). | Already answered well. Consider tightening section 5 to lead with the "paper can't do this" angle: change "Every set. Every PR." → "Every set. Every PR. Without the math." (Adds the differentiator vs paper, costs 3 words.) |

**Severity:** P2. Already answered, minor sharpen opportunity.

### O6. "Is this dude going to be around in 6 months? I don't want to commit to abandonware."

| Currently | Recommended fix |
|---|---|
| Section 11 (FounderStory) addresses this implicitly. Footer + privacy section reinforce "your data lives on your phone" — i.e., even if Unit goes away, your history doesn't. | Already partially answered. Consider one line in FAQ: "What if Unit gets discontinued?" → "Your data is on your iPhone. iCloud Backup covers it. Nothing depends on a Unit server. You'd lose the app; you wouldn't lose your history." Honest, on-brand, neutralizes the indie-abandonment concern. |

**Severity:** P1. The "abandonment anxiety" is one of the top reasons advanced lifters reject indie apps — and Unit's local-first architecture is genuinely the answer. Saying it explicitly is a free conversion win.

### Summary of recommended additions

- **O1:** one line after "Paste from Notes. Done." subhead.
- **O2:** one optional line at top of "What Unit is not".
- **O4:** one line in Privacy section about iCloud Backup.
- **O5:** 3-word tweak in section 5 heading.
- **O6:** one new FAQ entry.

**Total copy added:** ~5 small edits, ~50 words. No new sections. No structural change.

---

## §4. Web-SEO overlay (complement to Apple ASO)

The Apple ASO Keywords field is locked in [`aso-keywords.md`](../aso-keywords.md). But the **web** landing page also needs to win Google for the same searcher intent — and the visible H1/H2 hierarchy currently doesn't carry those terms.

### Current keyword density on visible headlines

| Slot | Current copy | Bucket 1/2 keywords carried | Notes |
|---|---|---|---|
| H1 | "Faster than paper." | 0 | Brand voice win, SEO loss. **Locked, do not touch** ([decision-log 2026-03-26](../../decision-log.md)). |
| Hero subhead | "Log a set in one tap…" | "log a set" (B2 #42 "fast set logging" adjacent) | OK. |
| Section 2 H2 | "Built for lifters who already know their program." | 0 | Brand voice. |
| Section 3 H2 | "Ghost values do the typing." | "ghost fill workout" (B2 #34) | OK. |
| Section 4 H2 | "Paste from Notes. Done." | "paste workout from notes" (B2 #31) | Strong. |
| Section 5 H2 | "Every set. Every PR." | 0 directly | Could carry "workout history" or "PR tracker" |
| Section 6 H2 | "Follows you to the Lock Screen." | "rest timer lock screen" (B2 #32) implicit | OK with eyebrow "Rest timer". |
| Section 8 H2 | "Quiet features doing real work." | 0 | Pure voice. |
| Section 9 H2 | "Local-first. Stays on your phone." | "offline gym tracker" (B2 #23), "local gym app" (B2 #24) implicit | OK. |
| FAQ H2 | "Common questions" | 0 | Standard. |
| Footer H2 | "Log faster. Keep your data. Train." | 0 | Brand voice. |

### Bucket 1 keywords currently MISSING from visible copy

From [`aso-keywords.md`](../aso-keywords.md) Bucket 1 (high-intent direct-match):
- ❌ "gym tracker" — never appears in visible H1/H2/H3
- ❌ "workout log" — never appears
- ❌ "lifting log" — never appears
- ❌ "strength log" — never appears
- ❌ "set tracker" / "rep counter" — never appears
- ✓ "workout log" appears in `metadata.description` only

**Trade-off:** the brand voice deliberately avoids category-conformist phrasing (per [`PRODUCT.md` §Anti-references](../../../PRODUCT.md)). Stuffing "gym tracker" into H2s would conflict with that. The recommendation is **moderate**: introduce 1–2 Bucket 1 terms in places where they're a natural fit, NOT a forced graft.

### Recommended SEO additions (low-risk, voice-preserving)

1. **Section 8 eyebrow + intro line:** Currently `"And that's not all"` + `"Quiet features doing real work."` Recommended: keep eyebrow, change intro to `"Quiet features doing real work — the workout log essentials."` (Adds "workout log" once, naturally.)

2. **FAQ schema entry — add new FAQ:** "What kind of workout log app is Unit?" → "Unit is an iOS gym tracker for intermediate-to-advanced lifters who already know their program. It's local-first, ad-free, and built around one principle: log a set in under 3 seconds, one-handed, mid-workout." (Carries "workout log app", "iOS gym tracker", "intermediate-to-advanced lifters" — all keyword-aligned, all honest, no hype.)

3. **`softwareLd` enrichment:** Add `keywords` field to the JSON-LD with a curated subset from Bucket 1+2:
   ```ts
   keywords: "gym tracker, workout log, lifting log, strength log, ghost values, rest timer, local-first, no account"
   ```
   Schema.org doesn't formally weight this for ranking, but it provides Google with explicit category signal at zero brand-voice cost.

4. **`metadata.description` already includes** "fast, local-first iOS gym tracker and workout log" — keep, verified honest.

5. **DO NOT touch:** the H1, the hero subhead, section 2's positioning H2, the privacy H2 — all locked or brand-anchored.

### What NOT to do

- ❌ Add "the best gym tracker" / "the simplest workout log" anywhere — superlatives are explicitly banned ([`PRODUCT.md` §Brand Personality](../../../PRODUCT.md)) and Apple's review team rejects them in keyword fields per [`aso-keywords.md`](../aso-keywords.md) §"Don't ever do".
- ❌ Add "track your workouts" CTA — competitor framing, banned per anti-patterns.
- ❌ Stuff keywords into section eyebrows — they're voice anchors, not SEO real estate.

---

## §5. Section-by-section audit

Walks the page top to bottom. For each section: verbatim → finding → recommended action. Only sections needing a fix appear; sections that are already sharp are noted briefly.

### §5.1 Hero (page.tsx:149-203)

**Verbatim:**
- H1: `Faster than paper.`
- Subhead: `Log a set in one tap. Ghost values pre-fill from your last session. No typing. No menus. Under three seconds.`
- CTA: `<WaitlistForm>` (pre-launch) / `<AppStoreBadge>` (post-launch)
- Caption (waitlist only): `I'll email you once. No spam, no marketing list.`
- Trust band: `<TrustBand count={waitlistCount} />`

**Finding:** strong on brand voice. The subhead is doing all the heavy lifting (sets up the "under 3s" claim, names ghost values, lists the negatives "no typing/no menus"). The CTA caption is honest and on-brand. **Trust band is currently waitlist-count only** — could be enhanced post-launch with App Store rating once available, but pre-launch the count is the right signal.

**Recommended action:** **NO COPY CHANGE.** Hero is locked.

### §5.2 One-line positioning (page.tsx:205-212)

**Verbatim:** `Built for lifters who already know their program.`

**Finding:** sharp, on-persona, on-brand. Repels beginners (good — matches anti-persona in `PRODUCT.md` §Users) and signals expertise.

**Recommended action:** **NO CHANGE.**

### §5.3 Feature slab — Ghost values (page.tsx:214-236)

**Verbatim:**
- Eyebrow: `One tap per set`
- Title: `Ghost values do the typing.`
- Body: `Weight and reps pre-fill from your last session. Tap Done. Move on. The Gym Test: one-handed, sweaty, under three seconds to log a set.`
- microStat: `Avg log: 2.4s`

**Finding:** the strongest slab on the page. Names the differentiator ("ghost values"), grounds it in the test condition ("Gym Test"), and cites a number ("2.4s"). The 2.4s claim is the single most concrete proof point on the page.

**Concern:** "Avg log: 2.4s" has no proof artifact. Where does 2.4s come from? Internal benchmark? TestFlight measurement? If a journalist or skeptical reader asks, the answer must hold. Either:
- (a) Add a tiny footnote/asterisk linking to a brief methodology note ("*measured in internal TestFlight, 12 lifters, n=400 sets, May 2026"). Adds credibility, costs ~10 words.
- (b) Drop the specific number and use "Sub-3s logs" or "Faster than writing it down" if the number can't be defended.

**Recommended action:** keep the slab. Address the 2.4s claim by either backing it (preferred) or softening (fallback). **Severity: P2.** Defer the methodology footnote to post-launch; the number stands for now.

### §5.4 Feature slab — Templates / program import (page.tsx:238-270)

**Verbatim:**
- Eyebrow: `Bring your program`
- Title: `Paste from Notes. Done.`
- Body: `Paste your routine from anywhere and Unit reads exercises, sets, reps, and weights automatically. Or build from scratch in under two minutes.`
- Imports from: `Notes · WhatsApp · paper · CSV · Markdown`

**Finding:** strong title. One issue:

1. ~~"Paper" as an import source~~ — **VERIFIED 2026-05-04: photo-OCR ships** via [`Vision` framework in OnboardingProgramImportView.swift:175](../../../Unit/Features/Onboarding/OnboardingProgramImportView.swift). The "paper" import source and FAQ #3's "take a photo" claim are both honest. No edit needed on this front.
2. **Persona objection O1 unaddressed:** what about my history? See §3.O1 above — add one line.

**Recommended action:**
- **ADD line addressing history** after the body: "Your weights catch up via ghost values inside 1–2 sessions per exercise." (Honest, on-brand.)

**Severity:** P1 (objection: history).

### §5.5 Feature slab — History & PRs (page.tsx:272-290)

**Verbatim:**
- Eyebrow: `History · PRs`
- Title: `Every set. Every PR.`
- Body: `Calendar of every session. Heaviest set, best rep, and best volume PRs detected automatically. You decide when to add weight — Unit just remembers what you did.`

**Finding:** strong. The closing line ("You decide when to add weight — Unit just remembers what you did") directly addresses the anti-AI-coach positioning. This is on-brand discipline.

**Optional sharpen (per §3.O5):** title → `Every set. Every PR. Without the math.` (Adds 3 words, calls out the differentiator vs paper notebook.) **Defer if it costs layout** — the title is short on purpose.

**Recommended action:** **KEEP as-is** unless the layout supports the 3-word add. **Severity: P3.**

### §5.6 Feature slab — Rest timer (page.tsx:292-310)

**Verbatim:**
- Eyebrow: `Rest timer`
- Title: `Follows you to the Lock Screen.`
- Body: `Auto-starts on Done. Lives in the Dynamic Island and on the Lock Screen. No need to reopen the app between sets.`

**Finding:** strong. Verified shipped (`RestTimerAttributes.swift` + `ActivityKit` import in `ActiveWorkoutView.swift`). Title is doing the work — "Follows you to the Lock Screen" is a great verb choice.

**Recommended action:** **NO CHANGE.**

### §5.7 Pro section (page.tsx:312-340)

**Verbatim:**
- Eyebrow: `Unit Pro`
- H2: `Go further when you're ready.`
- Body: `Core logging stays free forever. Pro is for the bits that matter once your data is worth something — exports, sync, and a touch of home-screen vanity.`
- 4 BentoCard modules: CSV/Markdown export, Apple Health sync, custom icons, $29.99/year founding member.

**Finding:** every Pro module promises a feature that doesn't ship. See §2 above for evidence.

**Recommended action:** **DELETE the entire section.** Also delete the `proModules` array (lines 98-119). Free-at-launch is the clean position; Pro returns as a v1.1 page-edit when paywall flips on at W5+ with real claims.

**Severity:** P0. Honesty.

### §5.8 Secondary features grid (page.tsx:342-374)

**Verbatim eyebrow:** `And that's not all`
**Verbatim H2:** `Quiet features doing real work.`
**Verbatim items:**
- Offline · local-first / "No account. No sync. Always works on the gym floor." ✓ ships
- Apple Health sync / "Workouts and PRs flow to Health when you want them there." ❌ doesn't ship
- Markdown export / "Every session, every set — yours to take anywhere." ❌ doesn't ship
- PR detection / "Heaviest set, best rep, best volume. Auto-flagged in history." ✓ ships
- Calendar overview / "Every session at a glance. Streaks without the badges." ✓ ships
- Custom app icons / "Pick the icon that matches your home screen." ❌ doesn't ship

**Finding:** half the grid promises features that don't ship. Same honesty issue as §5.7.

**Recommended action:** **REMOVE 3 entries:** Apple Health sync, Markdown export, Custom app icons. **REPLACE with what does ship:**
- "Lock Screen rest timer" / "Live Activity in the Dynamic Island. Auto-starts on Done." (Verified shipped.)
- "Quick Start" / "Freestyle session, no template required. Tap, lift, log." (Verified shipped per `QuickStartSupport.swift`.)
- "Eight starter programs" / "5/3/1, GZCLP, Upper/Lower, PPL, more — pick one or paste your own." (Verified shipped per `ProgramCatalog.swift` — 8 programs.)

Also rewrite the H2 intro line to carry one Bucket 1 keyword (per §4 above): `"Quiet features doing real work — the workout log essentials."`

**Severity:** P0 (honesty). P2 (SEO add).

### §5.9 Privacy slab (page.tsx:376-388)

**Verbatim:**
- Eyebrow: `Built for privacy`
- H2: `Local-first. Stays on your phone.`
- Body: `No account. No sync. No internet. Your full workout history and PRs live on-device, where they belong.`

**Finding:** strong, on-brand, honest. **But:** doesn't address persona objection O4 ("what if I lose my phone?").

**Recommended action:** add one line at end of body: `iCloud Backup covers your data the same way it covers your photos — no Unit account needed.`

**Severity:** P1.

### §5.10 What Unit is not (page.tsx:390-428)

**Verbatim items:**
- Not an AI coach. / "Unit doesn't tell you what to lift. You bring the program; Unit makes logging instant."
- Not a social platform. / "No feed. No followers. No likes. Training is personal."
- Not for beginners. / "Unit assumes you know your way around a barbell. That's a feature, not a limitation."
- Not subscription-locked. / "Core logging is free. Your workout data is never held hostage."

**Finding:** strong. The "Not subscription-locked" entry now reads even cleaner with the Pro section deleted (no contradiction — the page no longer offers a Pro subscription at all).

**Optional add (per §3.O2):** prepend one line at the top of the section: `"I built Unit because the apps I tried got slower with each release."` Defer if it bloats.

**Recommended action:** **NO CHANGE** (the optional add is P3, defer).

### §5.11 Founder Story (page.tsx:430-435)

Component is `<FounderStory />` from `components/marketing/FounderStory.tsx`. Not audited in detail here — assume the component is on-brand per recent commit `b6c1e8d` ("first-person founder").

**Recommended action:** trust the component. No edit.

### §5.12 FAQ (page.tsx:437-457)

**6 current FAQs.** Edits needed:

| FAQ | Action | Reason |
|---|---|---|
| 1. "How do ghost values work?" | KEEP | Honest, on-brand. |
| 2. "Does Unit work offline?" | KEEP | Honest. |
| 3. "How do I import my program?" | **REWRITE** if photo-OCR doesn't ship | Currently claims "take a photo of your program" — verify; if not shipped, cut that sentence. |
| 4. "What programs does Unit support?" | KEEP | Honest. |
| 5. "Is Unit free?" | **REWRITE** | Per §2: change to "Yes — completely free at launch. No ads, no account, no paywall on any logging feature. I may add a small Pro tier later for power-user extras; if I do, core logging stays free." |
| 6. "When does Unit launch?" | KEEP | Honest, time-bound. |

**ADD NEW FAQs:**

| New FAQ | Why |
|---|---|
| "What kind of workout log app is Unit?" → "Unit is an iOS gym tracker for intermediate-to-advanced lifters who already know their program. It's local-first, ad-free, and built around one principle: log a set in under 3 seconds, one-handed, mid-workout." | Per §4: SEO carrier with honest content. |
| "What if Unit gets discontinued?" → "Your data lives on your iPhone. iCloud Backup covers it. Nothing depends on a Unit server. You'd lose the app; you wouldn't lose your history." | Per §3.O6: addresses the indie-abandonment anxiety. |

**Final FAQ count:** 7 (after rewriting 2 + adding 2 + removing the unshipped paid claims from #5).

### §5.13 Footer CTA (page.tsx:459-486)

**Verbatim:**
- Eyebrow: `Ready when you are`
- H2: `Log faster. Keep your data. Train.`
- Body: `One tap per set. Everything stays on your phone. The notebook, upgraded.`
- Conditional pricing line: `Founding members lock in $29.99/year forever.`

**Finding:** strong emotional close. The pricing line at the bottom must go (no Pro at launch).

**Recommended action:** **DELETE the conditional pricing line** (lines 480-484). Optionally reframe the body to lead with "free at launch" — but the current body is on-brand and works without modification.

---

## §6. Conversion-blocker shortlist

The page is generally well-built. The blockers below are the highest-leverage items for the W3 launch window.

### B1. Pre-launch hero CTA is waitlist-only — no demo evidence visible

**Current:** waitlist email form + "I'll email you once. No spam, no marketing list." caption + trust-band count.

**Issue:** the persona's #1 unstated question on landing is *"can I see this thing?"* The page has **no above-fold demo** — no GIF of a set being logged, no video, no static "before/after" comparison. The 2.4s claim in section 3 is the page's strongest proof point but it's 1+ scrolls down.

**Severity:** P1.

**Recommended fix (minimum viable):** Add a small caption/microcopy under the CTA: `"60-second demo on the right →"` (or similar) pointing at the LayeredDeviceStack already there. This adds zero new assets but redirects attention to the strongest visual on the page.

**Recommended fix (ambitious):** swap the foreground iPhone in `LayeredDeviceStack` to a `<video autoplay loop muted playsInline>` of an actual logged set. This is a bigger lift (asset capture + Next.js video integration + accessibility considerations) and may not fit the W3 window. **Defer to post-launch unless the screen recording already exists.**

### B2. The 2.4s claim has no proof artifact

See §5.3. **Severity:** P2. Defer methodology footnote to post-launch.

### B3. Trust band is one number (waitlist count)

**Current:** `<TrustBand count={waitlistCount} />` — pre-launch shows the waitlist count only.

**Issue:** for the locked persona (skeptical, abandoned-1-app), "N people on waitlist" is weak. Stronger pre-launch signals: founder name + "indie / solo project" framing (already in `<FounderStory />` further down), App Store badge once live (already conditionalized), TestFlight participants if applicable.

**Severity:** P2.

**Recommended fix:** post-launch, swap waitlist count for App Store rating + review count once meaningful. Pre-launch, leave the waitlist count and let the FounderStory section (further down) do the trust work. **No edit needed for W3 launch.**

### B4. FAQ ordering buries the strongest objection-resolver

**Current order:** 1. Ghost values, 2. Offline, 3. Import, 4. Programs supported, 5. Free?, 6. Launch date.

**Issue:** "Is Unit free?" (post-rewrite) is now the strongest trust-builder on the page (free at launch, no paywall on logging). Burying it at #5 is a missed opportunity. Same for the new "Discontinued?" FAQ — that's a high-anxiety question for the persona.

**Severity:** P2.

**Recommended fix:** reorder FAQ to: 1. What kind of app is Unit (new SEO FAQ), 2. Is Unit free, 3. How do ghost values work, 4. Does Unit work offline, 5. How do I import my program, 6. What if Unit gets discontinued (new), 7. When does Unit launch. Brings the trust-builders earlier.

### B5. Footer CTA is identical to Hero CTA

**Current:** both ends of the page use the same `<WaitlistForm>` / `<AppStoreBadge>` block.

**Issue:** the footer is the second-strongest conversion surface. Identical CTAs is a missed differentiation opportunity. A scroll-to-bottom reader is more committed than a hero-bouncer; the footer copy can address a different psychological state ("they read the whole thing — what's the smallest commitment they can make right now?").

**Severity:** P3.

**Recommended fix:** post-launch, A/B test footer CTA microcopy ("Notify me at launch — I'll email you once" vs the hero's "I'll email you once. No spam"). For W3, leave as-is.

### B6. No "what does the app look like" hub link

**Current:** the page has device frames in multiple sections, but no single "see all 5 screenshots" hub. Once App Store launches, the App Store listing IS the hub — but pre-launch, there's nothing.

**Severity:** P3. **No fix for W3** — the App Store listing solves this post-launch.

### Summary of conversion-blocker fixes for W3 window

- **B1 minimum-viable:** add caption pointing to demo stack. ~3 words. **Recommended for W3.**
- **B4:** reorder FAQ. **Recommended for W3** (low-effort, high-impact).
- **B2, B3, B5, B6:** defer to post-launch.

---

## §7. Competitor landing teardown — what NOT to echo

Per [`PRODUCT.md` §Anti-references](../../../PRODUCT.md), Unit must not look or feel like Strong, Hevy, Jefit (spreadsheet-dense, prescriptive, dashboard-aesthetic) or generic fitness SaaS ("transform your training", stock photos, three-icon feature grids). This section captures verbatim hero / CTA / feature copy from the closest comparables so audit recommendations can flag where Unit's current copy drifts toward them.

WebFetch run 2026-05-04.

### §7.1 Strong (strong.app)

**Hero headline:** `Think less. Lift more.`
**Hero subhead:** `Strong is the simplest, most intuitive workout tracking experience. Trusted by over 5 million users worldwide.`
**Primary CTAs:** `Get Started with Strong` / `Download on App Store` / `Get it on Google Play`
**Trust band:** 5M+ users, 10M+ training hours, 15M+ workouts, 4.9★ × 125K reviews (App Store), 4.9★ × 27K reviews (Play). Featured in: The Verge, Lifehacker, The Guardian, Muscle & Fitness, Women's Health, CNET, CNBC, Apple.
**First 3 feature headings:**
1. `Workout. Notebook. Reinvented.` — "Strong is simpler and more powerful than a notebook, and designed to stay out of your way. Plan your training and track your progress."
2. `Take Control of Your Training` — "Visualize your progress with Strong PRO. Keep track of your best sets, max 1RM, body fat percentage, and more."
3. `Your Training. Any Device.` — "Strong is available on iPhone, Android, and Apple Watch. Access your training from any device and never miss a workout."

**Pricing language:** `Strong Accounts are Free Forever`
**Tone words:** simplest, most intuitive, powerful, user-friendly, superclean, rock solid, quick, easy, full-featured, trusted, intuitive and clean.

#### What Unit must NOT echo

| Strong does | Unit must NOT echo because |
|---|---|
| Superlatives ("simplest", "most intuitive") | Banned per [`PRODUCT.md` §Brand Personality](../../../PRODUCT.md): "no marketing superlatives". |
| Motivational hero ("Think less. Lift more.") | Adjacent to "crush your goals" — banned per anti-patterns. |
| Cross-platform claim ("iPhone, Android, Apple Watch") | Unit is iPhone-only, intentionally. Don't apologize for it; don't even raise it. |
| Numeric flex ("5 million users") | Unit doesn't have it and faking it is dishonest. The waitlist count + founder voice is the calibrated alternative. |
| **"Workout. Notebook. Reinvented."** ⚠️ | Direct overlap with Unit's "Your gym notebook, upgraded." Strong **owns** the notebook-metaphor real estate at scale. Unit's differentiation isn't the metaphor — it's the **speed claim** ("Faster than paper" ≠ "Notebook reinvented"). The H1 is fine; the App Store subtitle "Your gym notebook, upgraded." is more vulnerable to Strong's brand gravity. **Action:** flag for the App Store copy review (out of scope here, but log it). |
| Pro upsell visible on landing (`Strong PRO` named in feature 2) | Unit's free-at-launch position is a category-differentiator. Don't restore the Pro section until it has real claims. |

#### What Unit IS doing better

- Voice: first-person founder vs Strong's corporate "Strong is the simplest" framing.
- Honesty: Unit's "Not for beginners" is a category-rare filter; Strong tries to be for everyone.
- Pricing: Unit's free-at-launch is cleaner than Strong's free-with-Pro-upsell.

### §7.2 Liftosaur (liftosaur.com)

**Hero headline:** `The most powerful weightlifting planner and tracker app`
**Hero subhead:** `It's like having Google Sheets and Strong in the same app! Create custom programs or choose proven ones like GZCL or 5/3/1, trusted by thousands of lifters to get bigger and stronger.`
**Primary CTAs:** `Download on the App Store` / `Get it on Google Play` / `or use as a web app`
**Trust band:** `Unlike anything else` (App Store reviews quote)
**First 3 feature headings:**
1. `Workout Editor` — "Write your weightlifting program in plain text with Liftoscript! Specify exercises by week/day, sets, and progressive overload rules…"
2. `Follow free built-in programs` — "Start with a trusted program. All are built with Liftoscript, making them fully customizable to match your goals and preferences."
3. `Powerful Tracker` — "Log every set and rep, monitor body stats, and visualize your progress with detailed graphs. All your data is securely stored in the cloud for access anywhere."

**Pricing language:** none above the fold (mentioned in user testimonials only).
**Voice:** corporate hybrid — "All your data is securely stored in the cloud" / "we" implied.
**Tone words:** powerful, customizable, flexible, scriptable, infinitely customizable, free, trusted, unique.

#### What Unit must NOT echo

| Liftosaur does | Unit must NOT echo because |
|---|---|
| Superlative hero ("The most powerful…") | Banned per `PRODUCT.md`. |
| Direct competitor framing ("like Google Sheets and Strong") | Banned per anti-patterns: "no competitor framing ('unlike other apps')". |
| Cloud-first storage flex ("securely stored in the cloud") | Unit's positioning is the **opposite** — local-first is a feature, not a compromise. |
| Scripting language as feature ("Liftoscript", "scriptable", "infinitely customizable") | Unit positions for the lifter who **doesn't want to script** — wants to log and leave. Power-user customization is anti-persona. |

#### Where Unit is competing for the same searcher

Liftosaur owns "weightlifting planner", "5/3/1 tracker", "GZCL tracker" — all Bucket 4 niche-audience keywords from `aso-keywords.md`. Unit can co-exist by serving the SAME audience differently: "I have a 5/3/1 program and just want to log it without writing scripts" → Unit. "I want to design a custom program with progression rules" → Liftosaur. The positioning is complementary, not directly competitive.

### §7.3 Hevy (hevyapp.com)

WebFetch returned a Cloudflare loading state; the page didn't render. Content extraction not possible 2026-05-04. Falling back to [`PRODUCT.md` §Anti-references](../../../PRODUCT.md):

> **Strong / Hevy / Jefit** — spreadsheet-dense layouts, parallel target-vs-actual columns, prescriptive weight targets, busy timer chrome, dashboard-style "today's workout" summaries.

#### What Unit must NOT echo (from anti-references)

- Spreadsheet density — Unit is one row at a time, ghost-filled.
- Target-vs-actual columns — Unit explicitly removed these per [scope.md](../../claude/scope.md) banned-list.
- Prescriptive weight targets — Unit is "history, not instructions" per `PRODUCT.md` Design Principle 2.
- Dashboard-style "today's workout" — Unit's Today view is a single template card, not a dashboard.

**Action:** retry Hevy WebFetch in a future audit pass when not Cloudflare-blocked. For W3 the anti-references coverage is sufficient.

### §7.4 Cross-competitor pattern: what Unit is uniquely doing

Reviewing the three competitors, Unit's distinct positioning:

1. **First-person founder voice.** Strong, Liftosaur, Hevy all use corporate "we". Unit uses "I" per [`PRODUCT.md`](../../../PRODUCT.md) first-person singular rule. This is the single biggest brand asset on the landing page and should not be diluted.
2. **Free at launch, no upsell visible.** All three competitors show pricing or "Pro" labels above the fold. Unit's clean free-at-launch (after the Pro section is removed) is a category outlier.
3. **Anti-feature framing ("What Unit is not").** None of the competitors do this. It's a brand-voice differentiator the page should keep.
4. **Local-first as positioning, not feature.** Liftosaur leads with cloud storage; Strong is multi-device cloud-sync; Unit is local-first by design. The Privacy section makes this explicit and should stay prominent.

---

## §8. Prioritized fix list

Single source of truth for Phase 2 edits. Grouped by priority; each item references the section above.

### P0 — Honesty (must ship before launch)

| # | Edit | Location | Source |
|---|---|---|---|
| P0.1 | DELETE Pro section block | `page.tsx:312-340` | §2, §5.7 |
| P0.2 | DELETE `proModules` array | `page.tsx:98-119` | §2, §5.7 |
| P0.3 | TRIM `secondaryFeatures`: remove "Apple Health sync", "Markdown export", "Custom app icons" | `page.tsx:89-96` | §2, §5.8 |
| P0.4 | ADD to `secondaryFeatures`: "Lock Screen rest timer", "Quick Start", "Eight starter programs" | `page.tsx:89-96` | §5.8 |
| P0.5 | REWRITE FAQ "Is Unit free?" | `page.tsx:48-51` | §2, §5.12 |
| P0.6 | ~~REWRITE FAQ "How do I import my program?"~~ — **VERIFIED 2026-05-04: photo-OCR ships** via [`Vision` framework in OnboardingProgramImportView.swift:175](../../../Unit/Features/Onboarding/OnboardingProgramImportView.swift). NO ACTION NEEDED. | n/a | §5.12 |
| P0.7 | DELETE footer pricing line | `page.tsx:480-484` | §2, §5.13 |
| P0.8 | ~~REMOVE "paper" from `importSources`~~ — **VERIFIED 2026-05-04: photo-OCR ships**, so paper is honest. NO ACTION NEEDED. | n/a | §5.4 |

### P1 — Persona objection coverage (high-leverage, small diff)

| # | Edit | Location | Source |
|---|---|---|---|
| P1.1 | ADD line about ghost values catching up to recent weights, after templates body | `page.tsx:244` | §3.O1, §5.4 |
| P1.2 | ADD iCloud Backup line to Privacy section body | `page.tsx:383-386` | §3.O4, §5.9 |
| P1.3 | ADD new FAQ "What if Unit gets discontinued?" | `page.tsx:26-57` (faqs array) | §3.O6, §5.12 |

### P2 — Web-SEO + audit polish (low-risk, voice-preserving)

| # | Edit | Location | Source |
|---|---|---|---|
| P2.1 | ADD new FAQ "What kind of workout log app is Unit?" | `page.tsx:26-57` | §4, §5.12 |
| P2.2 | ADD `keywords` field to `softwareLd` JSON-LD | `page.tsx:59-69` | §4 |
| P2.3 | EXTEND secondary-features H2 intro: add "the workout log essentials" | `page.tsx:356-358` | §4, §5.8 |
| P2.4 | REORDER FAQ: trust-builders earlier (Free, Discontinued) | `page.tsx:26-57` | §6.B4 |
| P2.5 | ADD demo-pointer caption under hero CTA | `page.tsx:125-136` | §6.B1 |

### P3 — Defer (post-launch)

- 2.4s methodology footnote / link (§5.3, §6.B2)
- Trust band: swap waitlist count for App Store rating once meaningful (§6.B3)
- Footer CTA microcopy variant (§6.B5)
- Demo video integration in `LayeredDeviceStack` (§6.B1)
- Cross-surface honesty fix in `app-store-copy-variants.md` (§2)
- Hevy WebFetch retry once not Cloudflare-blocked (§7.3)

---

## §9. Verification protocol (Phase 3)

Run after Phase 2 edits land:

1. **Brand-voice grep:** `grep -RIn "\bwe\b\|\bwe'\|\bour\b\|\b us \b" app/\(marketing\)/page.tsx components/marketing/` — must return zero non-test, non-comment hits ([`PRODUCT.md` §Brand Personality](../../../PRODUCT.md) first-person singular rule).

2. **Honesty grep:** `grep -inE "health|csv|markdown|alternate.*icon|custom.*icon|\\\$[0-9]|founding|pro\\b" app/\(marketing\)/page.tsx` — every hit must correspond to a feature/claim that ships. Expected zero hits for: HealthKit, CSV/Markdown export, custom icons, $4.99/$29.99/$44.99 pricing, "founding member" lock-in.

3. **Dev preview:** start the marketing dev server (check `package.json` for the dev script — likely `pnpm dev` from repo root). Open `http://localhost:3000/` and walk top-to-bottom: hero, feature slabs, secondary features, privacy, "what Unit is not", FAQ, footer CTA. Sanity-check that every visible promise has a code-level proof point.

4. **Cross-check against locked decisions:** open [`docs/decision-log.md`](../../decision-log.md) and confirm no edit contradicts an existing decision (especially 2026-03-26 hero-direction, 2026-04-28 paywall-deferred). If a contradiction exists, append a new decision-log entry per [CLAUDE.md §1.6](../../../CLAUDE.md).

---

## §10. See also

- [`docs/marketing/aso-keywords.md`](../aso-keywords.md) — keyword strategy for the Apple Keywords field; this audit's §4 is the web-side complement.
- [`docs/marketing/app-store-copy-variants.md`](../app-store-copy-variants.md) — Variant 1 positioning. Note: same Pro feature claims appear here and need the same trim before App Store submission (§2 cross-surface note).
- [`docs/marketing/research/screenshot-strategy-final.md`](screenshot-strategy-final.md) — locked App Store screenshot strategy. Screenshot 5 already drops the paywall per the same 2026-04-28 decision; this audit aligns the web page with that.
- [`docs/marketing/anti-patterns.md`](../anti-patterns.md) — what not to do; consulted throughout.
- [`docs/decision-log.md`](../../decision-log.md) — 2026-03-26 hero direction, 2026-04-28 paywall-deferred. Both honored by this audit.
- [`PRODUCT.md` §Users / §Brand Personality / §Anti-references](../../../PRODUCT.md) — persona, voice, what to avoid. The first-person singular rule is non-negotiable.
- [`Unit/Features/Subscription/PaywallView.swift`](../../../Unit/Features/Subscription/PaywallView.swift) — actual shipped paid features (lines 60-61).
- [`docs/claude/scope.md`](../../claude/scope.md) — "Paywall on core logging" banned, "free everything at launch".

---

## §11. Post-launch update plan

This audit is a snapshot. After W3 launch, when real traffic data flows from App Store Connect, AppFigures, and the waitlist conversion funnel, append a §12 "what we now know" appendix with:

- Conversion rate by section (heat-mapped if possible).
- Which FAQ entries get the most click-throughs (signals real objection priority).
- Which Bucket 1/2 keywords actually drive traffic (validates §4 SEO bets).
- Whether removing the Pro section materially affected reader perception of "is this a serious product" — measured indirectly via install conversion of waitlist subscribers.

Schedule: review at W6 alongside the planned A/B test of Variant 1 vs Variant 3 ([`screenshot-strategy-final.md` §A/B test plan](screenshot-strategy-final.md)).
