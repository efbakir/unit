---
name: Unit
description: The fastest, most trustworthy gym logging tool for athletes who already know how to train.
colors:
  ink: "#0A0A0A"
  actionBlue: "#0068E0"
  actionBlueSoft: "#EAF2FF"
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
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "56px"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-0.6px"
  headline:
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.3px"
  title:
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.3px"
  body:
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 500
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "normal"
  caption:
    fontFamily: "-apple-system, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  numeric:
    fontFamily: "ui-monospace, SFMono-Regular, monospace"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "normal"
    fontFeature: "tnum"
  marketingHeroMobile:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.035em"
  marketingHeroTablet:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "52px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.035em"
  marketingHeroDesktop:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "60px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.035em"
  marketingCampaignMobile:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.02
    letterSpacing: "-0.04em"
  marketingCampaignDesktop:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "44px"
    fontWeight: 700
    lineHeight: 1.02
    letterSpacing: "-0.04em"
  marketingDisplayMobile:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: "-0.025em"
  marketingDisplayDesktop:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "54px"
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: "-0.025em"
  marketingSectionMobile:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  marketingSectionDesktop:
    fontFamily: "Geist, -apple-system, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  webMetadata:
    fontFamily: "Geist, GeistMono, -apple-system, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.3
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
    backgroundColor: "{colors.actionBlue}"
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
    textColor: "{colors.actionBlue}"
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
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "4px 8px"
    height: "44px"
---

# Design System: Unit

**October 20 approved color override:** `AppColor.accent` is blue `#0068E0`, with `accentSoft` `#EAF2FF` and the existing Chalk foreground. This supersedes references below to Ink as the action accent. Ink remains the primary text/data color. Reuse existing action and selection owners; no per-exercise colors. Layout, type, and native navigation structure remain unchanged.

Runtime owners and the DEBUG catalog: [design-system index](docs/design-system-index.md).

## 1. Overview

**Creative North Star: "The Lab Notebook"**

Unit is the gym notebook a serious lifter has been writing in for a year — quiet, page-like, and trusted because it never gets in the way. The visual system is built around a single belief: under fatigue, the only things that should compete for the eye are the numbers the lifter is reading and the one button they need to press next. Everything else recedes into milk-grey paper and bond-white cards.

