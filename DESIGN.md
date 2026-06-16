---
name: Unit
description: The fastest, most trustworthy gym logging tool for athletes who already know how to train.
colors:
  ink: "#0A0A0A"
  milk: "#F5F5F5"
  bond: "#FFFFFF"
  pumice: "#E8E8E8"
  hairline: "#E5E5E5"
  ash: "#595959"
  mist: "#949494"
  chalk: "#F6F6F6"
  spark: "#FF4400"
  verde: "#34C759"
  amber: "#FF9500"
  signal: "#FF3B30"
typography:
  display:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "56px"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-1.2px"
  headline:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.4px"
  title:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.4px"
  body:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 500
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "GeistMono, ui-monospace, SFMono-Regular, monospace"
    fontSize: "17px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "normal"
  caption:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  numeric:
    fontFamily: "GeistMono, ui-monospace, SFMono-Regular, monospace"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.6px"
    fontFeature: "tnum"
rounded:
  sm: "10px"
  md: "14px"
  lg: "22px"
  sheet: "40px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  smd: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.chalk}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "60px"
  button-primary-disabled:
    backgroundColor: "{colors.pumice}"
    textColor: "{colors.mist}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
  button-secondary:
    backgroundColor: "{colors.pumice}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "60px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "60px"
  card:
    backgroundColor: "{colors.bond}"
    rounded: "{rounded.lg}"
    padding: "24px"
  card-row:
    backgroundColor: "{colors.milk}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "8px"
  list-row:
    backgroundColor: "{colors.bond}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    padding: "8px 24px"
    height: "52px"
  divider:
    backgroundColor: "{colors.hairline}"
    height: "1px"
  stepper:
    backgroundColor: "{colors.pumice}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "4px 8px"
    height: "44px"
---

# Design System: Unit

## 1. Overview

**Creative North Star: "The Lab Notebook"**

Unit is the gym notebook a serious lifter has been writing in for a year — quiet, page-like, and trusted because it never gets in the way. The visual system is built around a single belief: under fatigue, the only things that should compete for the eye are the numbers the lifter is reading and the one button they need to press next. Everything else recedes into milk-grey paper and bond-white cards.

