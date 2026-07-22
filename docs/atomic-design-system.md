# Unit — Atomic design system

> **Single source of truth for UI structure and tokens in the SwiftUI codebase.**  
> Before adding or changing views, read this file and `visual-language.md`. If a pattern is missing here, define it at the correct layer first, then implement.

---

## Philosophy

Unit’s interface follows **atomic design** (Brad Frost): build screens **bottom-up** from a small, named set of tokens and components. Screen files (`*View.swift`) wire data and navigation; they do not invent one-off colors, spacing, fonts, or card chrome.

| Layer | Role | Location in repo |
|-------|------|-------------------|
| **Atoms** | Indivisible tokens and base primitives (color, type, spacing, radius, icons, divider) | `Unit/UI/DesignSystem.swift` (`AppColor`, `AppFont`, `AppSpacing`, `AppRadius`, `AppIcon`, `AppDivider`) |
| **Molecules** | Small reusable composites with one job | `Unit/UI/DesignSystem.swift` (`AppListRow`, `AppStepper`, `AppPrimaryButton`, etc.) |
| **Organisms** | Larger sections (cards, settings groups) | `Unit/UI/DesignSystem.swift` (`AppCard`, `ProductTopBar`, `WorkoutCommandCard`, etc.) |
| **Templates** | Screen shell: nav, scroll, padding, optional sticky CTA | `Unit/UI/DesignSystem.swift` (`AppScreen`) |
| **Pages** | Real screens with real data | `Unit/Features/**/**/*View.swift` |

All atoms, molecules, organisms, and the screen template live in **one file** (`DesignSystem.swift`). The atomic taxonomy above is the conceptual map, not the file layout — keep the single-file layout unless the file genuinely outgrows it.

**Rule:** Prefer tracing every visual decision to **`AppColor`**, **`AppFont`**, **`AppSpacing`**, **`AppRadius`**, or **`AppIcon`**. Legacy feature code may still reference older theme types during migration — new work must use atoms.

---

## Atoms

### Colour — `AppColor`

Defined in code today (hex → `Color` via `UIColor`). Names express **role**, not implementation.
**Light-mode only** per CLAUDE.md §4 rule 3 — no dark-mode variants are maintained.

