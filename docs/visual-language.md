# Unit — Visual language

**Light-mode only, calm, performance-focused.** The UI is built with the **atomic design system** (`atomic-design-system.md`): tokens live in `DesignSystem.swift`, screens compose through `AppScreen` and shared molecules/organisms.

**Core test:** Can a tired user read the screen and log a set in under 3 seconds?

---

## 1. Color

### Theme mode
**Light only** per CLAUDE.md §4 rule 3 — no dark-mode variants are maintained.

### Surfaces (role-based)
- **Page background** (`AppColor.background`): `#F5F5F5` — calm, neutral, softer than pure white. Navigation bars use native automatic scroll-driven backgrounds; nonoverlapping pinned sections match the page. There is no separate `barBackground` token.
- **Card surface** (`AppColor.cardBackground`): White `#FFFFFF` — cards separate from the Milk page through **fill contrast** alone (a 6.25% lightness step), **not shadows and not borders**. See `DESIGN.md` §4 "The Flat-By-Default Rule".
- **Row-on-card fill** (`AppColor.cardRowFill`): `#F5F5F5` — for elements nested inside `AppCard` (use with `AppRadius.sm` and `AppSpacing.sm`, per the Figma source of truth).

### Text

- **Primary** (`AppColor.textPrimary`): Black `#0A0A0A` for body, titles, and key data.
- **Secondary** (`AppColor.textSecondary`): `#595959` for labels, subtitles, helper copy, and empty-state hints.
- **Disabled** (`AppColor.textDisabled`): `#949494` for disabled buttons and inactive controls.

### Accent and primary CTA (high contrast)
- **Primary CTA background** (`AppColor.accent`): Ink ink in light mode, near-white in dark mode.
- **Primary CTA foreground** (`AppColor.accentForeground`): Text/icon color chosen to keep the CTA **high contrast** on `AppColor.accent`.
- **Rule**: Restrained — **one obvious primary action** per screen where the Gym Test applies.
- **Accent soft** (`AppColor.accentSoft`): Milk `#EBEBEB` for subtle fills and iOS-style utility controls.

### Supporting

- **Borders** (`AppColor.border`): Hairlines and `AppDivider` — use sparingly.
- **Success / warning / error** (`AppColor.success`, `warning`, `error`): `#34C759`, system warning, and `#FF3B30`; pair with icons or labels — never color alone (HIG).

---

## 2. Design system size (hard constraint)

Keep the token set **small**. New roles need a Gym Test or clarity justification.

| Role | Guidance |
|------|-----------|
| Background levels | page / surface / card (as defined in atoms) |
| Text levels | primary / secondary / muted |
| Primary CTA | one dominant action per critical screen |
| Card treatment | prefer `AppCard` / `appCardStyle()` only |

---

## 3. Typography

- **Hierarchy**: Weight, reps, timers, and targets dominate. Exercise names and metadata are secondary.
- **Font**: **Geist** (sans) and **Geist Mono** (numerics / CTAs), bundled as `.ttf` in `Unit/Resources/Fonts/`. Always reach typography via **`AppFont`** variants — never `Font.custom(...)` directly in feature code.
  - **Title / headings (Geist Sans)**: `AppFont.largeTitle`, `AppFont.title`, `AppFont.sectionHeader`, `AppFont.productHeading`. (`sectionHeader` doubles as the button label style — there is no separate `label` case.)
  - **Body / labels (Geist Sans)**: `AppFont.body`, `AppFont.caption`, `AppFont.muted`.
  - **Workout numerics (Geist Mono)**: `AppFont.numericDisplay` for fast fatigue-friendly reading; `AppFont.performance` and `AppFont.stepIndicator` for compact numeric rows and step counters; `AppFont.productAction` for primary CTA labels with mono digits.
