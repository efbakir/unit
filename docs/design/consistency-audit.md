# Consistency audit (2.1 + PR #5)

- **What:** every place where the same thing looks or behaves differently, one rule per pattern, the smallest fix.
- **Scope:** consistency only. No features, no flow changes, no redesign.
- **Audited:** release branch `claude/app-finalization-launch-34a116` plus PR #5 (`f7445ba`). Line numbers below are at `f7445ba`.
- **Approved:** 2026-10-24 by Efe, with decisions D1-D4 at their defaults (below).
- **Shots:** iPhone 17 Pro simulator, iOS 27, region US, seeded with the UI-test fixtures. Before = `f7445ba`, after = each fix PR. Folder: [`docs/qa/consistency-audit-2026-10-24/`](../qa/consistency-audit-2026-10-24/).

## Decisions

| # | Decision | Result | Recorded decision it changes |
|---|---|---|---|
| D1 | Toolbar buttons stay black; text buttons in the page turn blue | Yes | None. Matches Apple's toolbar guidance ("prefer the default monochromatic appearance") and the JOI note "Top-bar actions are ink" |
| D2 | Drop SF Mono everywhere, including the 30pt set inputs | Yes | Oct 20-21 notes "SF Mono unchanged" |
| D3 | Paywall legal links blue at 13pt | Yes | 2026-08-13 asked for the muted token (13pt gray); code shipped 11pt gray. Color changes, size follows the decision |
| D4 | "+ Add set" becomes the same blue add row as "Add exercise" in routines | Yes | Final B spec said centered 15pt |

## Rules

