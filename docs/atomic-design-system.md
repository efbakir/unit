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
- **Interactive**: `accent` = `#0068E0`, `accentForeground` = `#F6F6F6`, `accentSoft` = `#EAF2FF` (October 20 user-approved blue). `accent` doubles as the `.tint(...)` on every NavigationStack — there is no separate `systemTint`. Exercise data and charts retain neutral text colors; no exercise-family colors were approved.
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

Use `.image(size:weight:)` for consistent sizing. Six user-drawn body-fold `unit.lift.*` vectors exported from Figma are reserved for the Big 6 in Analytics and exercise detail: squat, bench press, deadlift, overhead press, barbell row and pull-up. `ExerciseIconResolver` matches complete canonical names/aliases and returns `nil` for other exercises, including related movements and equipment variants. There is no generic exercise-icon fallback. Today, routines, pickers, onboarding and active logging remain text-only. `AppIcon` owns template/native rendering; `AppMainLiftCard.iconTile` owns the 20/28pt neutral tiles. All six marks use `AppColor.textPrimary`, including empty main-lift cards. Original Figma outlines are preserved on transparent centred 32pt canvases. Source nodes and adjustments: `docs/qa/movement-icons-v3/source.json`.

**Rules**

- Set icon size explicitly at the call site (see `ProductTopBar` / `AppListRow` for defaults).
- **Navigation rows/cards**: `appNavigationDisclosure()` is the single trailing-chevron layout owner in `DesignSystem.swift`. `AppListRow(showsDisclosure: true)` applies it inside row padding; `PreviewListRow(showsDisclosure: true)` delegates to it. Custom destination labels use the modifier inside their link/button. Native `List` navigation links retain the system disclosure to avoid doubling. Read-only, selection, inline action, and toolbar controls do not opt in.
- **Navigation preview rows**: `PreviewListRow(showsDisclosure: true)` owns the trailing chevron. Use `showsSeparator` between recessed preview rows. Read-only previews default to neither; selection/action rows retain their own semantics.

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

### Saved-action feedback

`AppPrimaryButton(isConfirmed:)` temporarily replaces its label with the existing checkmark symbol while retaining its measured label layout. `WorkoutCommandCard` owns the 2.5-second dwell and starts it only after its saved-set signal changes. The next eligible set remains immediately actionable. Reduce Motion and VoiceOver use a fade; the existing success haptic remains the single tactile owner.

`RestTimerControl` uses the existing `cardRowFill` for quiet secondary controls, with no outline. Geometry and typography are unchanged.

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
| Raw disclosure glyph in feature code | Shared navigation row disclosure or `AppIcon.forward` for a navigating card header |
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


### Preview row spacing and separators — 19 October 2026

`PreviewListRow` owns the recessed preview’s 16pt horizontal inset and symmetric vertical breathing. Its identity-first content is vertically centered within the existing 80pt minimum, growing for longer content. `PreviewListContainer` owns the surface and capped scroll viewport only, with no second layer of row padding. Separators overlay the full row width outside the content inset. `AppDividedList` no longer supports inset separator variants; its rows own padding and its dividers span the container. No new tokens, components or visual variants were introduced.

Recessed compact navigation rows use a 64pt minimum with 16pt vertical breathing, matching the preview viewport estimate. Disclosure arrows use the shared 12pt indicator size, medium weight and `AppColor.textDisabled` across custom navigation rows/cards; native List disclosures remain system-owned. Overflow keeps the next title visible rather than exposing only its inset.

Workout targets and their weight/reps editor reuse the existing `AppFont.numericInput` role at30pt, the user-approved middle size between36pt and24pt. Product headings stay24pt; large timer numerics retain their own36pt role. No new font token or variant.

## Native bar material — October 19 override

Navigation backgrounds use SwiftUI `toolbarBackgroundVisibility(.automatic, for: .navigationBar)`. Do not force `.visible`, a `.bar` background style or custom standard/scroll-edge appearances: the system decides when scrolling content needs a backdrop. Existing typography and tint remain. The latest native-only correction removes all forced hard/soft scroll-edge styles. `appScrollEdgeSoft` is a pass-through compatibility entry point; SwiftUI chooses its default effect. Tab labels use the system font with no UITabBarItem appearance override. AppScreen does not add an outer clip around its native ScrollView; the system owns content clipping beneath the bars.

