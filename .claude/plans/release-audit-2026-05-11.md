# Unit — pre-release page audit (2026-05-11)

Static read-only audit per `/page-audit` skill across all main screens. No simulator runs (per CLAUDE.md §6).

Coverage: **27 screen files** across Onboarding, Today, Active Workout, Templates/Programs, History, Settings, Paywall. Six parallel audit passes; findings consolidated below.

---

## Release-blockers (P0) — must fix before App Store submission

| # | File:Line | Issue | Fix-level | Notes |
|---|---|---|---|---|
| 1 | TodayView.swift:266, 273, 545, 622-626 | **Ghost values computed but never rendered.** `lastPerformanceLabel` ("Last 60kg", "Last BW") and `lastPerformedLabel` ("Yesterday", "3 days ago") are built per exercise/template and dropped. The north-star feature is broken on the home screen. | screen | Two-line fix: pass `lastPerformanceLabel` to `PreviewListRow.subtitle` (or alongside `displayTarget`). Likely the single highest-leverage edit in the audit. |
| 2 | TodayView.swift:228 | Raw `Color.clear` in feature code — banned token | screen | Replace with `EmptyView()` or `Spacer().frame(width: 0)` |
| 3 | ExercisesListView.swift:51 | `.listRowBackground(Color.clear)` — banned token | screen | Use a sanctioned token or document exception |
| 4 | OnboardingExercisesView.swift:352 vs DesignSystem.swift:~3576 | **Two `ExerciseSearchSheet` structs exist** with the same name in the same module. Textbook §4 parallel-implementation violation; also a Swift compile fragility. | organism | Consolidate; the DS-level sheet is canonical. The onboarding flow should call into it (parameterize if needed). |
| 5 | HistoryView.swift:561-587 | `SessionSummarySheet` body = `NavigationStack { ScrollView { ... } }`. Sheet hygiene violation per §4 ("sheet roots must be plain VStack via AppSheetScreen/AppScreen"). | screen | Wrap in `AppSheetScreen(title:dismissLabel:dismissActionPlacement:onDismissAction:)`. Drops the hand-rolled chrome inside one canonical molecule. |
| 6 | PaywallView.swift:183-238 | **`tierCard` hand-rolled** — 50-line inline `.background(...).clipShape(RoundedRectangle(...))` card composition bypassing `AppCard`. Largest parallel-implementation drift in the audit set. | molecule | Promote to `AppSelectableTierCard(tier:isSelected:badge:label:price:sublabel:action:)` in `DesignSystem.swift`. |
| 7 | PaywallView.swift:201-212 | Selected tier signaled only by 14pt checkmark + `accentSoft` background tint. Borderline WCAG AA failure for users with reduced color discrimination. | screen | Add a stronger border / fill change on selected state. Accessibility `.isSelected` trait is already correctly exposed (line 237). |
| 8 | TrainingWeekProgress.swift:296-297 | Numbered "next week" circle reads as "Week N" — visually the banned cycle-style affordance per §3, even though the data is ISO week-of-year. | screen | Push back per §2: either drop the next-week segment, use a right-arrow glyph, or get explicit override. **Note:** this file may not be currently wired into Today — verify before fixing. |

---

## P1 — visible drift, fix before submission

### ActiveWorkoutView
- **Hardcoded `"Weight (kg)"` label** (1416) — lb users see kg-only label while the rest of the app displays lb. Hoist to `AppCopy.Workout.weightLabel(isBodyweight:unitSystem:)` AND make seed/parse unit-aware.
- **Hardcoded `"Reps"` literal** (1423) — tokenize to `AppCopy.Workout.repsLabel`.
- **Exercise-lineup sheet builds N stacked shadowed cards** (698-740) — violates "one card per list, rows separated by AppDivider". Collapse to single `AppCardList`.
- **`AdjustResultSheet` body bespoke** (1349) — `NavigationStack { ScrollView { VStack { ... } } }`. Migrate to `AppSheetScreen`. Fixes both `.log` and `.edit` modes in one change.
- **`exerciseListSheet` body bespoke** (698) — same chassis issue. Migrate to `AppSheetScreen`.
- **Dead code:** `nextSetHelperText` (902-906) — defined but never called. Delete.