- **Text buttons:** text with no fill is blue (`AppColor.accent`), always through `AppGhostButton`: full width (17 bold) or `layout: .inline` (15 medium, hugs its text, 44pt hit area). No underline. No gray or black text buttons.
- **Add X:** inside a card's list = `AppCardListAddRow` (blue, plus icon). Below or outside cards = `AppGhostButton`.
- **Action rows:** a list row that runs an action (no chevron) has a blue title. A row that opens something keeps a black title and a chevron.
- **Icon buttons:** stay black. The symbol is the cue.
- **Toolbars:** native and black. Close = X at the leading edge. Confirm = checkmark at the trailing edge. No "Done", "Cancel" or "Close" text. No custom weight on toolbar text.
- **Tint:** one owner. `AppScreen` tints page content blue; bars and toolbars stay black from `ContentView`. No per-screen re-tints.
- **Numbers:** SF Pro with tabular digits for every number. SF Mono is not used.
- **Number sizes:** set data (sets, reps, weight) is 17pt wherever it sits, the same size as the row name. Supporting numbers (dates, "Last time", comparisons, counts) are 15pt. Hero numbers are 30-56pt bold. Set data is never 13 or 11pt.
- **Minimum for numbers on the right of a row:** 17pt at the default text size (iOS Body). Apple's iOS floor is 11pt and its default is 17pt. Every size scales with Dynamic Type through the existing `UIFontMetrics` tokens. Tabular digits do not change what VoiceOver reads.
- **List rows:** name 17 semibold; set data 17 medium with tabular digits (gray for plans, black for logged results); supporting line 15 gray; 16pt side inset; at least 52pt tall. At accessibility text sizes the value moves under the name instead of shrinking. Numbers never use `minimumScaleFactor`.
- **Number formats:** one weight formatter (the phone's decimal mark, up to 2 decimals in kg and 1 in lb, a space before the unit).
  - One set: "80 kg × 8"
  - Same sets: "3 × 8 at 80 kg"
  - Mixed sets: "80 kg · 8/8/7 reps"
  - Plan without weight: "3 × 8–10"
  - Bodyweight: "BW × 12", "BW + 10 kg × 8"
  - Last time: "Last time · 80 kg × 8"
  - A next target reads like a plan, with the change after a middle dot: "Next time: 3 × 8 at 62.5 kg · +2.5 kg" (also "· +1 rep", "· same target"). One performed set stays "62.5 kg × 8".
- **Colors:** blue only for things you can tap or that are selected. Status checkmarks are black. Text is black, supporting text gray.
- **Type scale:** `AppFont` tokens only, each with its own tracking. No borrowed tracking, no `.bold()` or `.weight()` overrides. In-page titles are 24pt (`productHeading`).
- **Capitalization:** sentence case for every label, button, title and header. Names keep their capitals (Unit Pro, App Store, Terms of Service, exercise and program names). Caps only through `appCapsLabel`, never on text the lifter typed. Apple uses title case for buttons; Unit's recorded rule is sentence case and almost every string already follows it.
- **Words:** one word per thing: "routine" (not "day"), "Contact me" (not "Support"), "Level" (not "Experience"). Error alerts close with "OK" (Apple: "OK" only for purely informational alerts).
- **Spacing:** rows and cards use the `AppCardList` 16pt inset. Never stack a second inset. The same row has the same padding on every screen.
- **Empty states:** no data yet = `EmptyStateCard`; no filter results = `AppEmptyHint`. Both left-aligned on the page, titles without a final period.
- **Destructive confirms:** a simple do-or-cancel is an alert with a red button and Cancel. Choices about an action (3 options) are a confirmation dialog. Undoable actions get no confirm, only an Undo toast.
- **Sheets vs push:** looking at details = push, tab bar hidden. A short task that returns = sheet with an X.

## Why SF Pro with tabular digits

- Apple: SF numbers are proportional by default; `.monospacedDigit()` "returns a modified font that uses fixed-width digits, while leaving other characters proportionally spaced".
- Apple: SF Mono "enables alignment between rows and columns of text, and is used in coding environments like Xcode".
- Apple's Clock stopwatch uses SF with fixed-width digits, not SF Mono.
- Unit's own `numericInput` token already notes that mono cells put wide gaps around "." in values like 82.5.
- On device, SF Mono rows wrap where SF Pro fits: "30 kg/32.5 kg/30 / kg · 8/8/8 reps" (before shot `05-summary-evidence`).

## Design system map

All in `Unit/UI/DesignSystem.swift` unless noted.

| Group | Where | What exists |
|---|---|---|
| Color | `AppColor` L19-95 | surfaces, text (primary, secondary, tertiary, disabled, placeholder), border, accent blue + foreground + soft, status + soft + on-soft |
| Tint | `Unit/ContentView.swift` L85-98, L120 | tab bar blue; each tab's content black; nav bar black; Today, Programs, onboarding and every `AppSheetScreen` re-tint blue |
| Type | `AppFont` L164-265 | SF Pro roles 11-56pt; `numericInput` 30 bold with tabular digits; SF Mono `numericDisplay` 36, `setValue` 30, `setValueCompact` 28, `performance` 15, `stepIndicator` 14 |
| Spacing | `AppSpacing` L292 | 2, 4, 8, 12, 16, 24, 32, 48 |
| Radius | `AppRadius` L318 | 10, 14, 22 |
| Icons | `AppIcon` L976, `AppIconSize` L1073 | SF Symbols by role, 6 lift glyphs, sizes 12-44 |
| Buttons | L1624-2058, L4139 | `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton` + label, `AppCardListAddRow`, `AppFloatingPillButton`, `ProductTopBar` actions, `appToolbarTextStyle()`, `ScaleButtonStyle` |
| Rows | L1236-1368, L2829, L3937-4130, L6826-7025 | `AppListRow` + value label, `PreviewListRow`, `AppDividedList`, `AppCardList`, logging rows |
| Cards, screens, sheets | L3039, L4789-4961, L5393 | `AppCard`, `SettingsSection`, `AppSectionHeader`, `AppScreen`, `AppSheetScreen` |
| Status and empty | L2068, L3598, L3761, L3914, L7028 | `AppTag`, `AppToast`, `EmptyStateCard`, `AppEmptyHint`, `RestBar` |

## Worst 10, before and after

| # | What | Before | After |
|---|---|---|---|
| 1 | "Edit" blue in Analytics, gray in the workout summary | [Analytics](../qa/consistency-audit-2026-10-24/before/02-analytics.png), [summary](../qa/consistency-audit-2026-10-24/before/01-summary-next-time.png) | [Analytics](../qa/consistency-audit-2026-10-24/after-pr1/02-analytics.png), [summary](../qa/consistency-audit-2026-10-24/after-pr1/01-summary-next-time.png) |
| 2 | "Add exercise" black in a workout, blue row in a routine | [workout](../qa/consistency-audit-2026-10-24/before/03d-active-add-exercise.png), [routine](../qa/consistency-audit-2026-10-24/before/03-routine-detail.png) | [workout](../qa/consistency-audit-2026-10-24/after-pr1/03d-active-add-exercise.png), [routine](../qa/consistency-audit-2026-10-24/after-pr1/03-routine-detail.png) |
| 3 | Black underlined "Undo" and black "+ Add set" | [workout](../qa/consistency-audit-2026-10-24/before/03c-active-undo-add-set.png) | [workout](../qa/consistency-audit-2026-10-24/after-pr1/03c-active-undo-add-set.png) |
| 4 | Paywall links 11pt gray; Settings "Restore Purchases" looks like static text | [paywall](../qa/consistency-audit-2026-10-24/before/04-paywall-footer.png), [Settings](../qa/consistency-audit-2026-10-24/before/04b-settings.png) | [paywall](../qa/consistency-audit-2026-10-24/after-pr1/04-paywall-footer.png), [Settings](../qa/consistency-audit-2026-10-24/after-pr1/04b-settings.png); with PR 5 words: [paywall](../qa/consistency-audit-2026-10-24/after-pr6/04-paywall-footer.png) |
| 5 | Same numbers in SF Mono (summary) and SF Pro (Analytics) | [summary](../qa/consistency-audit-2026-10-24/before/05-summary-evidence.png), [log](../qa/consistency-audit-2026-10-24/before/05b-summary-exercise-log.png), [large text](../qa/consistency-audit-2026-10-24/before/11-ax3-summary-evidence.png) | [summary](../qa/consistency-audit-2026-10-24/after-pr2/05-summary-evidence.png), [log](../qa/consistency-audit-2026-10-24/after-pr2/05b-summary-exercise-log.png), [large text](../qa/consistency-audit-2026-10-24/after-pr2/11-ax3-summary-evidence.png) |
| 6 | SF Mono rows next to 13pt summaries on one screen | [workout](../qa/consistency-audit-2026-10-24/before/03c-active-undo-add-set.png) | [workout](../qa/consistency-audit-2026-10-24/after-pr2/03c-active-undo-add-set.png) |
| 7 | "3 × 60 kg × 10" vs "3 × 10 at 60 kg" vs "3 × 10"; "62.5" next to "62,5" in region Italy | [workout](../qa/consistency-audit-2026-10-24/before/06-active-collapsed-summary.png), [Today](../qa/consistency-audit-2026-10-24/before/07-today-up-next.png), [Italy](../qa/consistency-audit-2026-10-24/before/12-italy-active.png) | [workout](../qa/consistency-audit-2026-10-24/after-pr3/06-active-collapsed-summary.png), [Today](../qa/consistency-audit-2026-10-24/after-pr3/07-today-up-next.png), [Italy](../qa/consistency-audit-2026-10-24/after-pr3/12-italy-active.png) |
| 8 | Sheet close: X vs "Done" vs "Cancel" and "Done" | [picker](../qa/consistency-audit-2026-10-24/before/08a-exercise-picker-sheet.png), [target](../qa/consistency-audit-2026-10-24/before/08b-target-editor-sheet.png), [main lifts](../qa/consistency-audit-2026-10-24/before/08c-main-lifts-sheet.png) | [picker](../qa/consistency-audit-2026-10-24/after-pr4/08a-exercise-picker-sheet.png), [target](../qa/consistency-audit-2026-10-24/after-pr4/08b-target-editor-sheet.png), [main lifts](../qa/consistency-audit-2026-10-24/after-pr4/08c-main-lifts-sheet.png) |
| 9 | Analytics switch: caption in setup, none in Settings | [setup](../qa/consistency-audit-2026-10-24/before/09-setup-analytics-toggle.png), [Settings](../qa/consistency-audit-2026-10-24/before/04b-settings.png) | [setup](../qa/consistency-audit-2026-10-24/after-pr6/09-setup-analytics-toggle.png), [Settings](../qa/consistency-audit-2026-10-24/after-pr6/04b-settings.png) |
| 10 | Empty filter result: centered box, other empty states left on the page | [History](../qa/consistency-audit-2026-10-24/before/10-history-filter-empty.png) | [History](../qa/consistency-audit-2026-10-24/after-pr6/10-history-filter-empty.png) |

## Issues and fixes

Key: DS = `Unit/UI/DesignSystem.swift`; other paths under `Unit/Features/`. Effort: S under 1 hour, M 1-3 hours.

### PR 1 - Text buttons look tappable

| # | Issue | Where | Now | Fix | Effort | Status |
|---|---|---|---|---|---|---|
| 1 | Ghost buttons are black | DS:1932 (`AppGhostButtonLabel`); 14 callers | black 17 bold | label in `accent`; disabled stays `textDisabled` | S | Fixed (PR 1) |
| 2 | "Edit" in 2 styles | `Analytics/AnalyticsView.swift:33`; `History/SessionDetailView.swift:328` | blue 15 with -0.3 tracking, 48pt / gray 17 | `AppGhostButton(layout: .inline)` | S | Fixed (PR 1) |
| 3 | "Undo" black and underlined | DS:6918, DS:7013 | black 15, underline | `.inline` button in the same 44pt slot | S | Fixed (PR 1) |
| 4 | "No thanks" gray | `History/SessionDetailView.swift:729` | gray 15 | `.inline` | S | Fixed (PR 1) |
| 5 | "+ Add set" vs "Add exercise" | DS:6815 vs `Templates/TemplateDetailView.swift:60` | black centered 15 / blue row with icon | `AppCardListAddRow("Add set")` | S | Fixed (PR 1) |
| 6 | "Freestyle session" 44pt, other ghost buttons 60pt | `Templates/TemplatesView.swift:134` | raw button + label | `AppGhostButton` | S | Fixed (PR 1) |
| 7 | "Restore purchases" row looks like static text | `Settings/SettingsView.swift:247` | black title, no chevron | `AppListRow` action tone | S | Fixed (PR 1) |
| 8 | Paywall legal links tiny and gray | `Subscription/PaywallView.swift:819-820` | 11pt gray | 13pt blue | S | Fixed (PR 1) |
| 9 | Settings footer email black | `Settings/SettingsView.swift:327` | black 15 link | `.inline` style | S | Fixed (PR 1) |

### PR 2 - One number style, readable row numbers

| # | Issue | Where | Now | Fix | Effort | Status |
|---|---|---|---|---|---|---|
| 10 | Same data in SF Mono and SF Pro | `History/HistoryView.swift:815, 841`, `History/SessionDetailView.swift:344`, DS:6905, 6946, 7079, `Today/ActiveWorkoutView.swift:275` vs `Analytics/AnalyticsView.swift:64` and others | 5 SF Mono tokens | the mono factory (DS:140-143) returns SF Pro with tabular digits | S | Fixed (PR 2) |
| 11 | Row numbers too small | `performance` DS:238, `stepIndicator` DS:236 | 15pt / 14pt | 17pt / 15pt, medium | S | Fixed (PR 2) |
| 12 | Same exercise, two weights | collapsed card DS:6981 vs expanded header DS:6799 | 17 medium vs 17 semibold | name semibold; summary 13 to 17; suggestion 13 to 15 | S | Fixed (PR 2) |
| 13 | Set data under names at 15 or 13 | `Templates/TemplateDetailView.swift:204-216`; `Onboarding/OnboardingProgramPreviewView.swift:200-209`; Today "Last time" DS:2874 | 15 / 15 / 13 | 17 / 17 / 15 | S | Fixed (PR 2) |
| 14 | Analytics row value shrinks | `Analytics/AnalyticsView.swift:62-67` | 15pt, -0.3 tracking, shrinks to 70% | `AppListRow(title:value:)` | S | Fixed (PR 2) |
| 15 | Bold override | `History/SessionDetailView.swift:345` | `.bold(emphasized)` | color only | S | Fixed (PR 2) |
| 16 | Next-target inputs tiny | `History/SessionDetailView.swift:400, 420` | 15pt mono fields | `numericInput` (30 bold) | S | Fixed (PR 2) |
| 17 | Rows don't adapt to large text | DS:1260-1299 `AppListRow` | value squeezed beside the name | value moves under the name at accessibility sizes | M | Fixed (PR 2) |
| 18 | Double side inset | `Templates/ProgramLibraryDetailView.swift:38-43`, also the onboarding weight-unit row | 32pt | `AppListRow` `.display` rows no longer add a second 16pt inset | S | Fixed (PR 2) |
| 19 | Same row, two paddings | `History/SessionDetailView.swift:150` vs `History/HistoryView.swift:736` | 24pt vs 16pt | drop the extra 8pt | S | Fixed (PR 2) |

### PR 3 - One number format

| # | Issue | Where | Now | Fix | Effort | Status |
|---|---|---|---|---|---|---|
| 20 | 4 weight formatters, 2 decimal marks | DS:1083, `Today/WorkoutTargetFormatter.swift:14-29`, `Analytics/AnalyticsFormatting.swift:4-10` | Italy: "82.5" while logging, "82,5" in Analytics and the input field | one formatter, the phone's decimal mark; editable weights keep 2 decimals so a 61.25 kg target is not shown as 61.3 | M | Fixed (PR 3) |
| 21 | One exercise, 3 summaries | `Today/ActiveWorkoutView.swift:656-667`, History, `Today/TodayView.swift:798-812` | "3 × 80 kg × 8" / "3 × 8 at 80 kg" / "3 × 8" | "3 × 8 at 80 kg"; mixed sets "80 kg · 8/8/7 reps" | S | Fixed (PR 3) |
| 22 | "Last time" two ways | `UI/AppCopy.swift:14` vs Today | "Last time 80 × 8" (no unit) | "Last time · 80 kg × 8" | S | Fixed (PR 3) |
| 23 | Bodyweight plus load drops "BW" | `Today/WorkoutTargetFormatter.swift:310-318`, `Analytics/AnalyticsFormatting.swift:11-16, 68-72` | "10 kg × 8", "10 × 8" | "BW + 10 kg × 8" (the Analytics hero number still shows the load alone) | M | Fixed (PR 3) |
| 24 | Zero load shows as BW in History | `Today/WorkoutTargetFormatter.swift:315` | logging "0 kg × 8", History "BW × 8" | never infer BW from zero (Final B) | S | Fixed (PR 3) |

### PR 4 - Toolbars, sheet close buttons, one tint owner

| # | Issue | Where | Now | Fix | Effort | Status |
|---|---|---|---|---|---|---|
| 25 | Toolbar text in 2 weights | `appToolbarTextStyle` DS:5868 on "History", "Browse", picker "Done" vs system "Finish" | semibold vs regular | remove the modifier | S | Fixed (PR 4) |
| 26 | 4 ways to close a sheet | X (`AppSheetScreen`) vs "Done" (DS:5359, `Analytics/AnalyticsView.swift:166`) vs "Cancel" and "Done" (`Analytics/MainLiftsEditor.swift:98-106`) | mixed | X to close; Main lifts saves with a checkmark | S | Fixed (PR 4) |
| 27 | Keyboard "Done" in 2 fonts | DS:5675 vs DS:1428 | 17 semibold blue vs system | both native | S | Fixed (PR 4) |
| 28 | Tint fights itself | `ContentView.swift:85-95`; re-tints in 8 files; `Today/ActiveWorkoutView.swift:299` | Analytics black, Today and Programs blue | `AppScreen` tints page content once; bars and toolbars stay black from `ContentView` (removing the tab tint would have turned back buttons blue, against D1) | M | Fixed (PR 4) |

### PR 5 - Words

| # | Issue | Where | Fix | Effort | Status |
|---|---|---|---|---|---|
| 29 | Title Case outliers | "Restore Purchases", "Manage Subscription", "Untitled Program", "Full Body" | sentence case | S | Fixed (PR 5) |
| 30 | "day" vs "routine" | `Templates/ProgramDetailView.swift:97-100`, `Templates/AddTemplateView.swift:26-39` | "routine" | S | Fixed (PR 5) |
| 31 | Empty titles with periods | `Templates/TemplateDetailView.swift:49`, `Templates/ProgramDetailView.swift:98` | no period | S | Fixed (PR 5) |
| 32 | Support named twice | Paywall "Support" vs Settings "Contact me" | "Contact me", same prefilled email | S | Fixed (PR 5) |
| 33 | "Experience" vs "Level" | `UI/AppCopy.swift:363` vs `Templates/ProgramLibraryView.swift:73` | "Level" | S | Fixed (PR 5) |
| 34 | Error alert buttons | "Close" in 7 alerts vs "OK" in 4; "Save failed" says "Try again" but only closes; "Couldn't save workout" has no message | "OK"; "Couldn't save program"; same message as the toast | S | Fixed (PR 5) |
| 35 | Same error, two messages | `Templates/TemplateDetailView.swift:97` vs `Templates/AddTemplateView.swift:48` | one message | S | Fixed (PR 5) |
| 36 | Caps on text the lifter typed | `History/HistoryView.swift:718`; `Today/TodayView.swift:697, 713` | plain text; `EmptyStateCard` eyebrows are now sentence-case muted labels, like Today's "Up next" | S | Fixed (PR 5) |
| 37 | Straight vs curly apostrophes; "Rest finished." vs "Rest finished" | `Subscription/PaywallView.swift:563, 764`, `Today/ActiveWorkoutView.swift:304`; `UnitWidget/RestTimerLiveActivity.swift:33` | curly; one string | S | Fixed (PR 5) |

### PR 6 - Small leftovers

| # | Issue | Where | Fix | Effort | Status |
|---|---|---|---|---|---|
| 38 | Borrowed -0.3 tracking on body text | ~30 sites in Analytics, Main lifts, Exercise detail, DS:6680-6727; `Today/ActiveWorkoutView.swift:537, 564` | each font's own tracking | S | Fixed (PR 6) |
| 39 | Dash placeholder and a weight override | DS:6690, DS:6714 | remove | S | Fixed (PR 6) |
| 40 | Detail titles 20 vs 24 | `History/SessionDetailView.swift:119` vs Exercise detail | 24 (`productHeading`) | S | Fixed (PR 6) |
| 41 | Empty states: centered box vs left on the page | `AppEmptyHint` DS:3914; `Onboarding/OnboardingProgramPreviewView.swift:458-473` | left-aligned, no box; `EmptyStateCard` | S | Fixed (PR 6) |
| 42 | Done mark 20 vs 22 on one screen; reorder icon 16 vs 15 | DS:6928 vs DS:7018; `Templates/TemplateDetailView.swift:131` vs DS:4177 | 20; 16 | S | Fixed (PR 6) |
| 43 | Blue on checks you can't tap | DS:3532, `Subscription/PaywallView.swift:413`, DS:3686 | black | S | Fixed (PR 6) |
| 44 | Tab bar pops back in | `Templates/ProgramLibraryView.swift`, `History/ExerciseProgressView.swift` | hide like other pushed screens | S | Fixed (PR 6) |
| 45 | Delete confirm is a dialog, others are alerts | `Templates/TemplatesView.swift:383` vs `Today/ActiveWorkoutView.swift:307, 311` | alert | S | Fixed (PR 6) |
| 46 | Same setting, two looks | `AnonymousAnalyticsToggle` (setup, paywall) vs `Settings/SettingsView.swift:224-230` | one owner built from `AppListRow` and a native toggle | S | Fixed (PR 6) |

### Added on 2026-10-24 from the Grok benchmarks (`docs/research/2026-10-24-benchmarks/`)

| # | Issue | Where | Now | Fix | Effort | Status |
|---|---|---|---|---|---|---|
| 47 | The same next target is written two ways (benchmark report 4, row 8) | Exercise-done card (`Today/ActiveWorkoutView.swift` `exerciseDoneSuggestion`) vs Today and the summary; Analytics "Next" | "Suggested next: 62.5 kg × 8 · +2.5 kg" / "3 × 8 at 62.5 kg" / "Next 62.5 kg × 8" | targets read like a plan (rule above) | S | Done card built to the rule by the progression-loop chat (commit 4f9a8f2 on `claude/progression-loop-7006dd`, prefix "Next time:" because Finish now saves the target). Analytics "Next" needs the planned set count (follow-up) |

## Needs your call

- **"Last time" on a saved target** (persona panel round 2; `docs/flows/training-loop.md` "Source text"): the current set's source line says "Last time · 60 kg × 8" even when the row is prefilled from the saved next target, so the higher number has no label. You kept "Last time" as the label earlier. Default: keep it. Counter: say "Target" when the row shows the saved target.

## Noted, not fixed here

- Detail pages use a native nav title (Routine, Program, Library) or an in-page title (Session, Exercise detail). Structure change.
- "Add routine": the row opens a sheet; the empty-state button opens Edit program. Flow change.
- The History calendar opens a sheet; the list pushes a screen. Flow change.
- Paywall headline (20pt centered) vs onboarding headings (24pt left). Designed purchase surface.
- History shows "Set 3" after set 2 was removed (it numbers from the stored index). Data bug, follow-up.
- Calendar weekday headers are hardcoded "MON-SUN", Monday first. Locale follow-up.
- **Paywall loses its side margins on iOS 27 (found while capturing).** `AppSelectableTierCard` (DS ~L3352-3385) fixes the width of the plan title, badge and price, and PR #5 lengthened the badge to "SAVE 80% VS WEEKLY". The Yearly row is wider than the screen, so the whole paywall runs to the screen edges ([before](../qa/consistency-audit-2026-10-24/before/04a-paywall-top.png)). Layout bug in PR #5, not consistency: fix on PR #5 before the next upload.
- Unused code: `ProductTopBar`, `WorkoutCommandCard`, `SessionStateBar`, `SetProgressIndicator`, `RestTimerControl`, `AppFloatingPillButton`, the week strip, `ExercisesListView`. Cleanup PR.

## Sources

- Apple HIG: [Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [Color](https://developer.apple.com/design/human-interface-guidelines/color), [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts), [Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets)
- [SwiftUI `monospacedDigit()`](https://developer.apple.com/documentation/swiftui/font/monospaceddigit()), [Apple Fonts](https://developer.apple.com/fonts/), [Use Your Loaf: Monospace digits](https://useyourloaf.com/blog/monospace-digits/)