Pinned header/action sections in AppScreen occupy separate layout space, so content cannot scroll behind them. They match the page surface with no permanent material strip or separator. Native bars retain their own scroll-driven separation. No hand-drawn gradients. Sheets keep their native background. Content-card styling and all sizes stay unchanged.

## Stable workout motion — October 19

SetProgressIndicator reserves its existing44pt interactive height in every state; completing the first set cannot enlarge the row. State replacements reuse AppBlurTransition (normal arrival,0.92 shrink/blur removal) and collectionChange. WorkoutCommandCard holds metric/supporting/CTA layout slots across saved-set feedback; visible font/icon/button sizes are unchanged. PR evidence fits inline where possible and stacks on narrow widths. RestTimerControl has one persistent label hierarchy and a flexible centre column, keeping adjust buttons anchored through idle/running/paused/ready states. Exercise identity changes only the card’s upper content through a PlateSteps-style blur/fade; the timer keeps its identity. Existing Reduce Motion/VoiceOver gates keep fades.

## Automatic next exercise — October 19

WorkoutCommandCard’s optional `onSetConfirmationFinished` event fires after its existing2.5s saved-set confirmation; it does not own navigation or create another timer. ActiveWorkoutView rechecks exercise identity, completed working-set goal and open editors/confirmations before advancing. The same blur/fade and prefill owners prepare the next exercise. Moving from a completed exercise preserves its running/paused rest timer and scheduled alert; explicitly skipping an unfinished exercise still stops rest. The final exercise retains explicit Finish workout. No automatic set logging or guessed weights.

## Logging crossfades — October 19 audit

AppPrimaryButton keeps saved-icon/text layers mounted and animates their opacity directly with AppMotion.transition. It reuses AppIcon.checkmarkFilled in monochrome (filled circular shape, tick cut out), not a new icon/component. Saved indication still holds2.5s. An automatic exercise handoff owns its outgoing saved card; it does not first flash the old label. SetProgressIndicator keeps one horizontal scroll hierarchy at every width and animates chip-value layout changes. Mixed workout metric sentences crossfade; actual numeric counters keep numeric transitions. Native weight inputs stay immediate, with only their unit suffix fading.

Keep stateful presentation layers mounted when they crossfade. Bind animation after the changing opacity/style at that layer; an ancestor animation or transition duration alone does not prove that a disappearing label will fade. The completed metric keeps its control hierarchy (disabled with a metric-only accessibility label) so Adjust can fade rather than disappear through reparenting.

## Analytics R5 (approved 19 October 2026)

- `AppStatusSummaryCard`: one combined accessible summary. `AppFont.analyticsStatus` is 34pt SF Pro bold, tracking −0.8. The page owns its native explanation sheet.
- `AppMainLiftCard`: 16pt inset, existing 14pt radius, 30pt SF Pro/tabular number, small unit, comparison, shared chart and Best/Next footer. Full-width divider; no shadow. The caller owns navigation. Empty slots have no navigation affordance.
- `AppTrendChart`: one Swift Charts owner for cards and detail. Calendar-week points/domains come from `AnalyticsEngine`; the view only draws and supports native direct manipulation. Card charts are hidden inside the combined card element; detail exposes Audio Graphs. Scrubbing clears on release or cancellation. AppChartMetrics owns 96pt and accessibility 120pt card heights; detail reuses 160pt.
- Existing `AppIconCircle(shape: .roundedRect)` owns icon tiles. On-card tiles use `.background`; the detail header uses `.control` against the page background. No parallel tile component.
- Existing `AppCardList(rowVerticalInset: AppSpacing.xs)` owns compact Other/Recent/Best lists. Its standard 22pt list-card corners remain intentional; the newly approved summary and main cards use 14pt. Do not change list-card defaults across the product to match one page.
- Existing `AppColor` roles and native SF Pro/SF Mono remain. The approved icon tokens are `info`, `squat`, `deadlift`, `climbing`, `core`; `dumbbell` was reused.