### Onboarding (cross-cutting)
- **Voice drift across screens.** Schedule commits to first-person ("When do I lift?", "I'll pick", "I can change this later"). Splash, UnitPicker, ImportMethod, ProgramImport, SplitBuilder, Exercises use second-person ("your") or bare imperatives. Decision needed: migrate Schedule to second-person, or migrate the other four to first-person, but stop mixing.
- **Splash CTA inset drift.** Splash hand-rolls `.padding(.horizontal, AppSpacing.xl)` (32pt); other 4 screens go through `AppScreen.primaryButton` (16pt). The CTA visibly jumps inward when advancing from Splash → UnitPicker.
- **`OnboardingOptionCard`** (OnboardingImportMethodView.swift:50) is used in 2 onboarding screens but lives in a feature file. Promote to `DesignSystem.swift` per §4 parallel-implementation ban.
- **`AppSegmentedControl.selectionStyle` doc/code drift** — DS line 4290 says `.dark` for onboarding weekday assignment, but Schedule uses `.light`. Fix one side.
- **Negative padding hack** (OnboardingExercisesView.swift:161) — `.padding(.top, -AppSpacing.md)` to compensate for `appCardRowChrome` mishandling stacked 44pt-frame controls. Fix at the molecule layer.
- **Subtitle/title rhythm inconsistent** across 4 program-setup screens — some have subtitles, some don't. Pick a rule.

### Today
- **`routineRow` (TodayView:687-712) uses `AppFont.productAction`** — row-on-card recipe specifies `AppFont.body`. Drifts from canonical row chrome. Migrate to `AppListRow(title:subtitle:) { trailing }`.
- **Most Today copy is literal**, not in `AppCopy.Today.*` — pre-launch copy review will hunt through 6 files. Tokenize.
- **Toolbar icon ambiguity** — leading `list.bullet` (sheet picker) + trailing "History" text (nav). Symmetric icon-only would read cleaner under fatigue.
- **WorkoutTargetFormatter naming** — `trustedTargetText` / `actualText` grep-positive for banned "target-vs-actual". Rename to `plannedText` / `historyText` / `lastSessionText`.
- **WorkoutTargetFormatter zero-guard** — `weightCompact(0.0)` returns `"0kg"`. Guard inside the formatter (return nil for `kg <= 0`); push the BW/hide decision up to callers.
- **EarlierWeekCatchup.orderedTemplates** (65-70) is **identical logic** to `TodayDashboardViewModel.orderedTemplates` (TodayView:552-560). Pick one site.

### Templates / Programs
- **Sheet chrome double-application** — call sites apply `.appBottomSheetChrome() + .presentationDetents` AND `AppSheetScreen` body also applies them. Pick one source of truth.
- **Reorder UX drift** — `TemplateDetailView` uses drag (`appReorderable`); `EditProgramView` uses up/down chevron buttons. Pick one canonical.
- **Filter strip drift** — `ProgramLibraryView` uses `AppDropdownChip`; `ExercisesListView` uses `AppFilterChip`. Same concern, two molecules.
- **List primitive drift** — `ExercisesListView` uses raw `List + appPlainListRowChrome` (per docstring restricted to picker sheets). Every other tab screen uses `AppCardList`. Either widen the docstring or migrate.
- **"Use this program" CTA placement** — sticky in `ProgramLibraryDetailView`, in-flow in `ProgramDetailView`. Same action, two placements.
- **Exercise row composition drift** — three different hand-composed exercise rows across TemplateDetailView, ExercisesListView, AppExercisePickerSheet. Add canonical `AppExerciseListRow` molecule.
- **TemplateDetailView drag-preview** (170-191) — inline `RoundedRectangle.fill(cardBackground)` is parallel chrome. Replace with `appCardStyle()` or wrap in `AppCard`.
- **ProgramDetailView.routineSubtitle** accepts unused `dayIndex` parameter (102, 113). Dead parameter; remove before it becomes a foothold for re-introducing Day-N numbering.
- **ExercisesListView `-` placeholder** (402) — `–` / `—` / hyphen placeholders banned per §4. Use explicit empty-state copy.

