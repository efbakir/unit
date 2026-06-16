# Gemini Deep Research prompt — App Store screenshot strategy

> Paste-ready prompt for Gemini Deep Research, narrowly scoped so the output is concrete enough to drive Figma decisions for Unit's launch screenshots.
> Created 2026-04-30. Companion to `viral-patterns-2026-04-29.md` §7 (which already covers the high-level conversion math) — this prompt asks Gemini for the layer below: specific patterns, named-app examples, exact dimensions, A/B protocol.

## How to use

1. Open https://gemini.google.com → "Deep Research" mode
2. Copy the entire block below (everything between the `===PROMPT START===` / `===PROMPT END===` markers)
3. Paste into Gemini Deep Research as a single message
4. Let it run (typically 5-15 min for a deep multi-source report)
5. Save the output back to this folder as `gemini-app-store-screenshots-YYYY-MM-DD.md`
6. Cross-reference with my own research note (filed separately) before designing in Figma

---

```
===PROMPT START===

You are doing deep web research for an indie iOS developer launching "Unit," a minimalist gym logger for intermediate-to-advanced lifters. The deliverable is a structured research report on App Store screenshot strategy that the developer will use to design 5 screenshots + a 30-second preview video themselves in Figma.

CONTEXT (do not look these up — use them as constraints):
- App: Unit. Free core gym logging (set logging, ghost values, rest timer, full history, PR detection). Pro $4.99/mo / $29.99/yr / $44.99 lifetime, 7-day trial. iOS-only, iPhone-only, light-mode only, portrait-only, English-first.
- Brand voice: calm, expert, honest. No hype, no motivational copy ("crush your goals" type), no competitor name-shaming, no "the only app that…" superlatives.
- Persona: intermediate-to-advanced lifter (1-10+ years training) who already knows their program, currently uses Notes app or paper notebook because gym apps are too slow. Anti-persona: beginners, social lifters.
- Direct competitors: Hevy, Strong, Liftosaur, Jefit, Fitbod.
- Anti-references (visual): Strava, Nike Training Club, Whoop, Oura, Strong/Hevy spreadsheet-dense layouts, generic fitness SaaS hero photography.
- Launch: Wed 2026-05-13.

REQUEST: produce a 2,500-4,000 word research report on App Store screenshot strategy for indie iOS utility/fitness apps in 2025-2026, with primary sources cited inline (not in a footer-only list). The audience is a solo developer with design literacy but no ASO experience.

OUTPUT FORMAT:
- Markdown with H2 per section, H3 per question
- One-paragraph executive summary at the top
- "Minimum viable screenshot set" prescription at the bottom: exactly what 5 screenshots Unit should ship at launch, what each should claim, in what order, with an exact pattern reference (e.g., "screenshot 1: bold-claim hero with no UI, modeled on [named indie app]'s current listing")
- 2,500-4,000 words total
- Cite every numerical claim with a primary-source URL inline. If you can't find a primary source for a claim, say so explicitly — do NOT fabricate a number.

SECTIONS (cover all six):

## 1. Conversion data (numbers + sources, no hand-waving)

- Current empirical conversion lift from optimized vs default App Store screenshots. Cite Storemaven, SplitMetrics, AppFigures, Adapty, AppRadar, Phiture, or Apple's own Product Page Optimization data 2024-2026.
- Lift from adding a 30-second App Store preview video on top of optimized screenshots. Cite real %, not "up to" claims.
- Above-the-fold behavior: how much of the install decision happens on screenshot 1 alone vs after a swipe? Cite eye-tracking studies, click-behavior data, or App Store Connect funnel data.
- Realistic conversion rate range for a fitness/productivity utility iOS app at <$20k MRR in 2025-2026. Distinguish "browse → product page tap" vs "product page tap → install."

## 2. Visual patterns that convert (utility/fitness, NOT games)

- The "first screenshot is a value claim, not a UI" pattern — when does it hold, when does it fail? Cite specific apps as positive and negative examples.
- Device-frame vs full-bleed: which converts better, under what conditions? Any A/B data?
- Text-overlay-above (caption above device frame) vs text-on-screen (caption inside the UI mockup) — A/B data if any.
- Light mode vs dark mode for the gallery: does Apple's per-device theme setting affect what gets seen? When should an indie ship dual versions?
- Number of screenshots actually viewed (eye-tracking median). Should an indie ship 3, 5, 7, or 10?
- Caption copy length: single phrase vs short sentence vs multiple lines. Word-count thresholds.
- Vertical vs landscape: how does iPad-style landscape's recent rise affect iPhone-only apps?

## 3. Real indie iOS apps with strong listings in 2025-2026

Identify 8-10 indie iOS apps (sub-$20k MRR, solo or two-person teams) that have visibly polished App Store listings AND demonstrably good conversion (cite Sensor Tower estimates, AppFigures public data, or founder interviews where conversion is mentioned). Prioritize:
- Fitness/strength tracking (Liftosaur, Strong's original Lucas Whittaker era, Hevy's pre-acquisition years)
- Indie dev productivity (TypingMind, DevUtils, Xnapper, MacWhisper, Screen Studio)
- Notes/writing (Bear, Drafts, Ulysses)
- Habit/health (Streaks, Things 3, Reflectly early years)

For each app, link to its current App Store listing (or archived screenshots if redesigned), then analyze the EXACT decision: which screenshot pattern, which copy length, which color treatment, what's on screenshot 1 vs 2 vs 3. Avoid generic "they have nice screenshots" — point at the pattern.

Skip: games, social-first apps, dating apps, lifestyle/wellness lifestyle imagery. Those have different conversion mechanics.

## 4. Anti-patterns (what's getting penalized in 2025-2026)

- App Store screenshot patterns being actively down-ranked by App Store search 2024-2026 — if any (Apple's algorithm shifts here).
- Most common indie iOS screenshot mistakes per ASO consultancies' teardowns (Phiture, Yodel Mobile, AppRadar, dabo.dev). Name the consultancy + cite the teardown URL.
- The "App Store gallery as ad" (vibrant bg, heavy text, marketing-style) vs "as documentation" (real UI, restrained text) — which converts and when does the ad-style backfire?
- Anti-references: what fitness app patterns specifically read as "another bloated tracker" to lifters who already churn off Hevy/Strong?
- Whether emoji, gradients, 3D-rendered devices (Rotato-style), or stock-athletic photography help or hurt conversion in 2025-2026 — cite teardowns.

## 5. App Store preview video + Custom Product Pages + A/B testing

### Preview video
- Current Apple specs (length, format, codec, max file size, autoplay behavior in 2025-2026).
- Hook structure that converts (0-3s, 3-20s, 20-30s). Cite real teardowns (Hilo Media, SmoothCapture, SplitMetrics).
- Tools indie iOS devs actually use in 2025-2026 to produce preview videos: Screen Studio, SmoothCapture, Rotato, Final Cut, Submagic, CapCut, Veed, Loom. Free vs paid tradeoffs. Which produces App-Store-quality output and which doesn't.
- Whether to localize the video at indie scale.

### Custom Product Pages (CPPs)
- What CPPs allow that Product Page Optimization (PPO) doesn't.
- When indie should bother with CPPs vs just running the default page.
- Apple's current limits (number of variants, traffic split, eligibility).

### A/B testing
- Minimum impressions and minimum days before reading results at indie-scale traffic (~1k impressions/week).
- What to measure: impression-to-product-page-tap vs product-page-tap-to-install (different optimizations).
- Statistical significance threshold acceptable for indie scale (95% is overkill; 80% may be reasonable — confirm or refute).
- Whether testing screenshot order moves the needle vs testing first-screenshot only.

## 6. Specifications + tools

### Specifications
- Current Apple App Store screenshot dimensions for iPhone 15/16/17 (or whichever device class is the 2025-2026 default). Exact pixel dimensions per device class. Include if Apple has consolidated to one universal size.
- Maximum number of screenshots per device class (currently 10 — confirm).
- File format / max file size / color profile expectations.

### Tools
- Figma plugins or templates that produce iOS App Store screenshots in 2025-2026: Mockup Plugin (by Ed Chao), App Store Screenshots, Previewed for Figma. List with names, free/paid, output quality. Are any of these still maintained as of 2026?
- Standalone tools beyond Figma: Screenshots.pro, Previewed (Mac app), Rotato, AppMockUp, Mockuuups Studio, Smartmockups. Pricing, output quality, indie-friendliness rating.
- Whether AI-generated mockup tools (Galileo, Uizard, v0.dev) produce App-Store-quality output. Confirm with examples; my prior is "no, they're useful for sketches not gallery assets."

HARD CONSTRAINTS:
- Skip games entirely — different conversion mechanics
- Skip generic "you must…" advice from Medium-style listicles
- Prioritize sources from 2024-2026 (Apple changed App Store conversion behavior multiple times in this window — pre-2023 data is stale)
- Cite Apple's own developer documentation (developer.apple.com) where applicable
- Where two sources contradict, present both and flag the contradiction
- Do NOT fabricate numbers, A/B percentages, or quotes. If you can't find a primary source, say so explicitly.

FINAL DELIVERABLE — minimum viable screenshot set for Unit:
End the report with a concrete prescription: exactly 5 screenshots Unit should ship at launch, in order, with for each:
- What it claims (one short sentence)
- What's on screen (UI mockup vs hero claim only)
- Layout pattern (full-bleed / device-frame / split-screen)
- Color and typography treatment that fits a calm-expert-honest brand
- A named-indie-app reference for the same pattern

Make the prescription opinionated, not "here are options." The developer is solo, shipping in 2 weeks, and will design these in Figma based on your output.

===PROMPT END===
```