Analytics is read-only. `AnalyticsStore` fetches completed sessions with set-entry prefetch, snapshots model values on their actor and computes off the main actor. A day/calendar/source-value cache invalidates on appear, context save, foreground, day/time-zone and active-program changes. `AnalyticsEngine` owns comparison windows, status persistence, best-set selection, main-lift identity, weekly series and estimates. `WorkoutTargetFormatter` owns locale-aware presentation. `ExerciseProgressView.SessionPoint` and the compatibility projection use this same engine.

The native TabView, tab-bar appearance and selection behavior are unchanged. Logging, progression and the SwiftData schema are outside this change. System dark appearance still presents Unit in light mode.

## Whole-day workout logging — approved 20 October 2026

`WorkoutDayList`, `ExerciseLoggingCard`, `CurrentSetRow`, `LoggedSetRow`,
`PlannedSetRow`, `ExerciseSummaryRow` and `RestBar` are the approved active-workout
owners in `DesignSystem.swift`. They compose existing card, button, input, icon,
color, spacing and press owners. `AppFont.setValue` / `setValueCompact` provide
30/28pt SF Mono values; `AppWorkoutMetrics` contains their geometry. Controls
retain Unit's approved blue accent and native navigation/keyboard behavior.

The current row alone contains Complete set. A successful save immediately
collapses it into a checked row and expands the next; no saved-mark dwell gates
logging. Undo reserves its slot for five seconds. Native Menu owns Edit / Mark
not done. The fixed RestBar owns time, draining progress and −15 / +15 / Skip;
it never repeats the upcoming set. While editing, its time moves to the native
keyboard toolbar. Existing command-card/step/timer definitions remain for their
catalog/preview consumers, but ActiveWorkoutView no longer uses them.

`WorkoutLoggingState` owns value-only row grouping, admission timing, Undo,
next-set text and optional routine-update candidates. SwiftData saves stay in
the existing view/model owner; schema and progression policy are unchanged.
Unlogged targets remain session-scoped preferences. Only explicit Finish →
Update writes their first logged values back to the routine. Explicit zero on
a weighted exercise is a real load; only the Bodyweight toggle changes that
exercise flag. The source brief is `docs/specs/2026-10-20-logging-final-b.md`;
its historical Geist references map to the already approved SF font system.

## Build85 gym-feedback follow-up — 2026-10-20

- WorkoutDayList now keeps one flat, stable exercise-ID hierarchy through upcoming/current/completed states. ExerciseSummaryRow is the one owner for separate flat completed/upcoming cards; completion sits at the trailing edge and all titles share the leading inset. This user-approved workout exception supersedes grouped upcoming rows only.
- CurrentSetRow reuses AppPrimaryButton for both preparation and completion, with distinct labels/actions. Preparation never creates a set. ActiveWorkoutView owns full-width native field composition, keyboard accessory buttons and the keyboard-visible current action; only one current action is interactive/visible. Typed drafts are separate from completed history.
- RestBar owns a blue line sampled from the manager deadline, mounted fading status/control layers, and accessibility gates. It does not own notifications, persistence or timer scheduling.
- AppStatusSummaryCard keeps its compatibility name but now draws an editorial page stack, not an extra card surface. Status remains34pt, supporting copy15pt, time context13pt via existing roles. AppMainLiftCard Best/Next labels use the muted role; data/charts unchanged. Exercise card titles use existing17pt roles; workout numbers retain30/28pt.
- AppTrendChart changes units/domains immediately and fades only the replacement drawing; scrub interaction and semantic readout remain immediate.

No new component, style variant, palette color, typography token or dependency was introduced by this feedback pass. JOI evidence and limits: docs/research/2026-10-20-joi-visual-language.md.

### Rest/footer consistency follow-up

RestBar’s existing status/progress functions are shared with the keyboard panel. Both use page background, the same gutters/divider, fixed status anchors and AppSecondaryButton containers. Duration stays in the same existing typography role in idle/running/finished; finished reads0:00. Rest controls remain visible and disabled outside running, with taps/accessibility actions suppressed. The keyboard panel adds its explicit current action as needed; it does not introduce another rest renderer. Details and runtime boundaries: docs/handoffs/2026-10-20-rest-footer-consistency.md.
