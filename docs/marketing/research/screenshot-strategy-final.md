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
| Screenshot 5          | **"No account. Works offline."** (NOT paywall)            | Composition, no device frame — icon+label trio mirrors the in-app Settings Data section. Paywall off at W3 per launch-plan.md / product-compass.md 2026-04-28 |

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

**Purpose**: close on trust. NOT a paywall (paywall is OFF at W3 per launch-plan.md and product-compass.md decision 2026-04-28). Composition, not a device-frame capture — the three trust facts read faster as iconography than as a Settings list.

```
Layout:           Composition, NO device frame. Flat canvas.
                  Top 20%: headline + subhead.
                  Middle 55%: three stacked icon+label rows, vertically centered.
                  Bottom 25%: breathing space, empty.

Canvas:           1290 × 2796 px, background #F5F5F5, sRGB, no transparency.
Margin:           Horizontal 8% (≈103 px) — matches other 4 screenshots.

Headline (Geist Bold, 110pt, #0A0A0A):
    No account.
    Works offline.

Subhead (Geist Regular, 36pt, #595959):
    Your training data lives on your iPhone. Always.

The three fact rows (vertically centered within the middle 55% band):
  Row gap:        64 px between rows.
  Row layout:     [icon 96pt] [label 56pt left]   [value 56pt right, baseline-aligned]
  Optional:       1 px #E5E5E5 hairline divider between rows, full-bleed
                  within the 8% horizontal margin (mirrors in-app AppDividedList).

  Row 1 — Storage:
    Icon:  SF Symbol  iphone                            (regular weight, #0A0A0A)
    Label: "Storage"  (Geist Medium 56pt, #0A0A0A)
    Value: "On this iPhone"  (Geist Regular 56pt, #595959)

  Row 2 — Account:
    Icon:  SF Symbol  person.crop.circle.badge.xmark    (regular weight, #0A0A0A)
    Label: "Account"  (Geist Medium 56pt, #0A0A0A)
    Value: "None"  (Geist Regular 56pt, #595959)

  Row 3 — Tracking:
    Icon:  SF Symbol  hand.raised.slash                 (regular weight, #0A0A0A)
    Label: "Tracking"  (Geist Medium 56pt, #0A0A0A)
    Value: "None"  (Geist Regular 56pt, #595959)

    Originally specified as "Export data" + PRO chip. That spec triggered
    an App Review rejection on 2026-06-03 (Guideline 2.1(b) — Information
    Needed): the marketing screenshot promised a Pro tier that v1.0.0's
    binary does not carry (no IAPs configured in App Store Connect per the
    2026-05-31 Decouple decision). Replaced with "Tracking: None" — a true
    fact about v1.0.0 (verified by PrivacyInfo.xcprivacy: only UserDefaults
    declared, no third-party analytics SDKs, no tracking) that maintains
    the three-fact rhythm and reinforces the calm-honest brand voice.
    See docs/decision-log.md 2026-06-03 for the full reasoning. Re-add the
    Pro/Export row in the v1.1+ screenshot refresh when Pro IAPs ship.

Glyph rationale:
    iphone                          most literal read of "on this iPhone".
                                    Beats internaldrive (too technical) and
                                    house (too abstract).
    person.crop.circle.badge.xmark  explicit negation, no ambiguity. Beats
                                    person.slash (reads "blocked user")
                                    and bare xmark.circle (no human cue).
    hand.raised.slash               replaces square.and.arrow.up (the
                                    original "Export data" icon). Universal
                                    "stop / refuse" gesture paired with a
                                    cancellation slash reads as "we do not
                                    track" without needing the label to do
                                    the work alone. Beats eye.slash (reads
                                    "hidden", not "absent") and shield.slash
                                    (reads "security off", inverted intent).

    All three are stock SF Symbols at regular weight. They live ONLY in the
    Figma marketing file — DesignSystem.swift AppIcon enum is unchanged.

Pattern reference:
    1Password / Bitwarden / Proton (per visual-treatment catalog, 2026-05-10) —
    vertically-stacked icon+label trio with no device frame, for three
    independent trust facts. Same "show, don't claim" intent as the
    TypingMind reference in the prior brief, but content is promoted from
    settings-row chrome to first-class glyphs so each fact scans at
    App Store thumbnail size.

OCR caption:
    "Local gym tracker. No account. Offline."

Decision history (2026-05-10):
    Original brief listed two options — (a) onboarding screen "no sign-up
    path", (b) Settings showing "no account / on device / Pro export".
    Option (a) was killed by code exploration (Unit has no discrete
    onboarding screen — sign-up is proven by absence, which can't be
    photographed). Pivoted to (b) and built the Data section in SettingsView.
    Same-day pushback: a Settings capture still reads as "screenshot of a
    settings list" first, "trust mechanic" second. Pivoted to (c) this
    composition. The in-app Data section stays — it remains a real product
    surface independent of the marketing asset. See decision-log entries
    "Settings gets a 'Data' section to carry App Store screenshot #5"
    AND "Screenshot #5 pivots from Settings capture to iconographic
    three-fact composition" (both 2026-05-10).

Why NOT the paywall (push-back from app-store-screenshots-2026-04-30.md):
    Per launch-plan.md §2 and product-compass.md decision 2026-04-28, the
    paywall is OFF at W3 launch and conditionally flips on at W5+. Showing
    a paywall in the listing creates UX mismatch (user sees pricing, installs,
    finds no paywall, confused). Defer the paywall screenshot to W5+ once
    Pro is live. SUPERSEDED 2026-06-03 — the original "PRO chip in row 3
    is a gentle upgrade hint" framing was rejected by App Review under
    Guideline 2.1(b): a PRO badge with no IAP behind it reads as paid
    content the reviewer cannot evaluate. Row 3 is now "Tracking: None"
    (no Pro signal at all) until the v1.1+ Pro launch resubmission, at
    which point a paywall screenshot can replace slot 5 entirely.

Why NOT other treatments considered:
    Device frame + small corner lock glyph    Preserves rhythm with 2–4 but
                                              defeats the goal of moving away
                                              from a literal app capture.
                                              "Lock" also reads "encryption",
                                              a different claim from "no
                                              account / offline".
    Pure typographic, no imagery              Strongest restraint but loses
                                              the three-fact enumeration that
                                              is the whole "show, don't
                                              claim" intent.
    Horizontal three-column trio              More "feature page" energy but
    (Notion-style)                            less faithful to the Settings
                                              Data section's vertical flow,
                                              and less readable at thumbnail.
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
5. **Screenshot 5 (Trust)** — composition (no device frame); icon+label rows + typography. ~45 min.

**Total: ~4.75 hours** for all 5, including UI captures. Spread across two sessions for fresh eyes on the second pass.

---

## Pre-export checklist

Before uploading to App Store Connect:

- [ ] All 5 at exactly 1290 × 2796
- [ ] PNG, RGB, no alpha channel, < 8 MB each
- [ ] No emoji in any caption
- [ ] No gradients, no stock photography, no 3D rotations
- [ ] Geist Bold 110pt for all headlines (consistent)
- [ ] Background `#F5F5F5` on all 5
- [ ] Real UI from the app (not vector mockups) on screenshots 2-4 (screenshot 5 is a composition — icon+label rows, no device frame)
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