- Prefer `AppFont` cases over inline `.font(.geist(...))` / `.font(.geistMono(...))` so typography stays consistent.
- **Rule**: Never use regular (400) font weight anywhere in the app. The minimum weight is **medium** (500). Geist is bundled in three weights only: Medium, SemiBold, Bold.
- **Rule**: If text doesn’t help log or understand state, remove or demote it.

---

## 4. Layout and structure

- **Cards**: Rounded rectangle (`AppRadius.card` = 22) with iOS continuous corners, padding `AppSpacing.lg` (24). Separation from background is **fill contrast** alone — never drop shadows, never a border stroke (per `DESIGN.md` §4).
- **One primary CTA** on high-stress flows: full-width black (accent) button pattern via `AppPrimaryButton` unless a documented exception exists.
- **Compact controls and buttons**: `AppRadius.md` = 14 with iOS continuous corners.
- **Spacing**: 4pt grid via `AppSpacing` — consistent section gaps vs. tight in-card grouping.
- **Navigation**: Root/product screens use `ProductTopBar`; detail flows can remain on `AppScreen` + shared nav molecules. Touch targets stay ≥ 44×44pt.

---

## 5. Components and patterns
Pick the simplest UI that still satisfies the Gym Test. Keep the component surface area minimal in core flows:
- `AppScreen` (page wrapper) + `ProductTopBar` when a shared header is needed
- `AppCard` / `appCardStyle()` for card chrome
- `AppPrimaryButton` as the single dominant CTA (high contrast)
- `AppListRow` and `AppStepper` for fast, compact controls
- Session: `WorkoutCommandCard` (target + set progress) + `SessionStateBar` (rest/ready/next)
- Today: `ExercisePreviewStrip` (horizontal rail + overflow fade) + week-of-routine progress rendered through the standard `AppCard` + `AppFont` lockup

Patterns we rely on:
- Large tap targets and minimal steps for logging
- Clear success/failure feedback (no “did it save?” ambiguity)
- Avoid adding new bespoke components unless the pattern is missing from the atomic layers

---

## 6. Iconography

- **SF Symbols** only; weights/sizes set explicitly (`AppIcon` + `.image(size:weight:)`).
- Passive icons: secondary text color. Active / primary: accent or primary text as appropriate.

---

## 7. Rest timer and Live Activity

- **In-app**: Large, legible countdown; state obvious at a glance.
- **Pattern**: Use `RestTimerControl` inside `SessionStateBar`; avoid standalone giant timer cards or icon-only pause/play ambiguity.
- **Live Activity**: Lock Screen / Dynamic Island — same hierarchy principles; no decorative clutter.

---

## 8. Root shell

- **Tabs**: Root navigation uses native SwiftUI `TabView` / `UITabBar` chrome.
- **Active state**: Use the system-selected state with Unit's single accent; do not draw a second selection treatment.
- **Behavior**: Let `TabView` own state preservation, touch feedback, Dynamic Type, and accessibility. Do not recreate a custom tab bar.

---

## 9. What we are not doing

- No gratuitous gradients, glows, or decorative illustration in core flows
- No shadows or “elevated” card illusions — rely on surface/background contrast and borders
- No unbounded one-off components in page files — extend atoms/molecules/organisms first
- No custom replacement for native root-tab chrome
- No floating text-only header actions without a clear tap container
- No spreadsheet-style logging layouts with parallel target/actual tables on critical set-entry screens
- No premature “Next exercise” CTA while the current exercise still owns the primary action

---

## Summary

| Element | Rule |
|---------|------|
| Background | Neutral grey page; white cards/surfaces via atoms |
| Cards | `AppCard` / `appCardStyle`; contrast, not shadows |
| Accent | Tokenized; one clear primary CTA on stress screens |
| Typography | Numbers and targets first; use `AppFont` |
| Structure | Atomic layers + `AppScreen` for new work |
| Benchmark | Gym Test + clarity under fatigue |

This visual language works with **`docs/atomic-design-system.md`** and the files under `Unit/UI/`.
