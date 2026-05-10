# App Store screenshots — final strategy + Figma-ready spec

> **The single executable artifact** that drives Figma work for Unit's W3 launch screenshots.
> Synthesizes `gemini-app-store-screenshots-2026-04-30.md` (broad survey) + `app-store-screenshots-2026-04-30.md` (audit + push-back) + Unit's actual design tokens from `Unit/UI/DesignSystem.swift`.
> Resolved 2026-04-30.

---

## The decisions (locked)

| Decision              | Resolution                                                | Rationale                                                                                                         |
| --------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Variant to ship       | **Variant 1 — "Notebook Replacement"**                    | `app-store-copy-variants.md` recommended; matches launch-plan.md hero direction; widest searcher comprehension    |
| Number of screenshots | **5**                                                     | Gemini + `viral-patterns` §7 agree; first 3 carry the load, 4-5 are secondary                                     |
| Orientation           | **Portrait only**                                         | 96% of top apps; Unit is iPhone-only, light-only, portrait-only per CLAUDE.md                                     |
| Reference dimensions  | **1290 × 2796** (iPhone 16/17 Pro Max)                    | Apple auto-scales down. Single source of truth per Apple spec                                                     |
| Caption position      | **Above device frame**                                    | OCR-friendly, doesn't obscure UI, matches Liftosaur/DevUtils precedent                                            |
| Background color      | **`#F5F5F5`** (Unit's `AppColors.background`)             | Light mode, brand-cohesive. NOT Gemini's "muted slate or sage" — Gemini doesn't have access to DesignSystem.swift |
| Headline font         | **Geist Bold** at 110pt                                   | Unit's actual display font (Geist family per AppFont). 110pt = upper end of Gemini's 80-120pt range               |
| Headline color        | **`#0A0A0A`** (Unit's `AppColors.textPrimary` / `accent`) | Per CLAUDE.md: "accent is `0x0A0A0A`" not `#FF4400`                                                               |
| Subhead font          | **Geist Regular** at 36pt                                 | Matches Unit's `numericInput` size, generous but not display                                                      |
| Subhead color         | **`#595959`** (`textSecondary`)                           | Calm, not stark                                                                                                   |
| Device frame          | **Standard iPhone 16 Pro Max, straight-on (0° tilt)**     | No 3D rotations. Gemini + viral-patterns both flag this.                                                          |
| Screenshot 5          | **"No account. Works offline."** (NOT paywall)            | Paywall is OFF at W3 launch per launch-plan.md and product-compass.md decision 2026-04-28                         |

---

## Per-screenshot Figma spec

### Canvas (every screenshot)

```
Frame:        1290 × 2796 px
Background:   #F5F5F5 (Unit AppColors.background)
Bleed:        0 (no transparency, RGB only — Apple spec)
Export:       PNG, sRGB color space
File size:    < 8 MB per screenshot
Margin:       Horizontal 8% (≈ 103 px) — generous breathing room on either side
```

**Geist font**: install from `Unit/Resources/Fonts/` (the `.otf` files referenced in `DesignSystem.swift`). In Figma, install Geist locally; do NOT substitute Inter or SF Pro — the Geist character is part of the brand.

---

### Screenshot 1 — The Hero Claim

**Purpose**: arrest attention in 0.5s. Reader knows what Unit is and isn't, before swiping.

```
Layout:           Hero composition. NO full device frame.
                  Top 35%: headline + subhead.
                  Bottom 65%: cropped, full-bleed UI of the active set-logging row.

Headline (Geist Bold, 110pt, #0A0A0A):
    Your gym notebook,
    upgraded.

Subhead (Geist Regular, 36pt, #595959, max 2 lines):
    Log a set in under 3 seconds. Free on App Store.

UI crop (bottom 65%):
    Real screenshot of the active workout view.
    Show the set-logging row mid-gesture: ghost values visible, "Done"
    button highlighted, rest timer countdown visible. Cropped tight to the
    logging row + 1 row above and below for context.
    Background of crop: white (#FFFFFF — AppColors.cardBackground)
    so the UI floats clean above the F5F5F5 page background.

Pattern reference:
    DevUtils (per Gemini §3) — hero headline dominance, no marketing fluff.

OCR caption (the algorithmic-indexing copy — separate from the visual headline):
    "Gym tracker. Faster than writing it down."

Why this version:
    "Your gym notebook, upgraded." matches Variant 1's exact subtitle from
    app-store-copy-variants.md. The OCR caption adds "gym tracker" (Bucket 1
    direct-match keyword from aso-keywords.md) for indexing weight.
```

---

### Screenshot 2 — The Core Loop (Frictionless Logging)

**Purpose**: prove the speed claim. Show the actual flow — ghost value → tap → done.

```
Layout:           Standard device frame, straight-on (0° tilt).
                  Top 20%: headline + subhead.
                  Middle 75%: device frame + UI screen.
                  Bottom 5%: empty breathing space.

Headline (110pt):
    One tap. Set logged.
    Timer running.

Subhead (36pt):
    Ghost values pre-fill last session. You confirm. Done.

UI inside frame:
    Active workout session screen.
    Set table visible: 3 sets logged, 1 active.
    Active set shows ghost-value: weight + reps pre-filled in subdued style.
    Subtle highlight ring around the "Done" button (inside the UI mockup,
    not as marketing overlay).
    Rest timer Live Activity preview visible at top of phone (Lock Screen
    or Dynamic Island peek if technically render-able).

Device frame:
    iPhone 16 Pro Max, light bezel (Apple stock), straight-on, no rotation.
    Drop shadow: SmoothShadow plugin recommendation; soft, multi-layer,
    subtle (10-15% opacity, 40-60px blur, no offset).

Pattern reference:
    Liftosaur (UI-dense, documentation-style) — proves the mechanism.

OCR caption:
    "One tap workout log. Rest timer auto-starts."
```

---

### Screenshot 3 — Ghost Values (the differentiator)

**Purpose**: name the unique mechanic. Audience that knows Strong/Hevy understands instantly.

```
Layout:           Standard device frame, straight-on.
                  Top 20%: headline + subhead.
                  Middle 75%: device frame.

Headline (110pt):
    Ghost values.
    Last session, pre-filled.

Subhead (36pt):
    No prescription. No AI coach. Just what you did.

UI inside frame:
    Exercise detail view.
    Show ghost-value text rendered in `textTertiary` (#707070) for the
    pre-fill, with the user's tap-to-confirm interaction state visible.
    Two rows visible: row 1 "BENCH PRESS — Ghost: 100kg × 5 (last session)"
    and row 2 same exercise with the user's current set being logged at
    102.5kg × 5 (one notch up).

Device frame:
    Same as screenshot 2. Consistency across 2-3-4 = visual rhythm.

Pattern reference:
    Liftosaur (data-density without apology) + Strength Direct (proving
    one core mechanic).

OCR caption:
    "Strength log. Ghost values. Last session pre-filled."
```

---

### Screenshot 4 — History + PRs (proof of progression)

**Purpose**: answer "but does it remember?". History + automatic PR detection are free-tier features, must be on the launch listing.

```
Layout:           Standard device frame, straight-on.
                  Top 20%: headline + subhead.
                  Middle 75%: device frame.

Headline (110pt):
    Every set.
    Every PR. Local.

Subhead (36pt):
    Full history. Automatic PR detection. No account.

UI inside frame:
    History calendar view OR exercise progress view (pick one — calendar
    likely converts better because it's a unique visual hook).
    If calendar: month grid with logged days highlighted, one day expanded
    showing the lifts. Subtle "PR" badge on one of the entries (rendered
    in #34C759 success color from AppColors).

Device frame:
    Same as 2 and 3.

Pattern reference:
    Streaks (per Gemini §3) — using native data viz as the primary
    aesthetic draw.

OCR caption:
    "Lifting log. Every set, every PR, no account."
```

---

### Screenshot 5 — Trust + Local-First

**Purpose**: close on trust. NOT a paywall (paywall is OFF at W3 per launch-plan.md and product-compass.md decision 2026-04-28).

```
Layout:           Standard device frame, straight-on.
                  Top 20%: headline + subhead.
                  Middle 75%: device frame.

Headline (110pt):
    No account.
    Works offline.

Subhead (36pt):
    Your training data lives on your iPhone. Always.

UI inside frame:
    SettingsView with the Data section visible at the top. Three rows:
      • Storage          On this iPhone
      • Account                    None
      • Export data               [PRO]
    The section enumerates the trust mechanic as facts — TypingMind-style
    proof, not a marketing claim. PRO chip is the gentle upgrade hint
    without an active paywall sheet.

    Decision history (2026-05-10): the brief originally listed two
    options — (a) onboarding screen "no sign-up path", (b) Settings
    showing "no account / on device / Pro export". Code exploration
    confirmed (a) does not exist as a discrete screen — every onboarding
    step is implicit-only proof (no sign-in field). Pivoted to (b) and
    built the Data section in SettingsView. See decision-log entry
    "Settings gets a 'Data' section to carry App Store screenshot #5".

Device frame:
    Same as 2-3-4.

Pattern reference:
    TypingMind (per Gemini §3) — establishing trust with technical users
    by showing the trust mechanic, not a marketing claim about it.

OCR caption:
    "Local gym tracker. No account. Offline."

Why NOT the paywall (push-back from app-store-screenshots-2026-04-30.md):
    Per launch-plan.md §2 and product-compass.md decision 2026-04-28, the
    paywall is OFF at W3 launch and conditionally flips on at W5+. Showing
    a paywall in the listing creates UX mismatch (user sees pricing, installs,
    finds no paywall, confused). Defer the paywall screenshot to W5+ once
    Pro is live.
```

---

## Tooling — exact stack for the launch

| Step | Tool | Cost | Notes |
|---|---|---|---|
| Capture iPhone screen recordings | iOS Control Center → Screen Recording | $0 | Built-in. 1170×2532 native, scale up for 6.9" or capture on 6.9" device |
| Layout in Figma | Figma + **AppLaunchpad** plugin | $0 free tier | Templates pre-sized to 1290×2796. Per Gemini §6 |
| Drop shadows on device frames | **SmoothShadow** Figma plugin | Free | Per Gemini §6 |
| Geist font | Local install (Unit/Resources/Fonts/) | $0 | Already in repo |
| Export | Figma native PNG export at 1× | $0 | RGB, no transparency, < 8 MB per file |
| Optional: 3D-rendered devices | **Skip Rotato** | — | Per Gemini §4 anti-pattern: 3D rotations obscure UI. Use flat device frames. |
| Preview video (separate workstream) | **SmoothCapture** | ~$30 lifetime (verify) | Per Gemini §5: native App Store-spec exports. |

**Don't use** for App Store screenshots: Mockuuups Studio, Smartmockups (lifestyle photography behind device — anti-brand), Galileo / Uizard (AI mockup tools — not App Store-quality per Gemini §6).

---

## Order to build in Figma (priority sequence)

Build screenshot 1 first; it's the most important and design decisions cascade from it (typography size, padding, headline/subhead ratio).

1. **Screenshot 1 (Hero)** — biggest design decision. ~2 hours.
2. **Screenshot 3 (Ghost Values)** — the most-defining feature. Build before 2 because the UI capture needs the most setup. ~1 hour.
3. **Screenshot 2 (Core Loop)** — copies 3's device-frame layer and changes the inside. ~30 min.
4. **Screenshot 4 (History/PRs)** — same. ~30 min.
5. **Screenshot 5 (Trust)** — same. ~30 min.

**Total: ~4.5 hours** for all 5, including UI captures. Spread across two sessions for fresh eyes on the second pass.

---

## Pre-export checklist

Before uploading to App Store Connect:

- [ ] All 5 at exactly 1290 × 2796
- [ ] PNG, RGB, no alpha channel, < 8 MB each
- [ ] No emoji in any caption
- [ ] No gradients, no stock photography, no 3D rotations
- [ ] Geist Bold 110pt for all headlines (consistent)
- [ ] Background `#F5F5F5` on all 5
- [ ] Real UI from the app (not vector mockups) on screenshots 2-5
- [ ] Captions OCR-readable: keyword density without keyword stuffing
- [ ] Each caption has at least one keyword from `aso-keywords.md` Bucket 1, 2, or 4
- [ ] First 3 screenshots tell the story alone (test: hide 4 and 5, can a stranger understand Unit?)
- [ ] Light mode UI throughout (no dark-mode UI in any screenshot — Unit is light-only)
- [ ] No "transform your training" / "crush your goals" / motivational copy anywhere
- [ ] No competitor names anywhere
- [ ] Pricing referenced once at most (subhead of screenshot 1) and matches `pricing.md` ($4.99 / $29.99 / $44.99 — but only if you want to surface pricing at launch; otherwise omit per anti-paywall-screenshot logic)

---

## A/B test plan (post-launch, NOT for W3)

**At W3 launch**: ship Variant 1 only. Don't A/B at zero traffic; signal will be noise.

**At W6 (~3 weeks post-launch, once impressions accumulate)**:
- Run Apple PPO test: Variant 1 control vs. Variant 3 ("Speed-First") — see `app-store-copy-variants.md`
- Treatment changes ONLY screenshot 1 + subtitle
- Minimum 1,000 impressions per variant before reading
- Target 80% confidence, not 95% — per Gemini §5 indie-scale guidance
- Primary metric: impression → product page tap
- Run for 2-4 weeks before declaring a winner

**At W12 (quarterly)**: review Custom Product Pages opportunity. If keyword data shows specific high-volume terms (e.g., "rest timer app", "PPL tracker") with non-trivial impressions, build a CPP for the top 1-2 keywords with screenshot 1 customized to that keyword's framing.

---

## Open questions (NOT blocking the W3 launch)

1. **Should screenshot 4 use calendar view or progress chart view?** Both are free-tier features. Calendar likely converts better (unique visual); chart is more "data-density" signal. Decision: ship calendar at W3, hold the chart in reserve for the W6 PPO test.
2. **Should the subhead on screenshot 1 mention pricing?** Tradeoffs: mentioning establishes trust ("free on App Store"); omitting reduces noise. Decision: include "Free on App Store" only on screenshots 1 and 5, omit on 2-3-4 to keep them focused.
3. **Localization?** Skip for W3 launch. Revisit at $5k MRR or international install spike.
4. **Should the Geist font be embedded in the Figma file or referenced locally?** Embed the font file in the Figma project. If you collaborate with anyone, they need the font.

---

## Tracking after launch

Per `cadence.md` weekly metrics review, add this row to your Sunday tracking:

| Metric | Where | Target |
|---|---|---|
| Product page → install conversion rate | App Store Connect → Analytics → Sources & Conversion | 3.4-5.0% (per Gemini §1 indie baseline) |
| First screenshot impressions vs taps | App Store Connect → Product Page → Analytics | Track week-over-week |
| Search appearance for "gym tracker", "workout log" | AppFigures (per `tools.md`) | Improving rank week-over-week |
| If running PPO at W6+: variant tap-rate delta | App Store Connect → PPO results | Statistical significance flag |

---

## See also

- `gemini-app-store-screenshots-2026-04-30.md` — the broad-survey research
- `app-store-screenshots-2026-04-30.md` — the audit + push-back layer
- `viral-patterns-2026-04-29.md` §7 — prior-art conversion research
- `app-store-copy-variants.md` — the 3 positioning variants and the 5 first-screenshot taglines
- `aso-keywords.md` — the keyword pool for OCR-aware caption writing
- `Unit/UI/DesignSystem.swift` — the actual color/font/spacing tokens
- `tools.md` — the $51/mo stack (note: AppLaunchpad and SmoothCapture are launch-week-only adds, not permanent)
