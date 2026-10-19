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
- **Interactive**: `accent` = `#0A0A0A`, `accentForeground` = `#F6F6F6`, `accentSoft` = `#EBEBEB`. `accent` doubles as the `.tint(...)` on every NavigationStack — there is no separate `systemTint`.
- **Status**: `success` = `#34C759`, `warning` = `#FF9500`, `error` = `#FF3B30`. Plus accessible chip pairs `successSoft`/`successOnSoft`, `warningSoft`/`warningOnSoft`, `errorSoft`/`errorOnSoft`.

**Rules**

- Do not scatter `Color(red:green:blue:)` or raw hex in feature views — extend `AppColor` if a new role is justified.
- Prefer semantic names (`textSecondary`) over `.gray` / `.black` in new UI.
- For `.tint(...)`, always pass `AppColor.accent` (not a local `Color`).

### Typography — `AppFont`

Every font is an enum case that bundles its `font`, `color`, and `tracking`. Apply via `.appFont(.X)` on `Text` or `.font(AppFont.X.font)` elsewhere. Native **SF Pro** is the default; `numericDisplay`, `stepIndicator`, and `performance` use native **SF Mono**. Compatibility helpers retain their `geist` names but resolve system fonts. Caps labels use SF Pro with neutral tracking; headings have restrained negative tracking. Point sizes and native Dynamic Type scaling are preserved. The October 19 user instruction supersedes the earlier Geist family decision.

Body hierarchy: `largeTitle`, `title`, `sectionHeader`, `body`, `caption`, `muted`, `metadata`.
Display / specialized: `overline`, `smallLabel`, `splashTitle`, `splashWelcome`, `numericDisplay`, `stepIndicator`, `productHeading`, `productAction`, `performance`.

**Rules**

- **Never use regular (400) font weight.** The minimum weight across the entire app is **medium** (500). Native system fonts use the existing Medium, SemiBold, and Bold roles.
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

- Set icon size explicitly at the call site (see `ProductTopBar` / `AppListRow` for defaults).
- **List rows**: `AppListRow` is chevron-free by design; do not add `chevron.right` for “disclosure” — use context and tap targets (HIG: don’t rely on chevrons alone for meaning).

### Divider — `AppDivider`

Use instead of bare `Divider()` where the design system specifies a hairline with `AppColor.border`.

---

## Molecules

| Component | Purpose |
|-----------|---------|
| `AppListRow` | Standard list row; optional leading icon, title, subtitle, trailing slot. Use `.cardListContent` only when `AppCardList` owns the row chrome. |
| `AppInlineWeightField` | Canonical compact editable weight/increment field with unit and caller-owned accessibility label. |
| `AppSegmentedControl` | Existing exclusive choices use native `Picker(.segmented)` with `.controlSize(.large)` on iOS 26+. Optional unanswered choices, per-item disabled predicates, missing IDs, and iOS 18 retain the button implementation. The initializer fixes this policy for optional choices, even after selection. Caller supplies the group `label`; abbreviated items supply full accessibility labels. `Size` supports `.compact` / `.weekday`; unused `.tall` and dark selection chrome were removed. |
| `AppStepper` | − / value / + control with fixed internal spacing |
| `AppTag` | Pills (default, accent, success, warning, error, muted, custom) |
| `AppPrimaryButton` | Full-width primary CTA (see `visual-language.md` for height/contrast) |
| `AppSecondaryButton` | Pumice-fill secondary action; tones `.default`, `.accentSoft`, `.destructive` |
| `AppGhostButton` | Text-only "Add X" trigger for inside-card affordances |
| `ProductTopBarAction` | Shared pill-style header action for text and icon affordances |
| `SetProgressIndicator` | Set-step tracker with Ink current, neutral completed/failed/upcoming, and Verde PR-completed states |
| `RestTimerControl` | Rest countdown control with `-15`, central timer pill, and `+15` |
| `PreviewListRow` | Shared preview row; use `identityFirst` when long identity must wrap above target/evidence. |
| `AppOptionTileCard` | Canonical single-choice onboarding/selection card. |
| `AppSelectableTierCard` | StoreKit tier card with selected, disabled, accessibility, and compact-detail states. Purchase surfaces keep the selected tier expanded and may collapse supporting copy on unselected siblings. |

### Pressed-state rule

`ScaleButtonStyle` is the single pressed treatment for every custom tappable
card, row, and button: 0.96× scale and 18% opacity dim over the 150ms
`AppMotion.Duration.press` token. Reduce Motion or VoiceOver uses only the fade;
disabled controls retain their paired fill and foreground colors. Native toolbar, alert, toggle,
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
| `AppCardList(data) { row }` | **Canonical** list-in-card primitive — bakes the 8/24 inset recipe, divider, and full padded rectangular hit shape for interactive rows. Hand-composing `AppCard { AppDividedList(...) }` outside `DesignSystem.swift` is banned (hook-enforced). |
| `AppTimeline` | Read-only connected milestone rail for short time-based sequences. Uses `AppTimelineItem` data and canonical card/icon atoms; not a replacement for divided lists or onboarding step progress. |
| `AppCardListAddRow` | Trailing "+ Add X" affordance designed to live in `AppCardList(_:row:trailing:)`. |
| `SettingsSection` | Titled group inside an `AppCard` |
| `ProductTopBar` | Shared root/product-screen top bar replacing ad-hoc large title headers |
| `PreviewListContainer` | Capped preview viewport with overflow cue and two-line/Dynamic-Type sizing. |
| `WorkoutCommandCard` | Primary workout command surface: set progress, target metric, `Complete set`, adjustment, and timer. |
| `SessionStateBar` | Bottom-aligned rest/ready/next-exercise state handler for active sessions |
| `AppSetRepEditorSheet` | Shared routine target editor, including optional rep-range progression and increment. |
| `AppFeatureAccessTable` | Compact Dynamic-Type-safe paywall feature matrix. |

