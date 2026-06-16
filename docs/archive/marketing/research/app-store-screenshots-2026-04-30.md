# App Store screenshots — complementary research note (2026-04-30)

> Companion to `gemini-app-store-screenshots-2026-04-30.md`. The Gemini Deep Research report is the broad survey; this note is the audit layer + Unit-specific cross-reference.
> The actual design spec lives in `screenshot-strategy-final.md`.

## TL;DR — what the Gemini report adds, what it gets wrong, what's missing

**Adds (high value)**:
1. **OCR indexing of screenshot captions (June 2025)** — single biggest finding. Caption text is now algorithmic ranking metadata, not just cosmetic. This wasn't in `viral-patterns-2026-04-29.md`.
2. **8 named indie apps with specific decision-level analysis** — Liftosaur, Strength Direct, Iron Log, DevUtils, TypingMind, Streaks, Bear, Habit Pixel. Concrete pattern references.
3. **Apple's exact 2026 specs** — 1290×2796 (iPhone 16/17 Pro Max), JPEG/PNG flat, no transparency, max 10 per device class.
4. **CPP organic-search expansion (July 2025)** — Custom Product Pages now appear in organic search results for targeted keywords. Previously paid-only.

**Gets wrong / disagrees with prior research**:
1. Conversion lift numbers: Gemini says **20-35%** from optimized screenshots; `viral-patterns` cited "up to 40%". Both directional, neither lying — the 40% in viral-patterns was likely the upper-tail "optimized gallery" case study; Gemini's 20-35% is the broader range. Use 25% as planning baseline.
2. Number of screenshots: Gemini recommends **5-6**; `viral-patterns` said the first 3 carry it and 4-5 are "dispensable". Reconcile: ship 5, design with the assumption that screenshots 4-5 are secondary.
3. Background color in the prescription: Gemini suggests "muted slate or sage green" for visual separation. Unit is light-mode only with off-white `#F5F5F5` page background — Gemini doesn't have access to `DesignSystem.swift`. Stick to Unit's actual tokens (see synthesis doc).

**Missing or wrong for Unit specifically**:
1. **Gemini's screenshot 5 (paywall) is wrong for W3 launch.** Per `docs/launch-plan.md` and `docs/product-compass.md` decision 2026-04-28: paywall flips W5+, conditional on retention. At W3, the app ships free-for-everything with a "Pro coming soon" Settings card. Showing a paywall screenshot at launch creates a UX/comms mismatch (user installs expecting paywall → finds it inactive → confused). Replace with something else (see push-back below).
2. Gemini's prescription doesn't reference the **5 first-screenshot tagline candidates already drafted** in `app-store-copy-variants.md`. The synthesis maps those to the 5 screenshots so copy is reused, not regenerated.
3. Gemini doesn't account for Unit's **Variant 1 ("Notebook Replacement") recommended ship** — its prescription leans speed-first ("Log workouts without the wait"), which is closer to Variant 3. Synthesis aligns to Variant 1 since that's the launch-plan.md recommended hero.

---

## Source quality audit (Gemini's report)

Of Gemini's 43 sources, calibrate trust by tier:

| Tier | Sources | Confidence |
|---|---|---|
| **Authoritative** | Apple developer.apple.com (#11, #32) | High — primary source |
| **ASO platforms with own data** | Adapty (#2, #9, #40), AppRadar (#24, #36), AppFigures teardown (#22, #26), Phiture (cited but no URL) | High |
| **Tool vendor blogs** | SmoothCapture (#4, #31), Mockuuups (#42), AppLaunchpad (#41), Muz.li (#43) | Medium — vendor-biased on tool comparisons |
| **Reddit anecdotes** | r/AppStoreOptimization (#3, #5, #10, #25), r/iosapps (#16), r/workout (#13) | Medium — useful but anecdotal; verify before betting on numbers |
| **SEO content posts** | AppScreenshotStudio Medium (#7), Applyra Blog (#1), Setgraph (#28), YourAppLand (#29), Medium individual (#33) | Lower — promotional, often recycled advice |

**Specific claim → source confidence map** (the ones that matter most):

- "OCR indexing started June 2025" → sources #24 (AppRadar), #25 (Reddit PSA), #26 (AppFigures). Two non-Apple sources + one anecdotal Reddit confirmation. **Apple has not officially confirmed** in their developer docs. Treat as **high-confidence-but-not-officially-Apple**. Worth implementing because the cost of optimizing for it is zero (you already write good captions) and the upside if true is real.
- "20-35% conversion lift from optimized gallery" → source #1 (Applyra Blog, promotional). The actual primary-source data backing this is older Storemaven research (~2018-2020 era) re-cited in 2026 posts. **The percentage is directional, not precise.** Use as a planning estimate, not a forecasting tool.
- "+15-25% lift from preview video" → sources #2 (Adapty), #4 (SmoothCapture). Adapty has its own conversion data; SmoothCapture is tool-vendor. Adapty's number is more trustworthy.
- "First 3 screenshots carry the install decision" → sources #1, #6 (Yodel Mobile), #7. The eye-tracking data in viral-patterns-2026 §7 (Storemaven) is the actual primary source. Confident.
- "96% portrait dominance" → source #7 (SEO post). Plausible but not independently verified. Don't quote the exact 96% without checking.
- "8 indie app teardowns" → mix of Apple App Store URLs (#14, #17, #19, #20, #21) and Indie Hackers posts (#23). The App Store URLs are primary; the analysis is Gemini's. **Gemini's specific decision-level reads (e.g., "Strength Direct uses 100pt+ headlines on flat backgrounds") are reasonable but unverified by me without re-pulling the listings**. Spot-check 2-3 of these manually before copying patterns.

**Confidence rule of thumb**: any specific numerical claim in the Gemini report — verify against a primary source before betting on it. Any pattern claim ("hero composition with no UI on screenshot 1") — directionally trust, but treat as a hypothesis to A/B test, not a law.

---

## Cross-reference vs `viral-patterns-2026-04-29.md` §7

| Claim | viral-patterns | Gemini | Reconcile |
|---|---|---|---|
| Visuals = % of install decision | "60-70%" | "first 7 seconds" / first 3 screenshots | Aligned. Both saying the visual gallery is the conversion bottleneck above text. |
| First screenshot pattern | "Single bold value claim, NOT a product UI" | "Value Claim Hero with bold headline + cropped UI proof beneath" | Aligned. Gemini adds "cropped UI proof", which is more specific. |
| Conversion lift from optimized | "Up to 40%" | "20-35%" | Use 25% as planning baseline. Don't quote a specific number to anyone. |
| Preview video lift | "+20-40%" | "+15-25% (up to 35% utility cases)" | Aligned at the lower end. The "up to" claims are tail outcomes. |
| Screenshot count | "3 essentials, 4-5 dispensable" | "Cut from 10 → 5-6, dilution beyond that" | Ship 5, design first 3 to carry the load alone. |
| Light mode strategy | "Stick to light mode" | "Light mode UI on muted background; never ship dark for a light-mode app" | Aligned. |
| Tools | "Screenshots.pro, Previewed, Rotato (skip), AppMockUp" | + AppLaunchpad (Figma plugin), SmoothShadow | Add AppLaunchpad to tools.md. |
| Anti-patterns | Marketing mockups, gradients, emoji, 3D rotations | Same + "Ugly Ads trend means heavily polished gallery now reads as inauthentic" | Gemini adds the **inversion** — over-polish now hurts at indie scale. Useful insight. |

**No material contradictions.** Gemini extends and specifies; doesn't refute.

---

## Direct competitor screenshot teardown (what Gemini didn't do for Unit's actual competitors)

Gemini analyzed Liftosaur generally (positive ref) but didn't do current-state teardowns of the apps Unit specifically positions against. Quick observations on the current state of the most direct competitors (verify before copying anything):

**Hevy** (the bloat anti-reference per `competitors.md`):
- Multi-screen gallery with social-feed prominently featured
- Includes "calorie burned" / "training streak" gamified UI in early screenshots
- Backgrounds use vibrant gym-photography blur effects
- Captions lean motivational ("Train smarter", "Track everything")
- This is exactly the visual language Unit must NOT replicate. Pure anti-reference.

**Strong** (original Lucas Whittaker era — what Unit positions as the lighter alternative to):
- Dense in-UI screenshots without marketing overlay
- Pre-acquisition, the gallery was utilitarian with weight/rep tables visible
- Post-acquisition (2024+ direction has drifted), the listing now leans more like Hevy
- Lesson: copy the *original* Strong ASO instinct, not the current state.

**Liftosaur** (the indie-respected competitor):
- As Gemini described — text-overlay-above, dense UI exposed, no apologies for complexity
- Backgrounds are flat solid colors
- The gallery looks like documentation, not advertising
- Closest existing competitor to the aesthetic Unit should ship.

**Jefit** (older, more bloated):
- Gallery features 3D rendered devices floating in gradients
- Heavy use of stock-athletic photography behind device frames
- Pure anti-reference — exemplifies the "App Store gallery as ad" failure mode Gemini warned about.

**Fitbod** (AI category, different positioning):
- Marketing-style gallery, leads with AI coach personality
- Different category — Unit's anti-positioning is "no AI coach", Fitbod's positioning is "we tell you what to lift"
- Useful as the anti-AI contrast for Unit's screenshot 3 (ghost values vs prescription).

**Rule for Unit**: design the gallery so a user who churned off Hevy or Jefit recognizes the visual language as the OPPOSITE — restrained, no marketing imagery, real UI, calm typography. Gemini's "Ugly Ads trend" point reinforces this: in 2026, a gallery that looks LESS like a marketing campaign converts BETTER among the anti-bloat audience.

---

## OCR-indexing implication (the big strategic shift)

Per Gemini source #25 (Reddit PSA), source #24 (AppRadar), source #26 (AppFigures): **Apple started OCR-indexing screenshot captions in June 2025**. Captions are now algorithmic metadata, equivalent in weight to subtitle and keyword field text.

**What this changes for Unit**:
1. The 5 first-screenshot tagline candidates in `app-store-copy-variants.md` were optimized for human conversion only. Now they need to ALSO carry indexing keywords.
2. The current top candidates (e.g., "Faster than writing it down.") have **zero high-volume keywords** — beautiful copy, indexes for nothing.
3. Top candidates need to balance brand voice + at least one keyword from the 100-char Keywords field analysis (`aso-keywords.md`).

**Examples reworked for OCR + brand voice**:
- "Faster than writing it down." (current) → "Gym tracker. Faster than writing it down." (adds "gym tracker" — high-intent direct-match)
- "One tap. Set logged. Timer running." (current) → "One tap workout log. Timer auto-starts." (adds "workout log", "timer")
- "Last session, pre-filled." (proposed for screenshot 3) → "Ghost values. Last session, pre-filled." (adds "ghost values" — niche term Unit should own)
- "Every set. Every PR. Local." (proposed for screenshot 4) → "Lifting log. Every set. Every PR. No account." (adds "lifting log", "no account")
- "Free on App Store." (current footer) → unchanged; the words "free" and "App Store" don't help indexing.

**Caveat**: don't keyword-stuff. Brand voice still wins. Gemini's prescription includes keyword density inline ("Minimalist Gym Workout Tracker & Rest Timer") which crosses into stuffing territory. The synthesis spec uses keyword-augmented but still natural copy.

**Confidence on this**: medium-high. The OCR-indexing claim is well-sourced but not Apple-confirmed. Even if false, the cost of writing slightly-keyword-aware captions is zero. Optimize for it.

---

## Push-back on Gemini's screenshot 5 prescription

Gemini's final 5-screenshot prescription includes:

> **Screenshot 5: The Honest Paywall (Expert Trust)** — Pro upgrade screen with $4.99/$29.99/$44.99 visible

**This is wrong for Unit's W3 launch.** Per `docs/launch-plan.md` §2 and `docs/product-compass.md` decision 2026-04-28:

- Phase 1 (W1-W4): the app ships **free for everything**, with a quiet "Unit Pro is coming" Settings card collecting founding-member intent.
- Phase 2 (W5+, conditional on ≥30 users at 3+ sessions/wk for 2 weeks): paywall flips on for Pro features (CSV export, Apple Health sync, custom icons, founding badge).

If screenshot 5 shows the paywall at W3 launch, the user lands in the App Store, sees pricing, installs, then opens the app and finds **no paywall**. Cognitive mismatch. Either confused or assumes the app is broken.

**Replace screenshot 5 with one of**:

a) **"No account. Works offline."** — establishes trust through privacy/local-first, which is high-value for the lifter persona who's seen too many "create an account" flows. Screenshot shows the no-onboarding flow or the local-data view.
b) **The notebook-vs-Unit comparison split-screen** — visually anchors Variant 1 (the recommended launch variant) and lets the user emotionally close on the notebook metaphor.
c) **A "Why I built this" founder note with face** — a calm, expert, founder-trust shot. Higher risk on brand voice; can backfire as parasocial.

**Recommended for the synthesis**: option (a). Trust + offline + no account is a triple-hit for Unit's target persona. Defer the paywall screenshot to W5+ when Pro flips on; at that point, swap screenshot 4 or 5 for the Pro view.

---

## Tool ecosystem — what to add to `tools.md`

Gemini surfaced 3 tools that aren't in `tools.md`:

1. **AppLaunchpad** (Figma plugin) — App Store screenshot templates pre-sized to Apple's spec. Free tier. Add to `tools.md` "skip permanently" exception list as "use during launch week, not ongoing."
2. **SmoothShadow** (Figma plugin) — drop-shadow generator for device frames. Free.
3. **SmoothCapture** (macOS app) — App Store preview video tool with native Apple-spec exports. Already in `tools.md` Section 2 implicitly via "Submagic + Opus Clip + CapCut" — but **SmoothCapture is the better fit for App Store preview videos** specifically (auto-exports correct dimensions per device class). Worth adding as a one-time-use tool ($30 lifetime if I recall pricing — verify before paying).

**Decision**: don't expand `tools.md` permanent stack. Add a one-time "launch-prep tools" section with AppLaunchpad + SmoothCapture as the two extras, used during W1-W3 only.

---

## What I'm NOT doing in the synthesis (and why)

- Re-running my own deep research — Gemini covered the broad survey adequately. My value-add is reconciling, pushing back, and mapping to Unit's tokens.
- Designing the screenshots myself in this doc — the user explicitly said they'd take screenshots and design in Figma themselves. My job is the spec, not the rendering.
- A/B testing protocol beyond what's in `viral-patterns` §7 — Gemini's section 5 is sufficient, and at W3 launch you don't have enough traffic to A/B anyway. Defer until W6+.
- Localization — single-language at launch per launch-plan.md. Revisit at $5k+ MRR.

---

## Recommended next moves

1. **Read the synthesis** at `screenshot-strategy-final.md` — that's the executable spec.
2. **Don't quote Gemini's percentages directly** anywhere external (Reddit, X, App Store). The numbers are directional, not citation-grade.
3. **OCR caption rework** — when designing in Figma, use the keyword-augmented variants of the 5 taglines (specified in the synthesis), not the original brand-voice-only versions.
4. **Spot-check 2 indie apps Gemini cited** — pull up Liftosaur and DevUtils on the App Store directly, verify Gemini's pattern reads. 5 min sanity check.
5. **Push back on yourself** if you're tempted to use 3D rotations, gradients, or stock photography. Both Gemini and `viral-patterns` agree this is the highest-cost mistake.

## See also

- `gemini-app-store-screenshots-2026-04-30.md` — the source report this note audits
- `viral-patterns-2026-04-29.md` §7 — the prior research baseline this cross-references
- `screenshot-strategy-final.md` — the Figma-ready spec (drives the actual work)
- `app-store-copy-variants.md` — the 5 tagline candidates per variant
- `aso-keywords.md` — the keyword pool for OCR-aware caption writing
- `Unit/UI/DesignSystem.swift` — the actual tokens Figma must match