### History
- **`SessionExerciseSummary`** (HistoryView.swift:617) is consumed by both HistoryView and SessionDetailView. That's a molecule, not a screen-private type. Move to `DesignSystem.swift`.
- **`SessionDetailView` header composition** (48-58) reproduces eyebrow/title pattern in different order than `AppSessionHighlightRow`. Use the canonical row.
- **`SessionDetailView.navigationTitle("")`** (70) — bare back chevron with no anchor. Use `.navigationBarTitleTruncated(templateName)`.
- **`SessionSummarySheet.headerTitle`** (557) returns `""` for single-session sheets — jarring empty nav title. Show date instead.
- **`SettingsSection` misnamed** — used in ExerciseProgressView for chart card. Rename to `AppTitledSection`.

### Settings
- **`"Contact support"` copy** (line 38) — should be `"Contact me"` per `PRODUCT.md` §Brand Personality (first-person singular + solo-founder positioning). Mailto subject is "Unit support" — could be "Help".
- **Export Button has empty `action: { }`** (184) — VoiceOver announces tappable button that does nothing. Add `.disabled(true)` or `accessibilityHint("Coming soon")`.
- **"Account" row shows `"None"`** (178) — cold. Suggest `"Local-first"` to reinforce brand position.

### Paywall
- **`benefitRow`** (143-157) and **`subscriptionDisclosure`** (283-289) hand-rolled — promote to molecules.
- **USD-hardcoded fallback prices** (255-258) — confusing in non-USD locales when StoreKit fails to load. Drop the fallback and rely on `loadFailureBanner`.
- **Paywall fairness:** core logging is NOT gated (confirmed). Two cosmetic Pro features (accent colors, founding badge) + Settings "Export data" (no-op until paywall flips on). **Verify with user**: is CSV export "core logging" or "convenience"? If core, this is a §3 violation.

### TrainingWeekProgress (not currently wired)
- **`AppColor.textPrimary` as background fill** (282) — token misuse. Should be `AppColor.accent` (canonical black for filled pills).
- **Hand-rolled current-week pill** (277-284) replaces what `AppTag(style: .accent)` already does. Three problems, one swap.
- **`AppDividedList` row hand-composed** (362-380) instead of `AppListRow(title:subtitle:) { trailing }`.

---

## Atom/molecule fixes (highest leverage — fix once, every screen benefits)

| # | Layer | Where | Change |
|---|---|---|---|
| 1 | molecule | DS | Promote `OnboardingOptionCard` → `AppOptionTileCard` (icon + title + trailing badge; ScaleButtonStyle; 44pt floor) |
| 2 | molecule | DS | Promote paywall tier card → `AppSelectableTierCard` |
| 3 | molecule | DS | Add `AppExerciseListRow` (leading reorder/icon + title + subtitle + trailing action) — collapses 3+ hand-rolled rows |
| 4 | molecule | DS | Add `AppLabeledStepper(label:value:range:onDecrement:onIncrement:)` — 3 callers exist today |
| 5 | molecule | DS | Add `AppIconCircleButton(icon:isEnabled:action:)` — covers HistoryView's `monthNavChevron` + future overflow menus |
| 6 | molecule | DS | Add `AppDisclosureCopy` for legal/disclosure body text (Paywall + future Onboarding terms) |
| 7 | molecule | DS | Add `AppRuleSection(title:body:)` for educational/help sheets (Onboarding format guide) |
| 8 | molecule | DS | Move `SessionExerciseSummary` from HistoryView.swift to DesignSystem.swift |
| 9 | molecule | DS | Rename `SettingsSection` → `AppTitledSection` (used outside Settings) |
| 10 | molecule | DS | Fix `appCardRowChrome` to handle stacked 44pt-frame controls without callers needing negative padding (OnboardingExercisesView:161 workaround) |
| 11 | molecule | DS | Extend `AppCardList` with optional `header: String?` slot — eliminates the `SettingsSection { AppDividedList { … } }` two-layer pattern |
| 12 | molecule | DS | Extend `AppSessionHighlightCard` with optional `onTap:` — collapses `HistoryMissedDayCard` and `EarlierWeekRoutineRow` private wrappers |
| 13 | atom | DS | Resolve `AppSegmentedControl.selectionStyle` doc/code drift — Schedule uses `.light`, docstring says `.dark` for onboarding |
| 14 | atom | DS | Stop using `AppColor.textPrimary` as a background fill (TrainingWeekProgress:282). Either rename token (foreground-semantic) or fix callers (`.accent`). |
| 15 | molecule | DS | Decide canonical reorder UX — drag (TemplateDetailView) vs up/down (EditProgramView) — and migrate one |
| 16 | molecule | DS | Decide canonical filter strip — `AppFilterChip` (toggle) vs `AppDropdownChip` (menu) — or document when each applies |