---

## Templates

**`AppScreen`** is the standard page wrapper: optional custom header, legacy nav bar path, horizontal padding, scroll content, optional sticky `AppPrimaryButton`.

**Rules**

- New full-screen flows should compose inside `AppScreen` rather than ad-hoc `VStack` + custom nav.
- Root/product screens may use `ProductTopBar`; detail screens use native navigation titles/toolbars.
- Root navigation uses native `TabView`; do not recreate a custom tab bar.
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
| Custom root-tab chrome | Native `TabView` / `UITabBar` behavior |
| `AppTabHeader` large-title root chrome on Today / Program | `ProductTopBar` |
| `chevron.right` on `AppListRow`-style content | Context + row tap; no decorative chevron |
| `.regular` weight anywhere; calling `Font.custom("Geist*"/"GeistMono*")` directly | `AppFont` cases (Medium minimum); never bypass `AppFont` for typography |
| New hex colours in Features | `AppColor` extension or asset + wrapper |
| Page-specific workout timer cards / custom command panels | `WorkoutCommandCard` + `SessionStateBar` |
| Floating text-only header actions without visible tap area | `ProductTopBarAction` |
| Ambiguous logging copy like “Log target” | Outcome labels like `Complete set`, `Finish workout`, `Next exercise` |

---

## Review surface and sheet behavior

Debug builds expose Settings → Design system → Components (`AppComponentCatalog`
in `DesignSystem.swift`). Samples use production components with local state only.
The catalog covers pressed, disabled, loading, large text, fade-only feedback,
and a failed-save editor. See [the short owner index](design-system-index.md).

`AppDropdownChip` and `AppFilterChip` retain native Menu/Button semantics while
private `AppFilterChipSurface` owns their shared capsule chrome and disabled fill.
`AppSheetScreen` renders a native leading X and preserves its caller's dismiss
handler; Save/Done is reserved for a committing action. `AppSetRepEditorSheet`
accepts a Bool save result: failure retains the input and presents a native alert.

`AppIconSize.compact`/`indicator` supplement `readiness`/`reward` for feature
symbols. `AppChartMetrics.compactHeight`/`standardHeight` own the existing chart
viewports; `AppColor.chartGrid`/`chartSelection` own their subdued colors.
Touch-target floors stay explicit at 44pt. Native widget metrics are unchanged.

## Related docs

- `visual-language.md` — tone, hierarchy, Gym Test, light-first surfaces
- `design-principles.md` — product principles + token discipline
- `apple-hig.md` — accessibility and platform rules

---

## Changelog

| Date | Change |
|------|--------|
| 2026-08-04 (latest) | Progressive-overload overhaul: documented `PreviewListRow.identityFirst`, two-line preview sizing, the extended `AppSetRepEditorSheet`, accessible inline weight/increment input, and the new shared `AppFeatureAccessTable`; corrected stale custom-tab and removed-component references. |
| 2026-04-28 (latest) | Doc refresh after Geist swap + DS unification commits (`241ebeb`, `4beafb2`): font family is **Geist / Geist Mono** (not SF Pro Rounded); `AppNavBar` removed (toolbar chrome is iOS-native via `ProductTopBar` + system `.toolbar`); `AppCardList(data) { row }` is the canonical list-in-card primitive (hand-composed `AppCard { AppDividedList(...) }` blocked by hook); `HeroWorkoutCard` / `ExerciseCommandCard` / `WeeklyProgressStepper` removed from organism inventory. |
| 2026-04-28 (later) | Token simplification pass: removed `barBackground` (= `background`), `secondaryLabel` (= `textSecondary`), `systemTint` (= `accent`), `shadow`/`scrim` (orphans — chrome modifiers are stroke-only post-shadow refactor), `AppFont.listSecondary` (1 use → `body`), `AppFont.numericLarge` (0 uses), `AppFont.compactLabel` (1 internal use → inline), `AppRadius.sheet` (0 uses). Doc updated to match the actual single-file layout (`Unit/UI/DesignSystem.swift`) — empty `Atoms/Molecules/Organisms/Templates` subdirectories deleted. Two minor feature drifts fixed: `.headline` toolbar title in `ActiveWorkoutView` → `AppFont.sectionHeader`; `.padding(.vertical, 3)` in `PaywallView` → `AppSpacing.xs`. |
| 2026-04-28 | DS audit fixes: light-only palette (no dark variants), card chrome is now contrast + stroke (no shadows) per visual-language.md, `AppFont` flattened to single enum (statics folded into cases, tracking bundled), `mutedFill` / `disabledSurface` collapsed into `controlBackground`, `AppFont.label` / `display` removed (use `sectionHeader` / `numericDisplay`), `splashAccent` removed (orange `#FF4400` was banned + unused), stale config comment block dropped, `AppRadius.card` alias added (= `lg` = 22), `PreviewListContainer` uses canonical `cardRowFill` + `AppRadius.sm`. |
| 2026-03 | Initial doc: maps atomic layers to `Unit/UI/*`, aligns with `AppAtoms` / `AppScreen`. |