The aesthetic is *iron and paper*: solid Ink (#0A0A0A) accents on Bond (#FFFFFF) cards floating on a Milk (#F5F5F5) page. There is no glow, no gradient, no decorative motion in the hot loop. Cards separate from the page through fill contrast, never through drop shadows. Numerics use monospaced digits and dominate visual hierarchy — weight, reps, and timers are the loudest elements on every screen because they are the data the lifter is actually reading mid-set. Copy is small, secondary, and quiet.

This system explicitly rejects the visual category of "fitness tracker" software. It is not a Strong/Hevy/Jefit spreadsheet, not a Strava feed, not a Whoop dashboard. There are no neon data viz arcs, no gradient hero metrics, no recovery rings, no badge animations, no stock-photo athletes. If a pixel doesn't help log faster or read state more clearly under fatigue, it does not belong.

**Key Characteristics:**
- Light-first, system-honoring (light mode is the design baseline; dark adapts via system trait, never drives decisions)
- Flat by doctrine — separation through fill contrast, never shadows
- Numerics-first hierarchy (monospaced digits at display size dominate every workout screen)
- One Ink-black primary CTA per stress screen, full-width, 60pt tall
- Surface area kept small: 12 colors, ~14 `AppFont` cases (Geist sans + Geist Mono), 3 radii, 8 spacing steps — and growing them requires a Gym Test justification

## 2. Colors: The Material-Shop Palette

The palette is named like materials in a workshop, not like UI states. There is one accent (Ink), and it carries the identity. Everything else is a neutral or a system signal.

### Primary
- **Ink** (`#0A0A0A`): The single accent. Used on the primary CTA background, on body and title text, and as the workout numeric color. It is the loudest element on screen by definition — its rarity is the point.

### Neutral
- **Milk** (`#F5F5F5`): The page. Bars and the root background share it so the screen reads as one continuous sheet of paper. Also reused as the inner fill of `card-row` recesses inside cards.
- **Bond** (`#FFFFFF`): Card and sheet surfaces. Cards lift off Milk through pure value contrast — no shadow, no border, just a 6.25% step in lightness.
- **Pumice** (`#E8E8E8`): Secondary controls. Steppers, secondary buttons, capsule chrome. A flat, slightly chalky neutral that sits between Milk and the Ink accent without competing.
- **Hairline** (`#E5E5E5`): The 1pt divider. Used at 55% opacity inside `AppDivider`, never raw — it should be felt, not seen.
- **Ash** (`#595959`): Secondary and supporting text. Section labels, helper copy, metadata.
- **Mist** (`#949494`): Disabled text and disabled-state foregrounds. Lighter than Ash so disabled never reads as merely "secondary".
- **Chalk** (`#F6F6F6`): The text color on Ink CTAs. Slightly off-white for less optical glare against pure black.

### System
- **Verde** (`#34C759`): Success. PR detection, set-logged confirmation. Always paired with an icon or label, never carries meaning alone.
- **Amber** (`#FF9500`): Warning. Soft cautionary states. Always paired.
- **Signal** (`#FF3B30`): Error and destructive. Delete confirmations, validation. Always paired.

### Off-system
- **Spark** (`#FF4400`): The splash-screen orange. Reserved for the launch animation and home-screen icon only — **forbidden in the app shell**. There is no `AppColor` token for it; the splash asset carries the value directly.

### Named Rules

**The One Ink Rule.** Ink is reserved for the single primary action on a stress screen. If a screen has two Ink-filled buttons, one of them is wrong. Secondary actions take Pumice. Tertiary actions take Ghost (text-only, no fill).

**The Flat-By-Default Rule.** Cards never carry a drop shadow **or a stroke**. Separation between Milk page and Bond card is the 6.25% lightness step and nothing more. A hairline border at full opacity is the same failure mode as a shadow — both add chrome that fill contrast already provides. If a card needs more weight, the card is in the wrong place — not under-shadowed and not under-bordered.

**The Spark-Is-Splash Rule.** `#FF4400` orange is permitted in the splash screen and nowhere else. It is the legacy of a previous brand decision, retained for launch identity, banned everywhere downstream.

**The Soft-Pair Rule.** Verde / Amber / Signal never carry state alone. They always pair with an icon (`success.circle`, `exclamationmark.triangle`, `xmark.octagon`) or a text label. Color blindness is the test, not the exception.

## 3. Typography

**Sans Font:** Geist (bundled `.ttf` in `Unit/Resources/Fonts/`, weights Medium / SemiBold / Bold)
**Mono Font:** Geist Mono (numerics, primary CTAs, set-result rows — fixed-width digits under fatigue)

Both ship as bundled `.ttf` and are registered via `UIAppFonts` in `Info.plist`. Always reach typography via the `AppFont` enum — never `Font.custom("Geist*")` or `Font.custom("GeistMono*")` in feature code.

**Character:** Geist is a humanist neo-grotesque — quiet, neutral, with just enough warmth to keep the page from reading as clinical. Numerics, primary CTAs, and the workout-signature rows pivot to Geist Mono so weight and rep columns stay aligned at every Dynamic Type size — the lifter scans down a column, not across a row.

### Hierarchy

- **Splash title** (Geist Bold 56, line-height 1.05, tracking -1.2): Splash welcome only.
- **Headline / large title** (Geist Bold 22, tracking -0.4): Screen-level titles. One per screen.
- **Product heading** (Geist Bold 24, tracking -0.4): `ProductTopBar` headings, hero copy on empty states.
- **Title** (Geist Bold 20): Section titles, exercise names on workout cards.
- **Section header** (Geist SemiBold 17): 17pt semibold section headings, list-row titles (program / template / routine names), and the canonical button-label style for sans buttons (no separate `label` case). Semibold (not bold) so row titles don't out-shout numerics on workout-adjacent lists and density reads closer to iOS-native.
- **Body** (Geist Medium 17, line-height 1.35): Default reading copy. List rows, descriptions, paragraph text.
- **Caption** (Geist Medium 15): Secondary metadata, helper text, timer subtitles.
- **Muted** (Geist Medium 13): Footnotes and very secondary copy.
- **Overline** (Geist SemiBold 10): Top-of-card overline labels.
- **Small label** (Geist Medium 11, tracking +1.0): Tiny uppercase "WAS" / "MOST POPULAR" style chips.
- **Numeric display** (Geist Mono Bold 36, tracking -0.6): Weights, reps, rest-timer countdown. The workout signature.
- **Product action** (Geist Mono Bold 17): Primary CTA labels and top-bar text actions.
- **Performance** (Geist Mono SemiBold 15): Set-result / PR rows in History.
- **Step indicator** (Geist Mono SemiBold 14): Set step counters in `SetProgressIndicator`.

### Named Rules

**The Medium-Floor Rule.** No text in the system uses `regular` (400) weight. The minimum is `medium` (500). At gym lighting and one-handed glance distance, regular weight goes mushy; medium reads at the same speed as bold without the heaviness.

**The Numerics-First Rule.** On any workout screen, the largest and heaviest element is a number — never a label, never an exercise name, never an icon. If something else is winning the visual hierarchy on a logging screen, the screen is wrong.

**The No-Decoration Rule.** No gradient text. No `background-clip: text`. No letter-spaced uppercase decoration. Type carries weight through size and weight contrast alone.

## 4. Elevation

**Unit is a flat system.** There are no shadow tokens. There is no `AppShadow` enum. Cards lift off the page through fill-value contrast (Bond `#FFFFFF` on Milk `#F5F5F5`, a 6.25% lightness step) and through generous internal padding. Sheets use the system presentation chrome — corner shape comes from iOS, not from a token, since no callsite needed a custom value.

There is one exception: the `appCardElevation` modifier exists for the rare moment a card sits over photographic or busy imagery (onboarding splash). It is not used in the workout shell and not part of the day-to-day vocabulary.

### Named Rules

**The Flat-By-Default Rule.** Surfaces are flat at rest. Depth is conveyed through value, padding, and the 1pt `AppDivider` hairline (`#E5E5E5` at 55% opacity). If you reach for a shadow, you are solving the wrong problem.

**The Soft-Edge Rule.** Content scrolling behind a fixed bar fades through the canonical `appScrollEdgeSoft(top:bottom:)` modifier — never a hand-rolled `LinearGradient` or `.mask`. This is the only legitimate "elevation" technique in the system, and there is exactly one implementation of it.

## 5. Components

The component set is deliberately small. Every primitive lives in `Unit/UI/DesignSystem.swift` — there is no Atoms/ folder splitting, by choice. New components require explicit user approval.

### Buttons

- **Shape:** rounded rectangle, `AppRadius.md` (14px), iOS continuous corners, 60pt tall, full-width on stress screens.
- **Primary** (`AppPrimaryButton`): Ink (`#0A0A0A`) background, Chalk (`#F6F6F6`) label, Label typography. One per screen on logging flows. Disabled state: Pumice background, Mist label.
- **Secondary** (`AppSecondaryButton`): Pumice (`#E8E8E8`) background, Ink label. Tones: `.default`, `.accentSoft`, `.destructive` (text-only Signal red).
- **Ghost** (`AppGhostButton`): No fill, no border, Ink label. Used for "Add exercise" / "Add set" triggers inside cards. The `accentSoft` tone of Secondary is **banned for "Add X" actions** — that's Ghost's job.
- **Pressed:** ScaleButtonStyle (transform only — no color change, no glow).

### Cards & Containers

- **Shape:** `AppRadius.lg` (22px) iOS continuous corners.
- **Background:** Bond (`#FFFFFF`).
- **Internal padding:** `AppSpacing.lg` (24px) horizontal and vertical by default.
- **Elevation:** none (see Elevation section).
- **Concentric geometry rule:** an Ink button placed inside a card uses `AppRadius.md` (14px) so the inner radius equals card-radius minus padding (22 − 8 = 14). Nested radii must stay concentric.

### Card Rows (the signature recess pattern)

Elements nested inside a card use `AppColor.cardRowFill` (Milk `#F5F5F5`) + `AppRadius.sm` (10px) + `AppSpacing.sm` (8px) padding. This creates a quiet recess inside the Bond surface — the card "page" with a Milk row "callout" inset into it. **This is the single canonical row-on-card recipe.** Do not invent parallel patterns with `controlBackground` or other fills.

### Lists

- **`AppDividedList`:** rows separated by 1pt `AppDivider` (Hairline `#E5E5E5` at 55% opacity). No outer chrome.
- **`AppCardList(data) { row }`:** the only sanctioned list-in-card primitive. Bakes the canonical 8/24 inset recipe and the divider. Never compose `AppCard { AppDividedList(...) }` by hand — the harness blocks it.
- **List rows:** 52pt minimum height, Body typography (17px medium), `AppSpacing.lg` (24px) horizontal padding.
- **Per-row shadowed cards are forbidden.** A list of N items is one Bond card with N divider-separated rows — never N stacked Bond cards.

### Steppers

`AppStepper`: Pumice background, `AppRadius.md` (14px) capsule, 44×44pt minimum tap targets on each ± button, value text in Label weight with monospaced digits. The fundamental "tweak a number" affordance for weight and rep adjustment.

### Dividers

`AppDivider`: 1px height, Hairline color at 55% opacity. The only divider primitive in the system. Raw `Divider()` is banned.

### Navigation

- **`ProductTopBar`:** 64pt tall, Title typography (24px semibold rounded, tracking -0.3), title in Ash (secondary text), 16pt spacing between leading/title/trailing slots. Sizes: `.md` and `.large`.
- **`UnitTabBar`:** custom tab bar; active tab gets a Pumice fill, inactive tabs are clear. Native `UITabBar` chrome is forbidden on root screens.
- **Toolbar buttons:** defer to iOS-native chrome. **`.weight()` modifiers on `ToolbarItem` buttons are banned** — they fight the system styling.

### Signature: The Workout Command Card

`WorkoutCommandCard` is the screen's center of gravity during a session. It uses `appWorkoutPanelChrome()`, displays the exercise name in Title, the working numeric (weight × reps) in `numericDisplay` (36px monospaced bold), and one Ink primary action ("Done"). An optional rest timer divides off the bottom with a 1pt divider at 32% opacity. There is no decorative chrome, no progress arc, no "next exercise" preview competing with the current action.

## 6. Do's and Don'ts

These guardrails carry PRODUCT.md's anti-references through into pixels. Every "Don't" maps to a real failure mode the system has rejected.

### Do:

- **Do** use Ink (`#0A0A0A`) as the single primary CTA color, and exactly one Ink CTA per stress screen.
- **Do** separate Bond (`#FFFFFF`) cards from the Milk (`#F5F5F5`) page through fill contrast alone — never with a drop shadow, never with a stroke.
- **Do** use monospaced-digit numerics (`AppFont.numericDisplay` / `numericLarge`) for every weight, rep count, and timer value, so columns align at every Dynamic Type size.
- **Do** use `AppCardList(data) { row }` for any list-inside-a-card pattern. It bakes the canonical 8pt vertical / 24pt horizontal inset recipe.
- **Do** use `appScrollEdgeSoft(top:bottom:)` whenever content scrolls behind a fixed bar.
- **Do** use the `cardRowFill` recess recipe (Milk fill + 10px radius + 8px padding) for any nested element inside a Bond card.
- **Do** keep `AppRadius` concentric — a 14px button inside a 22px card with 8px padding (22 − 8 = 14).
- **Do** pair Verde / Amber / Signal with an icon or label every time. Color is never the only carrier of state.
- **Do** keep touch targets ≥ 44×44pt everywhere. The Gym Test (one-handed, sweaty, fatigued) is the floor, not the ceiling.
- **Do** honor `accessibilityReduceMotion` — cross-fades and opacity only, no parallax or elastic.

### Don't:

- **Don't** introduce a parallel `LinearGradient` or `.mask` for scroll-edge fades — `appScrollEdgeSoft` is the single canonical implementation.
- **Don't** invent a new `struct X: View` / `ViewModifier` / variant when the existing canonical primitive in `DesignSystem.swift` covers ~80% of the case. Extend the canonical with `style:` / `variant:` / `tone:` instead. Parallel implementations are the worst drift in the system.
- **Don't** use `chevron.right` / `chevron.forward` anywhere. The system has no row-disclosure chevrons by doctrine.
- **Don't** use raw `Divider()`. Use `AppDivider` (Hairline at 55% opacity).
- **Don't** apply `.weight(.semibold/.bold/.heavy)` to `ToolbarItem` buttons. Toolbar chrome defers to iOS-native.
- **Don't** put `ScrollView` or `AppCard` as the root child of `.sheet { }`. Sheet roots are plain `VStack`.
- **Don't** use Spark orange (`#FF4400`) anywhere outside the splash screen. The accent is Ink.
- **Don't** use `regular` (400) font weight. The medium-floor is non-negotiable.
- **Don't** use a side-stripe border (`border-left` > 1px as a colored accent) on any card or row. Forbidden universally.
- **Don't** use gradient text or `background-clip: text` for emphasis. Use weight or size.
- **Don't** ship per-row shadowed cards stacked vertically. A list is one card with N rows, never N cards.
- **Don't** add a hairline stroke to card chrome. Bond on Milk is the separation; a 1pt border at full opacity is the same failure mode as a drop shadow.
- **Don't** show "0 kg" for bodyweight exercises. Show "BW". Don't use `–` or `—` placeholder copy.
- **Don't** build a target-vs-actual weight column UI. Last-time pre-fill only.
- **Don't** copy the Strong/Hevy/Jefit spreadsheet aesthetic — parallel target/actual columns, dense numeric rows, busy timer chrome. The whole "gym tracker app" visual category is the trap.
- **Don't** copy Strava / Nike Training Club patterns — feeds, badges, friend activity, share prompts, motivational hero copy, lifestyle photography of athletes mid-jump.
- **Don't** copy Whoop / Oura aesthetics — dark dashboards, neon data viz arcs, gradient hero metrics, recovery rings, sleep-score chrome. Unit is not a wellness product; it is a working tool.
- **Don't** add SaaS landing-page clichés to the marketing surface — stock-photo athletes, "transform your training" hero copy, three-icon feature grids, pricing tiers above the fold.