---

## What this prompt is engineered to do

- **Block generic advice.** The "skip games", "skip 'you must'", "prioritize 2024-2026" constraints prevent the SEO-optimized listicle output that most ASO articles produce.
- **Force named examples.** Section 3 explicitly lists 8-10 named candidate apps and asks for exact-decision analysis. Gemini can't escape with "many top apps use a hero image."
- **Trip on contradictions.** "Where two sources contradict, present both and flag" prevents Gemini from picking one source's number and burying the other.
- **End with a usable artifact.** The "minimum viable screenshot set" prescription means the output drives a Figma decision, not just a knowledge dump.
- **Honest about uncertainty.** "Do NOT fabricate" + "if you can't find a primary source, say so" forces Gemini to flag knowledge gaps instead of papering them over.

## What I will research separately (complementary, not duplicate)

When Gemini's report comes back, I'll add my own research note at `docs/marketing/research/app-store-screenshots-2026-04-30.md` that focuses on what Gemini can't easily do:

- Direct competitor teardown of Hevy / Strong / Liftosaur App Store screenshots specifically (current state, not aggregated)
- Brand-voice-specific recommendations for Unit (Gemini doesn't have your `PRODUCT.md` open)
- Cross-reference Gemini's claims against `viral-patterns-2026-04-29.md` §7 — flag contradictions
- A Figma-ready spec: per-screenshot layout, copy, color tokens, font tokens (mapped to your `DesignSystem.swift`)
- A/B testing protocol calibrated to your launch traffic specifically

We compare both reports in `docs/marketing/research/screenshot-strategy-final.md` and that's what drives the Figma work.

## See also

- `viral-patterns-2026-04-29.md` §7 — existing screenshot research baseline
- `app-store-copy-variants.md` — the 5 first-screenshot tagline candidates per variant
- `app-store-copy.md` — current App Store metadata baseline
- `PRODUCT.md` + `DESIGN.md` + `DesignSystem.swift` — brand and visual constraints Gemini won't have access to