The aesthetic is *iron and paper*: solid Ink (#0A0A0A) accents on Bond (#FFFFFF) cards floating on a Milk (#F5F5F5) page. There is no glow, no gradient, no decorative motion in the hot loop. Cards separate from the page through fill contrast, never through drop shadows. Numerics use monospaced digits and dominate visual hierarchy — weight, reps, and timers are the loudest elements on every screen because they are the data the lifter is actually reading mid-set. Copy is small, secondary, and quiet.

This system explicitly rejects the visual category of "fitness tracker" software. It is not a Strong/Hevy/Jefit spreadsheet, not a Strava feed, not a Whoop dashboard. There are no neon data viz arcs, no gradient hero metrics, no recovery rings, no badge animations, no stock-photo athletes. If a pixel doesn't help log faster or read state more clearly under fatigue, it does not belong.

**Key Characteristics:**
- Light-only for this release (after the recorded two-second black onboarding brand opener, the established light appearance is rendered regardless of the system trait)
- Flat by doctrine — separation through fill contrast, never shadows
- Numerics-first hierarchy (monospaced digits at display size dominate every workout screen)
- One Ink-black primary CTA per stress screen, full-width, 60pt tall
- Surface area kept small: 12 colors, ~14 `AppFont` cases (native SF Pro + SF Mono), 3 radii, 8 spacing steps — and growing them requires a Gym Test justification

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

**October 19 user override:** native SF Pro, restrained letter spacing, standard-size layout priority. Existing point sizes and native Dynamic Type scaling remain. This supersedes the bundled Geist decision for the iOS app; website typography is a separate surface.

**Sans:** SF Pro for body, headings, buttons, and caps labels.
**Mono:** SF Mono for workout numerics and set-result rows.

Use `AppFont`. The existing `Font.geist` / `UIFont.geist` names are compatibility helpers backed by system font factories; they no longer request bundled Geist. Bundled asset removal is separate cleanup.

### Hierarchy

- **Splash title:** SF Pro Bold 56, tracking -0.6.
- **Large title / title / product heading:** SF Pro Bold 22 / 20 / 24, tracking -0.3.
- **Section header / body:** SF Pro SemiBold / Medium 17, native spacing.
- **Caption / muted / metadata:** SF Pro Medium 15 / 13 / 11, native spacing.
- **Overline / small label:** SF Pro Medium 13 / 11, uppercase with zero extra tracking; emphasized overline is Bold.
- **Numeric display:** SF Mono Bold 36, neutral tracking.
- **Numeric input:** SF Pro Bold 36 with tabular digits.
- **Product action:** SF Pro Bold 17.
- **Performance / step indicator:** SF Mono SemiBold 15 / 14.

### Marketing type ramp

The public website uses the same Geist families, medium-weight floor, and
Ink/Ash hierarchy with a responsive editorial scale. These are named web
tokens in `app/globals.css`, not feature-level one-offs:

- **Hero** (`.h-hero`): 40 / 52 / 60px, line-height 1.0, tracking -0.035em.
- **Campaign heading** (`.h-campaign`): 34 / 44px, line-height 1.02.
- **Display CTA** (`.h-display`): 40 / 54px, line-height 1.04.
- **Section heading** (`.h-section`): 26 / 32px, line-height 1.1.
- **Narrative body:** 16px minimum; 18–20px is reserved for hero/supporting leads.
- **Metadata:** 12–14px only for dates, status, compact data labels, and controls.

Uppercase mono `.eyebrow` labels are metadata, not general section decoration.
Navigation, footer headings, and section introductions use sentence-case Geist.

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
- **Ghost** (`AppGhostButton`): No fill, no border, blue (`accent`) label. Every text button uses it: full width (17 bold, 60pt) for standalone actions, `layout: .inline` (15 medium, 44pt hit area) inside rows and headers. No underline, no black or gray text buttons (decision 2026-10-24). "Add X" at the end of a card's list uses `AppCardListAddRow`. The `accentSoft` tone of Secondary is **banned for "Add X" actions**.
- **Pressed:** `ScaleButtonStyle` is the single custom pressed state: 0.96× scale and 18% opacity dim over 150ms. Reduce Motion or VoiceOver uses the fade only; disabled controls retain their paired colors. Use it on every custom tappable card, row, and button. Native toolbar, alert, toggle, picker, and menu controls keep iOS feedback. Never add a screen-local pressed treatment.

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

`AppStepper`: Pumice background, `AppRadius.md` (14px) capsule, 44×44pt minimum tap targets on each ± button. Compact values use Body (17px medium) with monospaced digits; prominent workout values retain Numeric Display. The fundamental "tweak a number" affordance for weight and rep adjustment.

### Dividers

`AppDivider`: 1px height, Hairline color at 55% opacity. The only divider primitive in the system. Raw `Divider()` is banned.

### Navigation

- **`ProductTopBar`:** 64pt tall, Title typography (24px semibold rounded, tracking -0.3), title in Ash (secondary text), 16pt spacing between leading/title/trailing slots. Sizes: `.md` and `.large`.
- **Root tab bar:** native SwiftUI `TabView` / `UITabBar` chrome. Today and Programs keep their navigation state, system selection feedback, Dynamic Type, and accessibility behavior. Do not recreate a custom tab bar.
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
- **Do** show a trailing disclosure chevron on navigating cards/rows through the shared owner. Use `PreviewListRow(showsDisclosure: true)`; preserve plain read-only previews and selection controls. User decision: 2026-10-19.
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

## JOI direction — 20 October 2026

The full JOI-inspired overhaul supersedes earlier default 24pt card gutters and
centered boxed empty states. Page headings and empty states sit directly on the
page, left aligned. Cards group related content; previews do not add a second
filled container. Default card and list-row horizontal gutters are 16pt; section
headers use the existing 15pt secondary role. Explicit inset exceptions remain
for the active logging inputs and full-bleed charts/dividers.

Existing surface tokens: page #FAFAFA, card #FFFFFF, inset #F5F5F5, secondary
control #F0F0F0, active control #E5E5E5. Blue #0068E0 remains for primary actions,
selection and the rest line. Top-bar actions are ink. Native navigation owns its
materials. Keep numeric sizes, button heights and card radii. Completed and
upcoming exercises each use ExerciseSummaryRow, with a leading title, wrapping
metadata and far-trailing completion mark. No new component or variant.

### Surface separation correction — 20 October 2026

Page background uses `AppColor.background` #F5F5F5 again; cards remain white.
This supersedes the JOI pass’s #FAFAFA page value: the user found white cards
too difficult to distinguish. Logging weight inputs center the number and unit
as one group, retaining full-width tap targets.

### Rounded typography trial — 20 October 2026

User-approved SF Pro Rounded trial through the existing UIFont.geist bridge;
SF Mono workout values remain unchanged. JOI’s exact font is unconfirmed.
Secondary control fill returns to #E8E8E8; active fill #D6D6D6 for clearer
separation on both #F5F5F5 pages and white cards. No new tokens/components.

### 21 October corrections

Standard SF Pro restored at user request; SF Mono unchanged. Collapsed exercise
cards use 16pt inner spacing, full-width leading content and trailing completion
marks; expired Undo no longer reserves invisible space. Shared sticky action
chrome uses 16pt bottom spacing above native navigation.

Analytics correction: simplification must retain charts and Best/Next tables.
Keep single-point and no-recent-data chart states; simplify repeated wording only.