- **Surfaces**: `background` = `#F5F5F5`, `cardBackground` = `#FFFFFF`, `cardRowFill` = `#F5F5F5` (nested-in-card recipe), `sheetBackground` = `#FFFFFF`, `controlBackground` = `#E8E8E8` (single canonical neutral surface — steppers, segmented track, disabled buttons, muted chips), `border` = `#E5E5E5`
- **Text**: `textPrimary` = `#0A0A0A`, `textSecondary` = `#595959`, `textDisabled` = `#949494`
- **Progress**: `progressSegmentFill` = `#3A3A3A` (filled segment in onboarding's multi-step progress)
- **Interactive**: `accent` = `#0A0A0A`, `accentForeground` = `#F6F6F6`, `accentSoft` = `#EBEBEB`. `accent` doubles as the `.tint(...)` on every NavigationStack — there is no separate `systemTint`.
- **Status**: `success` = `#34C759`, `warning` = `#FF9500`, `error` = `#FF3B30`. Plus accessible chip pairs `successSoft`/`successOnSoft`, `warningSoft`/`warningOnSoft`, `errorSoft`/`errorOnSoft`.

**Rules**

- Do not scatter `Color(red:green:blue:)` or raw hex in feature views — extend `AppColor` if a new role is justified.
- Prefer semantic names (`textSecondary`) over `.gray` / `.black` in new UI.
- For `.tint(...)`, always pass `AppColor.accent` (not a local `Color`).

### Typography — `AppFont`

Every font is an enum case that bundles its `font`, `color`, and `tracking`. Apply via `.appFont(.X)` on `Text` (font + tracking together) or `.font(AppFont.X.font)` elsewhere. Sans is **Geist**; numeric/CTA cases (`numericDisplay`, `stepIndicator`, `productAction`, `performance`) use **Geist Mono** for fixed-width digits under fatigue. Both ship as `.ttf` in `Unit/Resources/Fonts/` (registered via `UIAppFonts` in `Info.plist`).

Body hierarchy: `largeTitle`, `title`, `sectionHeader`, `body`, `caption`, `muted`, `metadata`.
Display / specialized: `overline`, `smallLabel`, `splashTitle`, `splashWelcome`, `numericDisplay`, `stepIndicator`, `productHeading`, `productAction`, `performance`.

**Rules**

- **Never use regular (400) font weight.** The minimum weight across the entire app is **medium** (500). Geist is bundled in Medium, SemiBold, Bold only.
- Avoid inline `.font(.geist(...))` / `.font(.geistMono(...))` in page files for standard hierarchy; use `AppFont` cases. Inline `.font(.system(...))` is reserved for SF Symbol weight on `AppIcon` only.
- Tracking is **bundled with each case** — never load a loose `*Tracking` constant; either use `.appFont(.X)` (Text) or `.tracking(AppFont.X.tracking)`.
- For 17pt bold section headings AND button labels, use `sectionHeader` (or `productAction` if the label needs monospaced digits). There is no separate `label` case.

### Spacing — `AppSpacing` · Radius — `AppRadius`

Use named steps (`xs` … `xl` / `sm` … `lg`) for padding, `VStack` spacing, and corner radii.

**Rules**

- Avoid magic numbers like `.padding(16)` in new screens — use `AppSpacing.md` (or documented composition).
- Large surfaces and cards use **`AppRadius.card` (alias of `lg`) = 22**.
- Buttons and compact controls use **`AppRadius.md` = 14**.
- Compact chips, row pills, and elements nested inside `AppCard` use **`AppRadius.sm` = 10** with `AppColor.cardRowFill` (Figma source-of-truth recipe).
- Rounded shapes should use iOS-style continuous corners, not default sharp rounding.

### Icons — `AppIcon`

SF Symbol names as `String` raw values; use `.image(size:weight:)` for consistent sizing.

**Rules**

- Set icon size explicitly at the call site (see `AppNavBar` / `AppListRow` for defaults).
- **List rows**: `AppListRow` is chevron-free by design; do not add `chevron.right` for “disclosure” — use context and tap targets (HIG: don’t rely on chevrons alone for meaning).

### Divider — `AppDivider`

Use instead of bare `Divider()` where the design system specifies a hairline with `AppColor.border`.

---

## Molecules

| Component | Purpose |
|-----------|---------|
| `AppListRow` | Standard list row; optional leading icon, title, subtitle, trailing slot. Use `.cardListContent` only when `AppCardList` owns the row chrome. |
| `AppStepper` | − / value / + control with fixed internal spacing |
| `AppTag` | Pills (default, accent, success, warning, error, muted, custom) |
| `AppPrimaryButton` | Full-width primary CTA (see `visual-language.md` for height/contrast) |
| `AppSecondaryButton` | Pumice-fill secondary action; tones `.default`, `.accentSoft`, `.destructive` |
| `AppGhostButton` | Text-only "Add X" trigger for inside-card affordances |
| `ProductTopBarAction` | Shared pill-style header action for text and icon affordances |
| `IconSquareButton` | 48pt icon action for secondary card controls and compact utility actions |
| `ExercisePreviewItem` | Compact preview item for exercise name + target inside horizontal summary rails |
| `SetProgressIndicator` | Set-step tracker with Ink current, neutral completed/failed/upcoming, and Verde PR-completed states |
| `MetricDisplay` | Large numeric/value lockup for target, timer, and command-style data |
| `RestTimerControl` | Rest countdown control with `-15`, central timer pill, and `+15` |
| `UnitTabItem` | Custom root-tab item with icon + label and clear active state |

### Pressed-state rule

`ScaleButtonStyle` is the single pressed treatment for every custom tappable
card, row, and button: 0.96× scale, 14% opacity dim, and 8% brightness reduction
over the 150ms `AppMotion.Duration.press` token. Native toolbar, alert, toggle,
picker, and menu controls keep iOS feedback. Fix press feedback in
`ScaleButtonStyle`; never create a screen-local variant.

Toolbar and nav-bar chrome defers to iOS-native — there is no `AppNavBar` molecule. Use `ProductTopBar` for root/product screens and the system `.toolbar { }` API (no `.weight(...)` on `ToolbarItem` buttons) for detail screens.

---

## Organisms

| Component | Purpose |
|-----------|---------|
| `AppCard` | Default card surface: padding, `cardBackground`, `AppRadius.card` |
| `appCardStyle()` | Modifier matching `AppCard` when a wrapper type is awkward |
| `AppDividedList` | Bare divided list of rows separated by `AppDivider`. Use directly only when you already own the surrounding card chrome. |
| `AppCardList(data) { row }` | **Canonical** list-in-card primitive — bakes the 8/24 inset recipe and the divider. Hand-composing `AppCard { AppDividedList(...) }` outside `DesignSystem.swift` is banned (hook-enforced). |
| `AppCardListAddRow` | Trailing "+ Add X" affordance designed to live in `AppCardList(_:row:trailing:)`. |
| `SettingsSection` | Titled group inside an `AppCard` |
| `ProductTopBar` | Shared root/product-screen top bar replacing ad-hoc large title headers |
| `ExercisePreviewStrip` | Horizontal exercise-summary rail with overflow fade cue |
| `WorkoutCommandCard` | Primary workout command surface: set progress, target metric, `Done`, and edit |
| `SessionStateBar` | Bottom-aligned rest/ready/next-exercise state handler for active sessions |
| `UnitTabBar` | Shared custom root tab bar; native UITabBar visuals are not used on root screens |

---

## Templates

**`AppScreen`** is the standard page wrapper: optional custom header, legacy nav bar path, horizontal padding, scroll content, optional sticky `AppPrimaryButton`.

**Rules**

- New full-screen flows should compose inside `AppScreen` rather than ad-hoc `VStack` + custom nav.
- Root/product screens should prefer `customHeader:` with `ProductTopBar`; legacy `AppNavBar` remains for detail flows still on the old path.
- Bottom primary actions should go through `primaryButton:` when they match the sticky CTA pattern.

---

## Pages (feature views)

Allowed in `*View.swift`:

1. `AppScreen { … }` (or justified legacy layout during migration)
2. Organisms and molecules
3. Navigation, `@Query`, `@State`, view models

**Avoid in page files (for new code)**

- Raw padding/spacing numbers, raw corner radii, one-off `Color(…)` / `.foregroundStyle(.gray)`
- Custom top bars instead of `ProductTopBar` + system `.toolbar { }`
- Inline card chrome duplicating `AppCard` / `appCardStyle()`
- Hand-composed `AppCard { AppDividedList(...) }` — use `AppCardList(data) { row }`

---

## Banned patterns (review checklist)

| Pattern | Prefer |
|---------|--------|
| `Divider()` where spec calls for tokenized hairline | `AppDivider` |
| `.padding(16)` / `.cornerRadius(12)` in new UI | `AppSpacing.*` / `AppRadius.*` |
| Rounded rectangles with default corner rendering | `RoundedRectangle(..., style: .continuous)` |
| Native UITabBar visuals on root screens | `UnitTabBar` via app-shell `safeAreaInset` |
| `AppTabHeader` large-title root chrome on Today / Program | `ProductTopBar` |
| `chevron.right` on `AppListRow`-style content | Context + row tap; no decorative chevron |
| `.regular` weight anywhere; calling `Font.custom("Geist*"/"GeistMono*")` directly | `AppFont` cases (Medium minimum); never bypass `AppFont` for Geist |
| New hex colours in Features | `AppColor` extension or asset + wrapper |
| Page-specific workout timer cards / custom command panels | `ExerciseCommandCard` + `SessionStateBar` |
| Floating text-only header actions without visible tap area | `ProductTopBarAction` |
| Ambiguous logging copy like “Log target” | Outcome labels like `Done`, `Finish Session`, `Next exercise` |

---

## Related docs

- `visual-language.md` — tone, hierarchy, Gym Test, light-first surfaces
- `design-principles.md` — product principles + token discipline
- `apple-hig.md` — accessibility and platform rules

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-28 (latest) | Doc refresh after Geist swap + DS unification commits (`241ebeb`, `4beafb2`): font family is **Geist / Geist Mono** (not SF Pro Rounded); `AppNavBar` removed (toolbar chrome is iOS-native via `ProductTopBar` + system `.toolbar`); `AppCardList(data) { row }` is the canonical list-in-card primitive (hand-composed `AppCard { AppDividedList(...) }` blocked by hook); `HeroWorkoutCard` / `ExerciseCommandCard` / `WeeklyProgressStepper` removed from organism inventory. |
| 2026-04-28 (later) | Token simplification pass: removed `barBackground` (= `background`), `secondaryLabel` (= `textSecondary`), `systemTint` (= `accent`), `shadow`/`scrim` (orphans — chrome modifiers are stroke-only post-shadow refactor), `AppFont.listSecondary` (1 use → `body`), `AppFont.numericLarge` (0 uses), `AppFont.compactLabel` (1 internal use → inline), `AppRadius.sheet` (0 uses). Doc updated to match the actual single-file layout (`Unit/UI/DesignSystem.swift`) — empty `Atoms/Molecules/Organisms/Templates` subdirectories deleted. Two minor feature drifts fixed: `.headline` toolbar title in `ActiveWorkoutView` → `AppFont.sectionHeader`; `.padding(.vertical, 3)` in `PaywallView` → `AppSpacing.xs`. |
| 2026-04-28 | DS audit fixes: light-only palette (no dark variants), card chrome is now contrast + stroke (no shadows) per visual-language.md, `AppFont` flattened to single enum (statics folded into cases, tracking bundled), `mutedFill` / `disabledSurface` collapsed into `controlBackground`, `AppFont.label` / `display` removed (use `sectionHeader` / `numericDisplay`), `splashAccent` removed (orange `#FF4400` was banned + unused), stale config comment block dropped, `AppRadius.card` alias added (= `lg` = 22), `PreviewListContainer` uses canonical `cardRowFill` + `AppRadius.sm`. |
| 2026-03 | Initial doc: maps atomic layers to `Unit/UI/*`, aligns with `AppAtoms` / `AppScreen`. |