---

## Copy / voice findings

- **No `we / us / our` in any user-facing string** across all 27 files. The first-person singular rule is being respected.
- **Voice drift inside Onboarding** — see P1 above.
- **Settings `"Contact support"`** — should be `"Contact me"`.
- **WorkoutTargetFormatter naming** — `trustedTargetText` / `actualText` grep-positive for banned terms.
- **Most Today copy is literal** — tokenize to `AppCopy.Today.*`.

---

## Reference gaps (suggested additions to `docs/references/ios-screens/`)

- Welcome / splash hero (Linear / Things-style)
- Paste-import editor with parse-and-validate
- Program-day count picker
- Program-builder day with stepper rows
- Full-month calendar with workout markers (Apple Fitness / Hevy)
- Exercise progress: PR + chart + session-list stacked composition
- Light-mode quiet settings (Things 3, Bear, Reeder)

---

## What's NOT wrong (worth saying out loud)

- **Mechanical banned-token scan is clean** — no `chevron.right`, no hex literals, no `Color.gray`, no `.font(.system)`, no `.preferredColorScheme(.dark)`, no `LinearGradient` fade behind bars, no raw `Divider()`, no `Form { Section }`, no `Picker(.segmented)`, no `ToolbarItem` `.weight(...)`, no `UNIT_*` env scaffolding. The PreToolUse hook is doing its job.
- **Paywall does NOT gate core logging** — confirmed via inline comments and benefit list. Pro features are cosmetic/identity (accent colors, founding badge). Export is the only utility gate and is a no-op pre-launch.
- **No banned-scope creep** — no `Day N ·` rigid prefixes, no `Week N of M`, no `ProgressionEngine`, no plate calculator, no social/discovery surfaces.
- **Sheet hygiene mostly clean** — only HistoryView's `SessionSummarySheet` and ActiveWorkout's two custom sheet bodies violate.
- **Gym Test passes on ActiveWorkout** — 1-tap ghost-value path, 44pt touch targets, monospaced numeric displays, PR celebration without blocking next-set flow, re-entrancy guard on Complete-set.

---

## Suggested fix order

1. **P0 quick wins** (banned tokens + dead code) — TodayView `Color.clear`, ExercisesListView `Color.clear`, ActiveWorkout `nextSetHelperText` delete, ProgramDetailView dead `dayIndex` param
2. **Ghost-value rendering on Today** (single highest-leverage screen edit)
3. **Sheet hygiene** — HistoryView SessionSummarySheet + ActiveWorkout AdjustResultSheet + exerciseListSheet → all to `AppSheetScreen`
4. **Parallel-implementation consolidation** — duplicate `ExerciseSearchSheet`, paywall `tierCard` → `AppSelectableTierCard`, `SessionExerciseSummary` to DS, `OnboardingOptionCard` to DS
5. **Onboarding voice decision** + CTA inset fix
6. **Copy tokenization** — Today, ActiveWorkout `"Weight"`/`"Reps"`, Settings `"Contact me"`
7. **Atom/molecule renames** — `SettingsSection` → `AppTitledSection`, `WorkoutTargetFormatter` target/actual renames
8. **TrainingWeekProgress decision** — drop next-week numbered circle or push back per §2
9. **Templates cross-tab consistency pass** — reorder UX, filter strip, list primitive, CTA placement
10. **Paywall fairness sign-off** — confirm CSV export classification

---

## Verification

All findings are static reads. No simulator runs, no screenshots taken (per CLAUDE.md §6 — visual pass is the user's). The `/ui-visual-verify` skill is user-invoked only.

After applying fixes, the user runs `/ui-visual-verify` per screen, with sibling-screen regression checks for any atom/molecule changes.
